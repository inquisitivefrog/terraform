package dev.datastore.orders;

import static org.assertj.core.api.Assertions.assertThat;

import com.zaxxer.hikari.HikariDataSource;
import dev.datastore.orders.Model.NewOrder;
import dev.datastore.orders.Model.Order;
import dev.datastore.orders.Model.OrderSearch;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.testcontainers.containers.JdbcDatabaseContainer;

/**
 * The repository against the real engine and version the cluster runs
 * (DESIGN.md section 3: Testcontainers, not mocks), migrated by the same
 * Flyway scripts. Writer and reader are the same server here.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
abstract class RepositoryContract {

    private HikariDataSource dataSource;
    private OrderRepository repo;

    abstract JdbcDatabaseContainer<?> database();

    abstract String engine();

    abstract OrderRepository repository(HikariDataSource dataSource, Retrier retrier);

    String jdbcUrl() {
        return database().getJdbcUrl();
    }

    @BeforeAll
    void migrate() {
        dataSource = new HikariDataSource();
        dataSource.setJdbcUrl(jdbcUrl());
        dataSource.setUsername(database().getUsername());
        dataSource.setPassword(database().getPassword());
        Flyway.configure().dataSource(dataSource).locations("classpath:db/migration/" + engine()).load().migrate();
        repo = repository(dataSource, new Retrier(new SimpleMeterRegistry()));
    }

    @AfterAll
    void close() {
        dataSource.close();
    }

    @Test
    void ordersRoundTrip() {
        var customer = repo.createCustomer("Ada", "ada@example.com");
        var requestId = UUID.randomUUID();
        Order created = repo.createOrder(new NewOrder(customer.id(), "NEW", 1234L, requestId, "test"));

        assertThat(created.customerId()).isEqualTo(customer.id());
        assertThat(created.requestId()).isEqualTo(requestId);
        assertThat(created.createdAt()).isCloseTo(Instant.now(), within60s());
        assertThat(repo.order(created.id())).contains(created);

        var updated = repo.updateStatus(created.id(), "PAID").orElseThrow();
        assertThat(updated.status()).isEqualTo("PAID");
        assertThat(updated.updatedAt()).isAfterOrEqualTo(created.updatedAt());

        repo.deleteOrder(created.id());
        repo.deleteOrder(created.id()); // idempotent
        assertThat(repo.order(created.id())).isEmpty();
        assertThat(repo.updateStatus(created.id(), "PAID")).isEmpty();
    }

    @Test
    void createIsIdempotentOnRequestId() {
        var customer = repo.createCustomer("Bo", "bo@example.com");
        var order = new NewOrder(customer.id(), "NEW", 500L, UUID.randomUUID(), "idem");

        Order first = repo.createOrder(order);
        Order retried = repo.createOrder(order);

        assertThat(retried.id()).isEqualTo(first.id());
        assertThat(repo.countByRun("idem")).isEqualTo(1);
    }

    @Test
    void searchFiltersAndSortsNewestFirst() {
        var customer = repo.createCustomer("Cy", "cy@example.com");
        for (int i = 0; i < 3; i++) {
            repo.createOrder(new NewOrder(customer.id(), "NEW", 100L * i, UUID.randomUUID(), "search"));
        }
        repo.createOrder(new NewOrder(customer.id(), "SHIPPED", 999L, UUID.randomUUID(), "search"));

        var byStatus = repo.search(new OrderSearch(customer.id(), "NEW", null, null, null, 10));
        assertThat(byStatus).hasSize(3).allMatch(o -> o.status().equals("NEW"));
        assertThat(byStatus.get(0).id()).isGreaterThan(byStatus.get(2).id());

        var recentBig = repo.search(new OrderSearch(customer.id(), null,
                Instant.now().minus(1, ChronoUnit.HOURS), Instant.now().plus(1, ChronoUnit.HOURS), 150L, 10));
        assertThat(recentBig).extracting(Order::totalCents).containsExactlyInAnyOrder(200L, 999L);
    }

    @Test
    void seedsCustomersThenOrdersOverThePastYear() {
        assertThat(repo.seedCustomers(50)).isEqualTo(50);
        assertThat(repo.seedOrders(2500)).isEqualTo(2500);
        assertThat(repo.countByRun("seed")).isEqualTo(2500);
        assertThat(repo.customerIds(10)).hasSize(10);

        var old = repo.search(new OrderSearch(null, "DELIVERED", null,
                Instant.now().minus(30, ChronoUnit.DAYS), null, 100));
        assertThat(old).isNotEmpty().allMatch(o -> o.createdAt().isBefore(Instant.now().minus(30, ChronoUnit.DAYS)));
    }

    private static org.assertj.core.data.TemporalUnitOffset within60s() {
        return org.assertj.core.api.Assertions.within(60, ChronoUnit.SECONDS);
    }
}
