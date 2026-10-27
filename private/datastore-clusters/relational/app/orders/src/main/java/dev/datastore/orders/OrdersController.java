package dev.datastore.orders;

import dev.datastore.orders.Model.Customer;
import dev.datastore.orders.Model.NewCustomer;
import dev.datastore.orders.Model.NewOrder;
import dev.datastore.orders.Model.Order;
import dev.datastore.orders.Model.OrderSearch;
import dev.datastore.orders.Model.StatusChange;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * CRUDS over HTTP. Search has two forms (DESIGN.md section 8): GET with a
 * query string for simple filters, POST /orders/_search with a JSON body for
 * the rest.
 */
@RestController
class OrdersController {

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 100;

    private final OrderRepository orders;

    OrdersController(OrderRepository orders) {
        this.orders = orders;
    }

    @PostMapping("/customers")
    ResponseEntity<Customer> createCustomer(@RequestBody NewCustomer c) {
        require(c.name() != null && !c.name().isBlank(), "name is required");
        require(c.email() != null && c.email().contains("@"), "email is required");
        Customer created = orders.createCustomer(c.name(), c.email());
        return ResponseEntity.created(URI.create("/customers/" + created.id())).body(created);
    }

    @GetMapping("/customers/{id}")
    Customer customer(@PathVariable long id) {
        return orders.customer(id).orElseThrow(OrdersController::notFound);
    }

    @GetMapping("/customers/ids")
    List<Long> customerIds(@RequestParam(defaultValue = "1000") int limit) {
        require(limit > 0 && limit <= 10_000, "limit must be 1-10000");
        return orders.customerIds(limit);
    }

    @PostMapping("/orders")
    ResponseEntity<Order> createOrder(@RequestBody NewOrder o) {
        require(o.customerId() != null && o.customerId() > 0, "customerId is required");
        require(o.totalCents() != null && o.totalCents() >= 0, "totalCents must be 0 or more");
        String status = o.status() == null ? "NEW" : o.status();
        requireStatus(status);
        UUID requestId = o.requestId() == null ? UUID.randomUUID() : o.requestId();
        Order created = orders.createOrder(new NewOrder(o.customerId(), status, o.totalCents(), requestId, o.runId()));
        return ResponseEntity.created(URI.create("/orders/" + created.id())).body(created);
    }

    @GetMapping("/orders/{id}")
    Order order(@PathVariable long id) {
        return orders.order(id).orElseThrow(OrdersController::notFound);
    }

    @PatchMapping("/orders/{id}")
    Order updateOrder(@PathVariable long id, @RequestBody StatusChange change) {
        requireStatus(change.status());
        return orders.updateStatus(id, change.status()).orElseThrow(OrdersController::notFound);
    }

    @DeleteMapping("/orders/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void deleteOrder(@PathVariable long id) {
        orders.deleteOrder(id);
    }

    @GetMapping("/orders")
    List<Order> listOrders(@RequestParam(required = false) Long customerId,
                           @RequestParam(required = false) String status,
                           @RequestParam(required = false) Integer limit) {
        return search(new OrderSearch(customerId, status, null, null, null, limit));
    }

    @PostMapping("/orders/_search")
    List<Order> search(@RequestBody OrderSearch s) {
        require(s.customerId() != null || s.status() != null, "customerId or status is required");
        if (s.status() != null) {
            requireStatus(s.status());
        }
        int limit = s.limit() == null ? DEFAULT_LIMIT : s.limit();
        require(limit > 0 && limit <= MAX_LIMIT, "limit must be 1-" + MAX_LIMIT);
        return orders.search(new OrderSearch(s.customerId(), s.status(), s.createdAfter(), s.createdBefore(),
                s.minTotalCents(), limit));
    }

    static void require(boolean ok, String message) {
        if (!ok) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
    }

    private static void requireStatus(String status) {
        require(status != null && Model.STATUSES.contains(status), "status must be one of " + Model.STATUSES);
    }

    private static ResponseStatusException notFound() {
        return new ResponseStatusException(HttpStatus.NOT_FOUND);
    }
}
