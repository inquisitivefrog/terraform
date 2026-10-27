package dev.datastore.orders;

import dev.datastore.orders.Model.Count;
import dev.datastore.orders.Model.Seed;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Load-test support: bulk seeding (so the planted slow search shows without
 * hours of load) and counting a run's rows. In-cluster only, like the API.
 */
@RestController
@RequestMapping("/admin")
class AdminController {

    private static final int MAX_SEED = 100_000;

    private final OrderRepository orders;

    AdminController(OrderRepository orders) {
        this.orders = orders;
    }

    @PostMapping("/seed")
    Map<String, Integer> seed(@RequestBody Seed seed) {
        int customers = seed.customers() == null ? 0 : seed.customers();
        int count = seed.orders() == null ? 0 : seed.orders();
        OrdersController.require(customers >= 0 && customers <= MAX_SEED && count >= 0 && count <= MAX_SEED,
                "customers and orders must be 0-" + MAX_SEED + " per call");
        return Map.of("customers", orders.seedCustomers(customers), "orders", orders.seedOrders(count));
    }

    @GetMapping("/runs/{runId}/orders/count")
    Count countRun(@PathVariable String runId) {
        return new Count(orders.countByRun(runId));
    }
}
