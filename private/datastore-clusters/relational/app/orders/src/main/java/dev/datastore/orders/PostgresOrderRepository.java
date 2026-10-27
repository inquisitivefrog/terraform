package dev.datastore.orders;

import dev.datastore.orders.Model.NewOrder;
import java.util.UUID;
import javax.sql.DataSource;

/** PostgreSQL: request ids are native uuids; the insert skips a duplicate key. */
class PostgresOrderRepository extends SqlOrderRepository {

    PostgresOrderRepository(DataSource writer, DataSource reader, Retrier retrier) {
        super(writer, reader, retrier);
    }

    @Override
    protected long insertOrIgnoreOrder(NewOrder o) {
        // RETURNING yields no row when the request id already exists.
        return writer.sql("""
                        INSERT INTO orders (request_id, run_id, customer_id, status, total_cents)
                        VALUES (?, ?, ?, ?, ?)
                        ON CONFLICT (request_id) DO NOTHING
                        RETURNING id""")
                .params(o.requestId(), o.runId(), o.customerId(), o.status(), o.totalCents())
                .query(Long.class)
                .optional()
                .orElseGet(() -> writer.sql("SELECT id FROM orders WHERE request_id = ?")
                        .param(o.requestId())
                        .query(Long.class)
                        .single());
    }

    @Override
    protected Object requestIdParam(UUID requestId) {
        return requestId;
    }
}
