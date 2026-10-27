-- Customers and their orders.
--
-- The planted "oops" (DESIGN.md section 8): orders are searched by customer
-- and status, and nothing indexes that. No foreign key either: InnoDB would
-- create an index for one on the MySQL side, quietly fixing the search there.
-- Runbook 2 finds the slow search from the dashboards and query statistics;
-- runbook 17 adds the index online (CREATE INDEX CONCURRENTLY).

CREATE TABLE customers (
    id         bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       text        NOT NULL,
    email      text        NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Client-chosen idempotency key: a create retried after a failover
    -- returns the order already written instead of a duplicate.
    request_id  uuid        NOT NULL UNIQUE,
    -- Which load-test run (or 'seed') wrote the row.
    run_id      text,
    customer_id bigint      NOT NULL,
    status      text        NOT NULL,
    total_cents bigint      NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
