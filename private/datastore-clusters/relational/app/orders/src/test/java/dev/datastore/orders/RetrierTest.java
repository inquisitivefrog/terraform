package dev.datastore.orders;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.CannotGetJdbcConnectionException;

/** Which failures are retried: a failover's, not an overloaded pool's. */
class RetrierTest {

    private final SimpleMeterRegistry registry = new SimpleMeterRegistry();
    private final Retrier retrier = new Retrier(registry);

    @Test
    void retriesWhenTheDatabaseCannotBeReached() {
        var refused = new SQLException("Connection refused", "08001");
        var e = new CannotGetJdbcConnectionException("no connection",
                new SQLTransientConnectionException("writer - Connection is not available", "08001", refused));
        assertThat(Retrier.isTransient(e)).isTrue();
    }

    @Test
    void doesNotRetryAFullPool() {
        var e = new CannotGetJdbcConnectionException("no connection",
                new SQLTransientConnectionException("reader - Connection is not available, request timed out after 3000ms"));
        assertThat(Retrier.isTransient(e)).isFalse();

        var calls = new AtomicInteger();
        assertThatThrownBy(() -> retrier.call("search", () -> {
            calls.incrementAndGet();
            throw e;
        })).isSameAs(e);
        assertThat(calls).hasValue(1);
        assertThat(registry.find("orders.db.retries").counter()).isNull();
    }

    @Test
    void retriesAGaleraCertificationConflictThenSucceeds() {
        var conflict = new org.springframework.dao.CannotAcquireLockException("deadlock",
                new SQLException("Deadlock found when trying to get lock", "40001", 1213));
        var calls = new AtomicInteger();
        String result = retrier.call("update", () -> {
            if (calls.incrementAndGet() < 3) throw conflict;
            return "ok";
        });
        assertThat(result).isEqualTo("ok");
        assertThat(registry.counter("orders.db.retries", "op", "update").count()).isEqualTo(2);
    }

    @Test
    void doesNotRetryAStatementTimeout() {
        var postgres = new org.springframework.jdbc.support.SQLErrorCodeSQLExceptionTranslator("PostgreSQL")
                .translate("search", "SELECT", new SQLException("canceling statement due to statement timeout", "57014"));
        assertThat(postgres).isInstanceOf(org.springframework.dao.QueryTimeoutException.class);
        assertThat(Retrier.isTransient(postgres)).isFalse();

        var mysql = new org.springframework.jdbc.UncategorizedSQLException("search", "SELECT",
                new SQLException("Query execution was interrupted, maximum statement execution time exceeded", "HY000", 3024));
        assertThat(Retrier.isTransient(mysql)).isFalse();
    }

    @Test
    void doesNotRetryAConstraintViolation() {
        var e = new DataIntegrityViolationException("duplicate", new SQLException("duplicate key", "23505"));
        assertThat(Retrier.isTransient(e)).isFalse();
    }
}
