package dev.datastore.orders;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Two connection pools: the writer endpoint (primary; Flyway migrates
 * through it) and the reader endpoint. Settings come from orders.writer.*
 * and orders.reader.* (application-<engine>.yaml).
 */
@Configuration(proxyBeanMethods = false)
class DataSources {

    @Bean
    @Primary
    @ConfigurationProperties("orders.writer")
    HikariDataSource writerDataSource() {
        return new HikariDataSource();
    }

    @Bean
    @ConfigurationProperties("orders.reader")
    HikariDataSource readerDataSource() {
        return new HikariDataSource();
    }

    @Bean
    OrderRepository orderRepository(@Value("${orders.engine}") String engine,
                                    HikariDataSource writerDataSource,
                                    @Qualifier("readerDataSource") HikariDataSource readerDataSource,
                                    Retrier retrier) {
        return switch (engine) {
            case "postgresql" -> new PostgresOrderRepository(writerDataSource, readerDataSource, retrier);
            case "mysql" -> new MySqlOrderRepository(writerDataSource, readerDataSource, retrier);
            default -> throw new IllegalStateException("orders.engine must be postgresql or mysql, not " + engine);
        };
    }
}
