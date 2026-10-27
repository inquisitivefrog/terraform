# orders: the relational example app and its load

A small HTTP CRUDS service for orders and customers, run once per engine
(`orders-pg`, `orders-mysql`), and the k6 load that judges every runbook.
Why it is shaped this way: [DESIGN.md](../../docs/DESIGN.md) sections 3 and 8.

| Path | What |
|---|---|
| `orders/` | Spring Boot 4.1 on Java 25. `ORDERS_ENGINE` (postgresql or mysql) picks the repository, its SQL and the connection settings (`application-<engine>.yaml`) |
| `orders/src/main/resources/db/migration/<engine>/` | Flyway schema, one per engine, with the planted missing index |
| `orders/src/test/` | Repository tests against the cluster's engine versions in throwaway containers |
| `k6/orders.js` | The load: `run` (the CRUDS mix) and `seed` (bulk rows) |
| `dashboards/orders-load.json` | Grafana: **Relational / Orders load (k6 and app)** |
| `../modules/orders-app/` | Deployment (2 pods across zones), Service, ServiceMonitor |
| `../environments/dev/app/` | Root 3: both apps, the k6 script ConfigMap, the dashboard |

## The API

| Operation | Request | Endpoint |
|---|---|---|
| create | `POST /orders` `{customerId, totalCents, status?, requestId?, runId?}` | writer |
| read | `GET /orders/{id}` | writer (a client reads its own writes) |
| update | `PATCH /orders/{id}` `{status}` | writer |
| delete | `DELETE /orders/{id}` (204 even if already gone) | writer |
| search | `GET /orders?customerId=&status=&limit=` or `POST /orders/_search` `{customerId?, status?, createdAfter?, createdBefore?, minTotalCents?, limit?}` | reader (may be a moment behind) |
| customers | `POST /customers`, `GET /customers/{id}`, `GET /customers/ids?limit=` | |
| load support | `POST /admin/seed` `{customers?, orders?}`, `GET /admin/runs/{runId}/orders/count` | writer |
| metrics, probes | `/actuator/prometheus`, `/actuator/health/{liveness,readiness}` | |

Behaviour the runbooks rely on:
- **Retries across a failover.** A call that fails for a transient reason
  (connection lost, server shutting down, a demoted primary, a deadlock or
  Galera certification conflict) is retried 3 times with backoff; then the
  API answers 503. Creates are idempotent on `requestId`, so a retry never
  duplicates an order. A full connection pool or a statement timeout is
  never retried: that is overload, and the API answers 503 at once.
- **Timeouts.** PostgreSQL: `statement_timeout` 5 s, idle in transaction
  10 s. MySQL: `max_execution_time` 5 s (SELECTs only: MySQL has no
  statement timeout for writes), lock waits 5 s.
- **Galera read-your-writes.** The MySQL writer pool sets
  `wsrep_sync_wait=1`, so a read after HAProxy moves the writer to another
  node still sees what the client just wrote.
- **TLS verified** against each cluster's CA (PostgreSQL also checks the
  host name). For PXC that is the CA in `mysql-ssl-internal`, not
  `mysql-ssl`: mysqld presents the operator's internal certificate to
  clients as well as between nodes, and the two Secrets hold different
  root CAs.
- **Least privilege.** Each app logs in as the database's `app` user,
  never a superuser or an operator system user.
- **The planted "oops".** Nothing indexes `orders (customer_id, status)` and
  there is no foreign key (InnoDB would add an index for one). Searches
  scan the whole table: fine at first, slower as data grows.

## Test

The repository tests start PostgreSQL 16.13 and Percona XtraDB Cluster
8.0.44 (a one-node Galera cluster, strict mode on) in throwaway containers,
migrate them with the app's Flyway scripts and run the CRUDS operations,
idempotent create, search and seeding against each. Docker Desktop must be
running; about 2 minutes, mostly container start-up.

```sh
cd private/datastore-clusters/relational/app/orders
mvn test
```

## Build, deploy, load

From `private/datastore-clusters/relational`:

```sh
scripts/build_app.sh --test        # tests, then build orders:<pom version> and load it into the kind nodes

cd environments/dev/app            # needs the clusters root applied
terraform init && terraform plan -out plan-app && terraform apply plan-app
cd ../../..
scripts/check_resources.sh         # adds the orders app checks

scripts/load_test.sh pg seed               # 10000 customers, 300000 orders (a few minutes)
scripts/load_test.sh pg run                # 50 requests/s for 5 minutes
scripts/load_test.sh mysql seed
scripts/load_test.sh mysql run 50 10m
```

A code change needs a new version in `orders/pom.xml`, then
`build_app.sh` and `terraform apply -var app_image=orders:<version>` (or
change the default in `variables.tf`): the pods keep the image they have
while the tag is unchanged.

A seed stops at its first failed batch and reports FAILED: a failing bulk
write means the cluster is in trouble (on 2026-10-27 one wrote a PXC node
into an OOM kill). `load_test.sh` prints the Grafana link for the run (Grafana's port-forward:
`platform/scripts/grafana_restart.sh`) and k6's summary at the end. It exits
non-zero if any operation missed its SLO or a write was lost.

## The load

| | |
|---|---|
| Model | Open: a fixed number of requests per second whatever the latency (`constant-arrival-rate`). A slowdown shows as latency and dropped iterations instead of hiding as less load |
| Mix | create 20%, read 45%, search 20%, update 10%, delete 5%; each tagged `op` |
| SLO (thresholds) | p95: read 100 ms, create/update/delete 200 ms, search 300 ms; under 1% errors per operation; no lost writes |
| Lost writes | Each virtual user reads and updates only orders it created and was told succeeded; a 404 for one is an acknowledged write gone (`orders_lost`, must be 0) |
| Results | Pushed to Prometheus every 5 s (labels `testid` = the run id, `engine`, `op`) |

Expect the search SLO to fail once the data is seeded: that is the planted
problem for runbooks 2 and 17.
