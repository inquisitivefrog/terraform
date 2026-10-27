package dev.datastore.orders;

import io.micrometer.core.instrument.MeterRegistry;
import java.sql.SQLException;
import java.sql.SQLTransientConnectionException;
import java.util.function.Supplier;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.dao.QueryTimeoutException;
import org.springframework.dao.RecoverableDataAccessException;
import org.springframework.dao.TransientDataAccessException;
import org.springframework.stereotype.Component;

/**
 * Retries a database call that failed for a reason a failover or a conflict
 * explains: no connection, the server shutting down, a former primary now
 * read-only, a deadlock or (Galera) a certification conflict. Not an
 * exhausted connection pool or a statement timeout: those are overload and
 * slowness, and retrying feeds them. Every call
 * passed here must be safe to repeat; the repository makes creates
 * idempotent for that reason.
 *
 * Backoff 0.1, 0.2, 0.4 s; with the pool's 3 s connection timeout a call
 * gives up after about 13 s, then the API answers 503.
 */
@Component
class Retrier {

    private static final int ATTEMPTS = 4;

    private final MeterRegistry registry;

    Retrier(MeterRegistry registry) {
        this.registry = registry;
    }

    <T> T call(String op, Supplier<T> action) {
        for (int attempt = 1; ; attempt++) {
            try {
                return action.get();
            } catch (DataAccessException e) {
                if (attempt >= ATTEMPTS || !isTransient(e)) {
                    throw e;
                }
                registry.counter("orders.db.retries", "op", op).increment();
                try {
                    Thread.sleep(100L << (attempt - 1));
                } catch (InterruptedException interrupted) {
                    Thread.currentThread().interrupt();
                    throw e;
                }
            }
        }
    }

    void run(String op, Runnable action) {
        call(op, () -> {
            action.run();
            return null;
        });
    }

    static boolean isTransient(DataAccessException e) {
        // The pool is full: every connection busy, none failed (HikariCP
        // attaches the last connection error when the database is the
        // problem). Retrying only queues the request again and adds load:
        // answer 503 now (2026-10-27: 2,924 search retries turned 3 s waits
        // into 12-17 s responses).
        if (e.getMostSpecificCause() instanceof SQLTransientConnectionException pool && pool.getCause() == null) {
            return false;
        }
        // The statement ran out of time: it is too slow, and running it again
        // repeats the same work on a server already busy with it. Spring calls
        // PostgreSQL's 57014 a (transient) QueryTimeoutException; MySQL's
        // max_execution_time is error 3024 (2026-10-27: 573 retried 5 s
        // scans on saturated replicas).
        if (e instanceof QueryTimeoutException
                || e.getMostSpecificCause() instanceof SQLException timeout
                        && ("57014".equals(timeout.getSQLState()) || timeout.getErrorCode() == 3024)) {
            return false;
        }
        if (e instanceof TransientDataAccessException
                || e instanceof RecoverableDataAccessException
                || e instanceof DataAccessResourceFailureException) {
            return true;
        }
        if (e.getMostSpecificCause() instanceof SQLException sql && sql.getSQLState() != null) {
            String state = sql.getSQLState();
            return state.startsWith("08")      // connection lost or refused (MySQL 1047: Galera node not ready)
                    || state.startsWith("40")  // deadlock, serialization or Galera certification failure
                    || state.startsWith("57P") // PostgreSQL shutting down
                    || state.equals("25006");  // read-only transaction: a demoted primary
        }
        return false;
    }
}
