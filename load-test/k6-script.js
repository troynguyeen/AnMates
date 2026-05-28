import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter, Rate } from 'k6/metrics';

// ─── Custom metrics ───────────────────────────────────────────────
const profileLatency      = new Trend('profile_latency',       true);
const wishlistLatency     = new Trend('wishlist_latency',      true);
const matchesLatency      = new Trend('matches_latency',       true);
const conversationsLatency= new Trend('conversations_latency', true);
const authLatency         = new Trend('auth_latency',          true);
const errorCount          = new Counter('errors');
const errorRate           = new Rate('error_rate');

// ─── Thresholds (SLO) ─────────────────────────────────────────────
export const options = {
  scenarios: {
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 50  },  // warm-up
        { duration: '60s', target: 300 },  // ramp to target load
        { duration: '60s', target: 300 },  // sustain
        { duration: '30s', target: 500 },  // peak spike
        { duration: '30s', target: 0   },  // cooldown
      ],
      gracefulRampDown: '15s',
    },
  },
  thresholds: {
    http_req_duration:       ['p(95)<500', 'p(99)<1000'],
    http_req_failed:         ['rate<0.01'],
    error_rate:              ['rate<0.01'],
    profile_latency:         ['p(95)<400'],
    wishlist_latency:        ['p(95)<400'],
    matches_latency:         ['p(95)<500'],
    conversations_latency:   ['p(95)<500'],
  },
};

const BASE_URL   = __ENV.BASE_URL   || 'http://localhost:8080';
const DEV_SECRET = __ENV.DEV_SECRET || 'loadtest-secret-2026';
const USER_POOL  = parseInt(__ENV.USER_POOL || '100', 10);

// ─── setup(): build user pool ─────────────────────────────────────
// Called once before any VU starts; return value is passed to default().
export function setup() {
  // Wait for the API to be healthy (up to 60 s).
  let ready = false;
  for (let i = 0; i < 20; i++) {
    const r = http.get(`${BASE_URL}/health`, { timeout: '3s' });
    if (r.status === 200) { ready = true; break; }
    sleep(3);
  }
  if (!ready) {
    throw new Error('API did not become healthy within 60 s');
  }

  const tokens = [];
  for (let i = 0; i < USER_POOL; i++) {
    const email = `loadtest-${i}@anmates.dev`;
    const payload = JSON.stringify({ email, secret: DEV_SECRET });
    const headers = { 'Content-Type': 'application/json' };

    const r = http.post(`${BASE_URL}/api/v1/auth/dev-login`, payload, { headers, timeout: '5s' });
    if (r.status !== 200) {
      console.warn(`User ${i}: dev-login failed (${r.status}) — ${r.body}`);
      continue;
    }
    const body = JSON.parse(r.body);
    const accessToken = body.data && body.data.access_token;
    if (accessToken) {
      tokens.push(accessToken);
    }
  }

  if (tokens.length === 0) {
    throw new Error('setup(): zero tokens acquired — abort');
  }
  console.log(`setup(): acquired ${tokens.length}/${USER_POOL} user tokens`);
  return { tokens };
}

// ─── helpers ──────────────────────────────────────────────────────
function authHeaders(token) {
  return { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function record(res, trend, label, okStatuses) {
  const ok = okStatuses
    ? okStatuses.includes(res.status)
    : res.status >= 200 && res.status < 300;
  if (!ok) {
    errorCount.add(1);
    errorRate.add(1);
    console.warn(`${label}: status=${res.status}`);
  } else {
    errorRate.add(0);
  }
  if (trend) trend.add(res.timings.duration);
  check(res, { [`${label} ok`]: () => ok });
  return ok;
}

// ─── default VU function ──────────────────────────────────────────
export default function ({ tokens }) {
  if (!tokens || tokens.length === 0) return;

  const token = pick(tokens);
  const h     = authHeaders(token);

  // Weighted scenario: realistic mobile traffic mix.
  const roll = Math.random();

  if (roll < 0.05) {
    // 5 % — health check (unauthenticated, cheapest)
    const r = http.get(`${BASE_URL}/health`, { timeout: '3s' });
    record(r, null, 'GET /health');

  } else if (roll < 0.25) {
    // 20 % — GET /profile
    const r = http.get(`${BASE_URL}/api/v1/profile`, { headers: h, timeout: '5s' });
    record(r, profileLatency, 'GET /profile');

  } else if (roll < 0.45) {
    // 20 % — GET /wishlist
    const r = http.get(`${BASE_URL}/api/v1/wishlist`, { headers: h, timeout: '5s' });
    record(r, wishlistLatency, 'GET /wishlist');

  } else if (roll < 0.65) {
    // 20 % — POST /wishlist (write traffic to stress the pool)
    const foods = [
      'Lẩu bò', 'Bánh mì', 'Phở gà', 'Bún chả', 'Cơm tấm', 'Bánh xèo',
      'Bánh cuốn', 'Bún bò Huế', 'Cháo lòng', 'Hủ tiếu', 'Mì Quảng',
      'Bánh canh', 'Cơm hến', 'Xôi gà', 'Bún thịt nướng', 'Chả giò',
      'Gỏi cuốn', 'Bánh tráng trộn', 'Cơm chiên dương châu', 'Lẩu hải sản',
    ];
    const cats  = ['bun', 'pho', 'com', 'lau', 'bbq', 'cafe', 'trang_mieng', 'other'];
    const body  = JSON.stringify({ food_name: pick(foods), food_category: pick(cats) });
    const r = http.post(`${BASE_URL}/api/v1/wishlist`, body, { headers: h, timeout: '5s' });
    // 409 Conflict = duplicate entry — expected behaviour, not an error
    record(r, wishlistLatency, 'POST /wishlist', [200, 201, 409]);

  } else if (roll < 0.80) {
    // 15 % — GET /matches
    const r = http.get(`${BASE_URL}/api/v1/matches`, { headers: h, timeout: '5s' });
    record(r, matchesLatency, 'GET /matches');

  } else if (roll < 0.92) {
    // 12 % — GET /conversations
    const r = http.get(`${BASE_URL}/api/v1/conversations`, { headers: h, timeout: '5s' });
    record(r, conversationsLatency, 'GET /conversations');

  } else {
    // 8 % — token refresh (simulates 15-min token expiry churn)
    // dev-login tokens are long-lived so we just re-login to simulate the path.
    const i       = Math.floor(Math.random() * USER_POOL);
    const email   = `loadtest-${i}@anmates.dev`;
    const payload = JSON.stringify({ email, secret: DEV_SECRET });
    const r = http.post(`${BASE_URL}/api/v1/auth/dev-login`, payload, { headers: { 'Content-Type': 'application/json' }, timeout: '5s' });
    record(r, authLatency, 'POST /auth/dev-login');
  }

  // Think time: 0.5–1.5 s (realistic mobile pacing)
  sleep(0.5 + Math.random());
}

// ─── teardown(): summary note ─────────────────────────────────────
export function teardown(data) {
  console.log(`teardown(): test complete. Tokens used: ${data.tokens.length}`);
}
