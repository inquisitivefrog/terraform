package dev.datastore.orders;

import dev.datastore.orders.Model.Customer;
import dev.datastore.orders.Model.NewOrder;
import dev.datastore.orders.Model.Order;
import dev.datastore.orders.Model.OrderSearch;
import java.util.List;
import java.util.Optional;

/**
 * The data-access layer (DESIGN.md section 3): one place for the queries,
 * read/write routing and retries across a failover. One implementation per
 * engine, each in that engine's own SQL.
 *
 * Routing: everything that writes, and every read by key, goes to the writer
 * endpoint, so a client always reads what it just wrote. Searches go to the
 * reader endpoint and may be a moment behind.
 */
interface OrderRepository {

    Customer createCustomer(String name, String email);

    Optional<Customer> customer(long id);

    /** Up to limit customer ids, for load generators to pick from. */
    List<Long> customerIds(int limit);

    /** Idempotent on requestId: a retry returns the order already written. */
    Order createOrder(NewOrder order);

    Optional<Order> order(long id);

    Optional<Order> updateStatus(long id, String status);

    /** Idempotent: deleting a missing order is not an error. */
    void deleteOrder(long id);

    /** Newest first. The planted slow path: nothing indexes these columns. */
    List<Order> search(OrderSearch search);

    long countByRun(String runId);

    int seedCustomers(int count);

    /** Orders for existing customers, created at random times over the past year. */
    int seedOrders(int count);
}
