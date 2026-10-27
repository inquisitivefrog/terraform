package dev.datastore.orders;

import com.zaxxer.hikari.HikariDataSource;
import org.testcontainers.containers.JdbcDatabaseContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.mysql.MySQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * The cluster's own image: Percona XtraDB Cluster 8.0.44 as a one-node
 * Galera cluster, with its default pxc_strict_mode=ENFORCING (which, for
 * one, refuses GET_LOCK).
 */
@Testcontainers
class MySqlRepositoryTest extends RepositoryContract {

    @Container
    static final MySQLContainer MYSQL = new MySQLContainer(
            DockerImageName.parse("percona/percona-xtradb-cluster:8.0.44-35.1")
                    .asCompatibleSubstituteFor("mysql"))
            .withDatabaseName("appdb");

    @Override
    JdbcDatabaseContainer<?> database() {
        return MYSQL;
    }

    @Override
    String jdbcUrl() {
        return MYSQL.getJdbcUrl()
                + "?rewriteBatchedStatements=true&connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true";
    }

    @Override
    String engine() {
        return "mysql";
    }

    @Override
    OrderRepository repository(HikariDataSource dataSource, Retrier retrier) {
        return new MySqlOrderRepository(dataSource, dataSource, retrier);
    }
}
