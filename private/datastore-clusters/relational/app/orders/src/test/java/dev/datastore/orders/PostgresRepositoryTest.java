package dev.datastore.orders;

import com.zaxxer.hikari.HikariDataSource;
import org.testcontainers.containers.JdbcDatabaseContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * PostgreSQL 16.13 on Debian trixie, as in the cluster. The official image:
 * CloudNativePG's has no entrypoint (its instance manager starts postgres).
 */
@Testcontainers
class PostgresRepositoryTest extends RepositoryContract {

    @Container
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer(
            DockerImageName.parse("postgres:16.13-trixie"));

    @Override
    JdbcDatabaseContainer<?> database() {
        return POSTGRES;
    }

    @Override
    String engine() {
        return "postgresql";
    }

    @Override
    OrderRepository repository(HikariDataSource dataSource, Retrier retrier) {
        return new PostgresOrderRepository(dataSource, dataSource, retrier);
    }
}
