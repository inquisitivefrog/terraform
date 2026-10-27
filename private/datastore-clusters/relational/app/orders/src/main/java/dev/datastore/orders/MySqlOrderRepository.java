package dev.datastore.orders;

import dev.datastore.orders.Model.NewOrder;
import java.util.UUID;
import javax.sql.DataSource;
import org.springframework.jdbc.support.GeneratedKeyHolder;

/**
 * MySQL: request ids are CHAR(36). On a duplicate key the insert sets
 * LAST_INSERT_ID to the existing row's id, which the driver reports as the
 * generated key, so one statement covers both cases.
 */
class MySqlOrderRepository extends SqlOrderRepository {

    MySqlOrderRepository(DataSource writer, DataSource reader, Retrier retrier) {
        super(writer, reader, retrier);
    }

    @Override
    protected long insertOrIgnoreOrder(NewOrder o) {
        var keys = new GeneratedKeyHolder();
        writer.sql("""
                        INSERT INTO orders (request_id, run_id, customer_id, status, total_cents)
                        VALUES (?, ?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id)""")
                .params(o.requestId().toString(), o.runId(), o.customerId(), o.status(), o.totalCents())
                .update(keys);
        return keys.getKey().longValue();
    }

    @Override
    protected Object requestIdParam(UUID requestId) {
        return requestId.toString();
    }
}
