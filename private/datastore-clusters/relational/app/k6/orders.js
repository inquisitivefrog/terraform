// CRUDS load against the orders app (DESIGN.md section 8; RUNBOOKS.md 5).
// Run in the cluster by scripts/load_test.sh, which sets the environment:
//
//   BASE_URL     http://orders-pg.relational.svc:8080
//   MODE         run (the CRUDS mix) or seed (bulk rows for the planted slow search)
//   RATE         run: iterations per second, whatever the latency (open model)
//   DURATION     run: e.g. 5m
//   SEED_ORDERS  seed: orders to add (customers are seeded once, first)
//   RUN_ID       tags every row this run writes, and its metrics (testid)
//
// The mix is a read-heavy web shop's: create 20%, read 45%, search 20%,
// update 10%, delete 5%. Each operation is tagged op=<name> and has its own
// thresholds: the SLO. Search is kept apart from read on purpose: a read by
// key costs the same at any size, a search doesn't.
//
// Lost writes (runbook 24): every virtual user keeps the ids of orders it
// created and was told succeeded, and reads and updates only those, cycling
// through them. Nothing else deletes them, so a 404 for one means an
// acknowledged write is gone: counted in orders_lost, which must stay 0.

import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';

const BASE = __ENV.BASE_URL;
const MODE = __ENV.MODE || 'run';
const RATE = Number(__ENV.RATE || 50);
const DURATION = __ENV.DURATION || '5m';
const SEED_ORDERS = Number(__ENV.SEED_ORDERS || 300000);
const RUN_ID = __ENV.RUN_ID || 'adhoc';

const SEED_CUSTOMERS = 10000;
const SEED_BATCH = 10000;
const MIX = [['create', 20], ['read', 45], ['search', 20], ['update', 10], ['delete', 5]];
const STATUSES = ['NEW', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
const MAX_TRACKED = 5000;

const ordersLost = new Counter('orders_lost');
const ordersCreated = new Counter('orders_created');
const ordersDeleted = new Counter('orders_deleted');

// Latency SLO per operation (p95, milliseconds) and at most 1% errors each.
const SLO_P95 = { create: 200, read: 100, search: 300, update: 200, delete: 200 };

function thresholds() {
  const t = { orders_lost: ['count==0'] };
  for (const [op, p95] of Object.entries(SLO_P95)) {
    t[`http_req_duration{op:${op}}`] = [`p(95)<${p95}`];
    t[`http_req_failed{op:${op}}`] = ['rate<0.01'];
  }
  return t;
}

export const options = {
  // No url tag: every order id would be its own Prometheus series. The
  // name tag (e.g. "GET /orders/{id}") groups them instead.
  systemTags: ['status', 'method', 'name', 'scenario', 'expected_response', 'error_code'],
  scenarios: MODE === 'seed'
    ? {
        seed: {
          executor: 'shared-iterations',
          vus: 4,
          iterations: Math.ceil(SEED_ORDERS / SEED_BATCH),
          maxDuration: '60m',
        },
      }
    : {
        cruds: {
          executor: 'constant-arrival-rate',
          rate: RATE,
          timeUnit: '1s',
          duration: DURATION,
          preAllocatedVUs: 20,
          maxVUs: 200,
        },
      },
  // A seed batch that fails means the cluster is in trouble: stop at the
  // first one (and exit non-zero) rather than keep writing into it.
  thresholds: MODE === 'seed' ? { checks: [{ threshold: 'rate==1', abortOnFail: true }] } : thresholds(),
};

const JSON_HEADERS = { 'Content-Type': 'application/json' };

export function setup() {
  if (MODE === 'seed') {
    const have = http.get(`${BASE}/customers/ids?limit=1`).json();
    if (have.length === 0) {
      const res = http.post(`${BASE}/admin/seed`, JSON.stringify({ customers: SEED_CUSTOMERS }),
        { headers: JSON_HEADERS, timeout: '300s' });
      check(res, { 'customers seeded': (r) => r.status === 200 });
    }
    return {};
  }
  const customers = http.get(`${BASE}/customers/ids?limit=2000`).json();
  if (customers.length === 0) {
    throw new Error('no customers: run the seed first (load_test.sh <engine> seed)');
  }
  return { customers };
}

// Per virtual user: orders it created, acknowledged and hasn't deleted.
const mine = [];
let cursor = 0;

function pick(list) {
  return list[Math.floor(Math.random() * list.length)];
}

function chooseOp() {
  let r = Math.random() * 100;
  for (const [op, weight] of MIX) {
    if ((r -= weight) < 0) return op;
  }
  return 'read';
}

function nextMine() {
  cursor = (cursor + 1) % mine.length;
  return mine[cursor];
}

function tags(op, name) {
  return { tags: { op, name }, headers: JSON_HEADERS };
}

function create(data) {
  const body = {
    customerId: pick(data.customers),
    totalCents: 500 + Math.floor(Math.random() * 50000),
    requestId: crypto.randomUUID(),
    runId: RUN_ID,
  };
  const res = http.post(`${BASE}/orders`, JSON.stringify(body), tags('create', 'POST /orders'));
  if (check(res, { 'create 201': (r) => r.status === 201 })) {
    ordersCreated.add(1);
    mine.push(res.json('id'));
    if (mine.length > MAX_TRACKED) mine.shift();
  }
}

function read() {
  const id = nextMine();
  const res = http.get(`${BASE}/orders/${id}`, tags('read', 'GET /orders/{id}'));
  if (res.status === 404) ordersLost.add(1, { op: 'read' });
  check(res, { 'read 200': (r) => r.status === 200 });
}

function search(data) {
  const customerId = pick(data.customers);
  let res;
  if (Math.random() < 0.5) {
    res = http.get(`${BASE}/orders?customerId=${customerId}&status=${pick(STATUSES)}&limit=20`,
      tags('search', 'GET /orders?customerId&status'));
  } else {
    const createdAfter = new Date(Date.now() - 30 * 24 * 3600 * 1000).toISOString();
    res = http.post(`${BASE}/orders/_search`, JSON.stringify({ customerId, createdAfter, limit: 20 }),
      tags('search', 'POST /orders/_search'));
  }
  check(res, { 'search 200': (r) => r.status === 200 });
}

function update() {
  const id = nextMine();
  const res = http.patch(`${BASE}/orders/${id}`, JSON.stringify({ status: pick(STATUSES) }),
    tags('update', 'PATCH /orders/{id}'));
  if (res.status === 404) ordersLost.add(1, { op: 'update' });
  check(res, { 'update 200': (r) => r.status === 200 });
}

function remove() {
  const i = Math.floor(Math.random() * mine.length);
  const id = mine[i];
  // Stop tracking it either way: if the outcome is unknown (an error), a
  // later 404 would prove nothing.
  mine[i] = mine[mine.length - 1];
  mine.pop();
  const res = http.del(`${BASE}/orders/${id}`, null, tags('delete', 'DELETE /orders/{id}'));
  if (check(res, { 'delete 204': (r) => r.status === 204 })) ordersDeleted.add(1);
}

function seedBatch() {
  const res = http.post(`${BASE}/admin/seed`, JSON.stringify({ orders: SEED_BATCH }),
    { headers: JSON_HEADERS, timeout: '300s', tags: { op: 'seed', name: 'POST /admin/seed' } });
  check(res, { 'seed 200': (r) => r.status === 200 });
}

export default function (data) {
  if (MODE === 'seed') return seedBatch();

  let op = chooseOp();
  // Reads, updates and deletes need an order of this user's own.
  if (mine.length === 0 && op !== 'search') op = 'create';
  switch (op) {
    case 'create': return create(data);
    case 'read': return read();
    case 'search': return search(data);
    case 'update': return update();
    case 'delete': return remove();
  }
}
