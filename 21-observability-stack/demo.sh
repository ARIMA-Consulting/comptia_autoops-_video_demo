#!/bin/bash
# CompTIA AutoOps+ | Observability Stack Overview
# Exam Objective 4.2 — Uptime, SLOs, SLAs, feedback loop, MTBF
#
# Shows a REAL observability stack running locally via Docker:
#   app       → emits Prometheus metrics on :8000/metrics
#   Prometheus → scrapes the app every 5s, stores time-series data  (:9090)
#   Grafana    → queries Prometheus and visualizes it               (:3000)
#
# REQUIRES: Docker, internet (pulls images on first run, cached after)


# ===========================================================================
# BLOCK 0 — Setup: build the full stack (run this before recording)
#
# docker compose up -d : starts all three services in the background
# ===========================================================================

rm -rf obs-demo
mkdir -p obs-demo/app obs-demo/grafana/provisioning/datasources
cd obs-demo

# --- The metrics app ---
cat > app/app.py << 'EOF'
from prometheus_client import start_http_server, Counter, Gauge, Histogram
import time, random

# Three metric types:
#   Counter   = always increases (requests, errors)
#   Gauge     = goes up and down (active users, queue length)
#   Histogram = tracks distribution (latency buckets)
REQUEST_COUNT = Counter('app_requests_total', 'Total HTTP requests', ['endpoint', 'status'])
ACTIVE_USERS  = Gauge('app_active_users', 'Currently active users')
LATENCY       = Histogram('app_request_latency_seconds', 'Request latency in seconds',
                          buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0])

start_http_server(8000)
print("Metrics server running on :8000/metrics", flush=True)

while True:
    endpoint = random.choice(['/api/users', '/api/posts', '/health'])
    status   = '500' if random.random() < 0.03 else '200'   # ~3% error rate
    latency  = abs(random.gauss(0.1, 0.03))

    REQUEST_COUNT.labels(endpoint=endpoint, status=status).inc()
    ACTIVE_USERS.set(random.randint(10, 100))
    LATENCY.observe(latency)
    time.sleep(0.2)
EOF

cat > app/requirements.txt << 'EOF'
prometheus-client
EOF

cat > app/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
EOF

# --- Prometheus configuration: scrape the app every 5 seconds ---
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['app:8000']
EOF

# --- Grafana: auto-configure Prometheus as the default data source ---
cat > grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
    access: proxy
EOF

# --- Docker Compose: wires everything together ---
cat > docker-compose.yml << 'EOF'
services:
  app:
    build: ./app
    ports:
      - "8765:8000"

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    depends_on:
      - app

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
    depends_on:
      - prometheus
EOF

echo "Starting observability stack..."
docker compose up -d --build

echo "Waiting for services to be ready..."
for i in $(seq 1 30); do
    if curl -s http://localhost:8765/metrics > /dev/null 2>&1 && \
       curl -s http://localhost:9090/-/ready > /dev/null 2>&1 && \
       curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "All services ready."
        break
    fi
    sleep 2
done

echo ""
echo "=== Stack is running ==="
docker compose ps


# ===========================================================================
# BLOCK 1 — The raw metrics format Prometheus reads
#
# Prometheus uses a plain-text format called the exposition format.
# Every metric is a key-value pair with optional labels.
# curl the /metrics endpoint to see exactly what Prometheus scrapes.
# ===========================================================================

echo ""
echo "--- BLOCK 1: raw metrics from the app ---"
curl -s http://localhost:8765/metrics | grep "^app_"


# ===========================================================================
# BLOCK 2 — Query Prometheus in the terminal, then open the UI
#
# Prometheus has a built-in HTTP API — you can query it with curl.
# PromQL (Prometheus Query Language) is how you ask questions about your data.
# ===========================================================================

echo ""
echo "--- BLOCK 2: query Prometheus API ---"

# Give Prometheus time to complete at least one scrape cycle (5s interval)
sleep 6

echo "Total requests by endpoint (via Prometheus HTTP API):"
curl -s "http://localhost:9090/api/v1/query?query=app_requests_total" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
results = data.get('data', {}).get('result', [])
if not results:
    print('  (no data yet — Prometheus is still warming up)')
for r in results:
    print(f\"  {r['metric'].get('endpoint','?')}  status={r['metric'].get('status','?')}  count={r['value'][1]}\")
"

echo ""
echo "Open Prometheus UI: http://localhost:9090"
echo "  Try query: app_requests_total"
echo "  Go to Status → Targets to confirm the app is being scraped (state: UP)"


# ===========================================================================
# BLOCK 3 — Grafana: visualize the metrics
#
# Grafana connects to Prometheus and lets you build dashboards.
# The Prometheus datasource is already configured — just open and explore.
# ===========================================================================

echo ""
echo "--- BLOCK 3: open Grafana ---"
echo ""
echo "  URL      : http://localhost:3000"
echo "  Username : admin"
echo "  Password : admin"
echo ""
echo "Steps to show students:"
echo "  1. Login → you land on the Home dashboard"
echo "  2. Left sidebar → Explore"
echo "  3. Datasource dropdown → select Prometheus (already configured)"
echo "  4. Enter query: app_requests_total"
echo "  5. Click Run Query — see the time-series graph"
echo "  6. Change query to: rate(app_requests_total[1m])  (requests per second)"
echo "  7. Change query to: app_active_users              (gauge going up and down)"
echo ""
echo "  To build a dashboard:"
echo "  Dashboards → New → Add visualization → same queries above"


# ===========================================================================
# BLOCK 4 — The three pillars: logs, metrics, traces
#
# Prometheus + Grafana cover METRICS.
# The other two pillars in a full stack:
#   Logs   : Loki (Grafana's log aggregator) or ELK/Splunk/Datadog
#   Traces : Tempo/Jaeger — follow a single request across multiple services
# ===========================================================================

echo ""
echo "--- BLOCK 4: structured logging (the logs pillar) ---"

cat > /tmp/obs_log_demo.py << 'EOF'
import json
from datetime import datetime, timezone

def log(level, message, **ctx):
    print(json.dumps({"ts": datetime.now(timezone.utc).isoformat(),
                      "level": level, "msg": message, **ctx}))

log("INFO",  "Request received", method="GET", path="/api/users", request_id="r-001")
log("INFO",  "DB query",         table="users", rows=42, duration_ms=12)
log("INFO",  "Response sent",    status=200, duration_ms=18, request_id="r-001")
log("ERROR", "DB timeout",       duration_ms=5001, error="connection refused", request_id="r-002")
EOF

python3 /tmp/obs_log_demo.py

echo ""
echo "Structured JSON logs can be ingested by Loki, Datadog, Splunk, or CloudWatch."
echo "Grafana can visualize both Prometheus metrics and Loki logs on the same dashboard."


# ===========================================================================
# BLOCK 5 — Cleanup
# ===========================================================================

echo ""
echo "--- BLOCK 5: stop the stack ---"
docker compose down
echo "Stack stopped."
