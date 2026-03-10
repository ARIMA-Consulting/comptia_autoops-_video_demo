"""
Broken Flask app for Demo 23 — Troubleshooting Live Systems.

The app has an intentional misconfiguration: DATABASE_URL defaults to
a wrong host, causing /api/users to fail with 503 errors.

Troubleshooting flow:
  1. docker logs  → see JSON error entries
  2. curl         → reproduce the 503
  3. docker inspect / env → find the wrong DATABASE_URL
  4. Fix: restart with correct DATABASE_URL env var
  5. Verify: curl returns 200
"""
import os, time, random, json, sys
from datetime import datetime, timezone
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# *** THE BUG: wrong default host — this is what students find ***
DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://wrong-host:5432/mydb')

# Prometheus metrics
req_count    = Counter('http_requests_total',        'HTTP requests',   ['method', 'path', 'status'])
req_duration = Histogram('http_duration_seconds',    'Request duration', ['path'],
                         buckets=[.05, .1, .25, .5, 1, 2.5, 5])


def log(level, message, **kwargs):
    """JSON structured logging — standard in production systems."""
    entry = {
        "ts":    datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        "level": level,
        "msg":   message,
        **kwargs,
    }
    print(json.dumps(entry), flush=True)


@app.before_request
def startup_log():
    pass


@app.route('/health')
def health():
    log("info", "health check", status="ok")
    req_count.labels('GET', '/health', '200').inc()
    return jsonify({"status": "ok", "database_url": DATABASE_URL})


@app.route('/api/users')
def get_users():
    start = time.time()

    # Simulate a DB connection timeout when the URL is wrong
    if 'wrong-host' in DATABASE_URL:
        time.sleep(random.uniform(0.8, 1.5))   # simulates TCP timeout
        log("error", "database connection failed",
            database_url=DATABASE_URL,
            error="connection refused — host not reachable",
            retry_attempts=3,
            duration_ms=round((time.time() - start) * 1000))
        req_count.labels('GET', '/api/users', '503').inc()
        req_duration.labels('/api/users').observe(time.time() - start)
        return jsonify({"error": "Service temporarily unavailable",
                        "hint": "Check DATABASE_URL configuration"}), 503

    # Happy path — after the fix
    time.sleep(random.uniform(0.05, 0.15))
    log("info", "user query ok", user_count=42, duration_ms=round((time.time() - start) * 1000))
    req_count.labels('GET', '/api/users', '200').inc()
    req_duration.labels('/api/users').observe(time.time() - start)
    return jsonify({"users": [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]})


@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}


if __name__ == '__main__':
    log("info", "app starting", database_url=DATABASE_URL, port=5001)
    app.run(host='0.0.0.0', port=5001, debug=False)
