package dev.datastore.orders;

import dev.datastore.orders.Model.Customer;
import dev.datastore.orders.Model.NewOrder;
import dev.datastore.orders.Model.Order;
import dev.datastore.orders.Model.OrderSearch;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import javax.sql.DataSource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;

/**
 * The SQL both engines accept. Subclasses supply what differs: the
 * idempotent insert and how a request id is bound.
 */
abstract class SqlOrderRepository implements OrderRepository {

    static final String ORDER_COLUMNS =
            "id, request_id, run_id, customer_id, status, total_cents, created_at, updated_at";

    private static final int SEED_BATCH = 1000;
    private static final List<String> SEED_STATUSES = List.of("NEW", "PAID", "SHIPPED", "DELIVERED", "DELIVERED", "CANCELLED");

    protected final JdbcClient writer;
    protected final JdbcClient reader;
    protected final JdbcTemplate writerTemplate;
    protected final Retrier retrier;

    SqlOrderRepository(DataSource writer, DataSource reader, Retrier retrier) {
        this.writer = JdbcClient.create(writer);
        this.reader = JdbcClient.create(reader);
        this.writerTemplate = new JdbcTemplate(writer);
        this.retrier = retrier;
    }

    /** Inserts the order unless its request id exists; returns the order's id either way. */
    protected abstract long insertOrIgnoreOrder(NewOrder order);

    /** The request id as the engine's driver should bind it. */
    protected abstract Object requestIdParam(UUID requestId);

    @Override
    public Customer createCustomer(String name, String email) {
        return retrier.call("create_customer", () -> {
            var keys = new GeneratedKeyHolder();
            writer.sql("INSERT INTO customers (name, email) VALUES (?, ?)")
                    .params(name, email)
                    .update(keys, "id");
            return customerOn(writer, keys.getKey().longValue()).orElseThrow();
        });
    }

    @Override
    public Optional<Customer> customer(long id) {
        return retrier.call("read_customer", () -> customerOn(writer, id));
    }

    private static Optional<Customer> customerOn(JdbcClient db, long id) {
        return db.sql("SELECT id, name, email, created_at FROM customers WHERE id = ?")
                .param(id)
                .query((rs, n) -> new Customer(rs.getLong("id"), rs.getString("name"),
                        rs.getString("email"), instant(rs, "created_at")))
                .optional();
    }

    @Override
    public List<Long> customerIds(int limit) {
        return retrier.call("customer_ids", () -> reader.sql("SELECT id FROM customers ORDER BY id LIMIT ?")
                .param(limit)
                .query(Long.class)
                .list());
    }

    @Override
    public Order createOrder(NewOrder order) {
        return retrier.call("create", () -> orderOn(writer, insertOrIgnoreOrder(order)).orElseThrow());
    }

    @Override
    public Optional<Order> order(long id) {
        return retrier.call("read", () -> orderOn(writer, id));
    }

    private static Optional<Order> orderOn(JdbcClient db, long id) {
        return db.sql("SELECT " + ORDER_COLUMNS + " FROM orders WHERE id = ?")
                .param(id)
                .query(SqlOrderRepository::order)
                .optional();
    }

    @Override
    public Optional<Order> updateStatus(long id, String status) {
        return retrier.call("update", () -> {
            int rows = writer.sql("UPDATE orders SET status = ?, updated_at = CURRENT_TIMESTAMP(6) WHERE id = ?")
                    .params(status, id)
                    .update();
            return rows == 0 ? Optional.<Order>empty() : orderOn(writer, id);
        });
    }

    @Override
    public void deleteOrder(long id) {
        retrier.run("delete", () -> writer.sql("DELETE FROM orders WHERE id = ?").param(id).update());
    }

    @Override
    public List<Order> search(OrderSearch s) {
        var where = new ArrayList<String>();
        Map<String, Object> params = new HashMap<>();
        if (s.customerId() != null) {
            where.add("customer_id = :customerId");
            params.put("customerId", s.customerId());
        }
        if (s.status() != null) {
            where.add("status = :status");
            params.put("status", s.status());
        }
        if (s.createdAfter() != null) {
            where.add("created_at >= :createdAfter");
            params.put("createdAfter", utc(s.createdAfter()));
        }
        if (s.createdBefore() != null) {
            where.add("created_at < :createdBefore");
            params.put("createdBefore", utc(s.createdBefore()));
        }
        if (s.minTotalCents() != null) {
            where.add("total_cents >= :minTotalCents");
            params.put("minTotalCents", s.minTotalCents());
        }
        params.put("limit", s.limit());
        String sql = "SELECT " + ORDER_COLUMNS + " FROM orders WHERE " + String.join(" AND ", where)
                + " ORDER BY created_at DESC, id DESC LIMIT :limit";
        return retrier.call("search", () -> reader.sql(sql).params(params).query(SqlOrderRepository::order).list());
    }

    @Override
    public long countByRun(String runId) {
        return retrier.call("count_run", () -> writer.sql("SELECT count(*) FROM orders WHERE run_id = ?")
                .param(runId)
                .query(Long.class)
                .single());
    }

    @Override
    public int seedCustomers(int count) {
        int done = 0;
        while (done < count) {
            int start = done;
            int batch = Math.min(SEED_BATCH, count - done);
            retrier.run("seed", () -> writerTemplate.batchUpdate(
                    "INSERT INTO customers (name, email) VALUES (?, ?)",
                    java.util.stream.IntStream.range(start, start + batch)
                            .mapToObj(i -> new Object[] {"Customer " + i, "customer" + i + "@example.com"})
                            .toList()));
            done += batch;
        }
        return done;
    }

    @Override
    public int seedOrders(int count) {
        List<Long> customers = customerIdsOnWriter(10_000);
        if (customers.isEmpty()) {
            throw new IllegalStateException("seed customers before orders");
        }
        var random = ThreadLocalRandom.current();
        var now = Instant.now();
        int done = 0;
        while (done < count) {
            int batch = Math.min(SEED_BATCH, count - done);
            var rows = new ArrayList<Object[]>(batch);
            for (int i = 0; i < batch; i++) {
                var created = utc(now.minusSeconds(random.nextLong(365L * 24 * 3600)));
                rows.add(new Object[] {
                    requestIdParam(UUID.randomUUID()), "seed",
                    customers.get(random.nextInt(customers.size())),
                    SEED_STATUSES.get(random.nextInt(SEED_STATUSES.size())),
                    random.nextLong(500, 50_000), created, created});
            }
            retrier.run("seed", () -> writerTemplate.batchUpdate(
                    "INSERT INTO orders (request_id, run_id, customer_id, status, total_cents, created_at, updated_at)"
                            + " VALUES (?, ?, ?, ?, ?, ?, ?)", rows));
            done += batch;
        }
        return done;
    }

    private List<Long> customerIdsOnWriter(int limit) {
        return writer.sql("SELECT id FROM customers ORDER BY id LIMIT ?").param(limit).query(Long.class).list();
    }

    static Order order(ResultSet rs, int rowNum) throws SQLException {
        return new Order(
                rs.getLong("id"),
                UUID.fromString(rs.getString("request_id")),
                rs.getString("run_id"),
                rs.getLong("customer_id"),
                rs.getString("status"),
                rs.getLong("total_cents"),
                instant(rs, "created_at"),
                instant(rs, "updated_at"));
    }

    static Instant instant(ResultSet rs, String column) throws SQLException {
        return rs.getObject(column, OffsetDateTime.class).toInstant();
    }

    static OffsetDateTime utc(Instant instant) {
        return instant.atOffset(ZoneOffset.UTC);
    }
}
