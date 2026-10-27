-- Customers and their orders.
--
-- The planted "oops" (DESIGN.md section 8): orders are searched by customer
-- and status, and nothing indexes that. No foreign key either: InnoDB would
-- create an index for one, quietly fixing the search. Runbook 2 finds the
-- slow search from the dashboards and statement digests; runbook 17 adds the
-- index online (on Galera: pt-online-schema-change or a rolling schema
-- upgrade, since plain DDL blocks the whole cluster).
--
-- Times are UTC (the app pins the session time zone).

CREATE TABLE customers (
    id         BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(200) NOT NULL,
    email      VARCHAR(200) NOT NULL,
    created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE orders (
    id          BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY,
    -- Client-chosen idempotency key: a create retried after a failover
    -- returns the order already written instead of a duplicate.
    request_id  CHAR(36)    CHARACTER SET ascii NOT NULL,
    -- Which load-test run (or 'seed') wrote the row.
    run_id      VARCHAR(64),
    customer_id BIGINT      NOT NULL,
    status      VARCHAR(16) NOT NULL,
    total_cents BIGINT      NOT NULL,
    created_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE KEY uq_orders_request_id (request_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
