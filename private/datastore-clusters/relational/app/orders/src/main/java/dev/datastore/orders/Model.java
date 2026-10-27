package dev.datastore.orders;

import java.time.Instant;
import java.util.Set;
import java.util.UUID;

/** The API's records. */
final class Model {

    static final Set<String> STATUSES = Set.of("NEW", "PAID", "SHIPPED", "DELIVERED", "CANCELLED");

    private Model() {}

    record Customer(long id, String name, String email, Instant createdAt) {}

    record NewCustomer(String name, String email) {}

    record Order(long id, UUID requestId, String runId, long customerId, String status,
                 long totalCents, Instant createdAt, Instant updatedAt) {}

    /** requestId is the client's idempotency key; runId tags load-test rows. */
    record NewOrder(Long customerId, String status, Long totalCents, UUID requestId, String runId) {}

    record StatusChange(String status) {}

    /** Every field is optional, but at least one of customerId and status is required. */
    record OrderSearch(Long customerId, String status, Instant createdAfter, Instant createdBefore,
                       Long minTotalCents, Integer limit) {}

    record Seed(Integer customers, Integer orders) {}

    record Count(long count) {}
}
