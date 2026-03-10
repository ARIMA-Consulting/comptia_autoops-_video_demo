#!/bin/bash
# CompTIA AutoOps+ | Troubleshooting Live Systems
# Exam Objective 1.4 — Troubleshoot code lifecycle issues
# Exam Objective 2.4 — Troubleshoot system configuration issues
# Exam Objective 4.2 — Feedback loop, MTTR
#
# What this demo shows:
#   A real Flask app is running but broken (wrong DATABASE_URL config).
#   You work through the SRE troubleshooting sequence using real tools:
#     docker logs  → docker stats  → curl  → Prometheus metrics
#   Then you find the misconfiguration, fix it, and verify recovery.
#
# REQUIRES: Docker


DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===========================================================================
# BLOCK 0 — Setup: start the broken app
#
# The app starts fine but /api/users will fail with 503 errors.
# This is intentional — the DATABASE_URL env var points to a wrong host.
# Students will discover this systematically through the blocks below.
# ===========================================================================

docker compose -f "$DEMO_DIR/docker-compose.yml" down 2>/dev/null || true

echo "Starting broken app + Prometheus..."
docker compose -f "$DEMO_DIR/docker-compose.yml" up -d --build

echo "Waiting for app to start..."
until curl -sf http://localhost:5001/health >/dev/null 2>&1; do sleep 2; done
echo "App is running."
echo ""
echo "  Broken app   : http://localhost:5001"
echo "  Prometheus   : http://localhost:9092"
echo ""

# Generate some error traffic so logs are populated before recording
echo "Generating pre-demo traffic (builds up log entries)..."
for i in $(seq 1 10); do
  curl -s http://localhost:5001/api/users > /dev/null
  curl -s http://localhost:5001/health > /dev/null
done
echo "Ready. Begin recording."


# ===========================================================================
# BLOCK 1 — Is it running? Container and resource checks
#
# Step 1 in every troubleshooting session: confirm what is alive.
# docker ps   = what containers are running?
# docker stats = is it consuming unexpected memory or CPU?
# ===========================================================================

echo ""
echo "--- BLOCK 1: container status and resource usage ---"
echo ""
echo "[docker ps] Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "[docker stats] Current resource usage (one snapshot):"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo ""
echo "[health check] Is the app responding?"
curl -s http://localhost:5001/health | python3 -m json.tool


# ===========================================================================
# BLOCK 2 — What do the logs say? (almost always where the answer is)
#
# In containerized apps, structured JSON logs are the standard.
# Look for the FIRST error — everything after it is the cascade.
# docker logs --follow lets you watch in real-time.
# ===========================================================================

echo ""
echo "--- BLOCK 2: live log analysis ---"
echo ""
APP_CONTAINER="23-troubleshooting-live-systems-app-1"

echo "[docker logs] Last 20 log lines (mixed stdout + stderr, as you'd see in production):"
docker logs "$APP_CONTAINER" --tail 20 2>&1

echo ""
echo "[docker logs] Just the JSON error entries:"
docker logs "$APP_CONTAINER" 2>&1 \
  | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    try:
        entry = json.loads(line)
        if entry.get('level') == 'error':
            print(f\"  [{entry.get('ts','')}] ERROR: {entry.get('msg','')} — {entry.get('error','')}\")
    except:
        pass
" | tail -5


# ===========================================================================
# BLOCK 3 — Reproduce the error
#
# Call every endpoint yourself.  /health works, /api/users does not.
# The HTTP status code and response body tell you what is broken.
# ===========================================================================

echo ""
echo "--- BLOCK 3: reproduce the error with curl ---"
echo ""
echo "[curl] Health check (should work):"
curl -s http://localhost:5001/health | python3 -m json.tool

echo ""
echo "[curl] Users endpoint (this is the broken one):"
curl -s -w "\nHTTP status: %{http_code}\n" http://localhost:5001/api/users


# ===========================================================================
# BLOCK 4 — Find the root cause
#
# The app returns 503 and the logs say "wrong-host not reachable."
# The next question: WHY is it using wrong-host?
# Answer: the DATABASE_URL environment variable is misconfigured.
# docker inspect shows every env var the container was started with.
# ===========================================================================

echo ""
echo "--- BLOCK 4: find the misconfiguration ---"
echo ""
echo "[docker inspect] Environment variables for the app container:"
docker inspect 23-troubleshooting-live-systems-app-1 \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep -i database

echo ""
echo "Found it — DATABASE_URL is pointing to 'wrong-host'"
echo "It should be the actual database host (e.g. 'db-host')"
echo ""
echo "This is one of the most common production issues:"
echo "  Code is fine. Infrastructure is fine. Config is wrong."


# ===========================================================================
# BLOCK 5 — Check Prometheus: visualize the error rate
#
# While you were troubleshooting, Prometheus was scraping metrics.
# Now you can SEE the error rate spike — this is what SREs watch.
# Open the Prometheus UI and query for the error pattern.
# ===========================================================================

echo ""
echo "--- BLOCK 5: Prometheus metrics showing the error spike ---"
echo ""
echo "Querying error rate from Prometheus..."
sleep 3
curl -sf "http://localhost:9092/api/v1/query?query=rate(http_requests_total%7Bstatus%3D%22503%22%7D%5B2m%5D)" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
results = d.get('data', {}).get('result', [])
if results:
    for r in results:
        val = float(r['value'][1])
        print(f'  503 error rate: {val:.3f} req/sec = ~{val*60:.1f} errors/min on /api/users')
else:
    print('  (no results yet — Prometheus needs ~15s of scrape data)')
" 2>/dev/null || echo "  (Prometheus starting — open http://localhost:9092 in browser)"

echo ""
echo "Open your browser: http://localhost:9092"
echo "Paste this query:  rate(http_requests_total{status=\"503\"}[2m])"
echo "Switch to Graph tab. You'll see the 503 rate spike — this is what pages on-call."


# ===========================================================================
# BLOCK 6 — Fix it, restart, verify
#
# Change the DATABASE_URL to the correct value and restart the container.
# Prometheus will show the error rate drop to zero after the fix.
# ===========================================================================

echo ""
echo "--- BLOCK 6: fix the configuration and verify recovery ---"
echo ""
echo "Fixing DATABASE_URL: wrong-host → db-host"
echo ""
echo "The fix is one env var change in docker-compose.yml:"
echo "  Before:  DATABASE_URL=postgresql://wrong-host:5432/mydb"
echo "  After:   DATABASE_URL=postgresql://db-host:5432/mydb"
echo ""

# Run a fixed container on port 5002 to demonstrate the fix
docker rm -f app-fixed 2>/dev/null || true
docker run -d \
  --name app-fixed \
  -p 5002:5001 \
  -e DATABASE_URL=postgresql://db-host:5432/mydb \
  23-troubleshooting-live-systems-app:latest

sleep 3
echo "Hitting the FIXED app (port 5002 — correct DATABASE_URL):"
curl -s -w "\nHTTP status: %{http_code}\n" http://localhost:5002/api/users

echo ""
echo "503 → 200. The fix worked. One environment variable was the entire incident."
echo ""
echo "In production: update the secret in Vault or SSM, redeploy."
echo "Watch in Prometheus: the 503 rate graph flattens to 0 after the restart."
docker rm -f app-fixed 2>/dev/null || true


# ===========================================================================
# BLOCK 7 — Incident summary
#
# Every incident should end with a written summary.
# This becomes the post-mortem and feeds the feedback loop.
# ===========================================================================

echo ""
echo "--- BLOCK 7: incident summary (post-mortem template) ---"

cat << 'EOF'
=== Incident Summary ===

Incident ID : INC-2024-001
Duration    : ~15 minutes (12:01 – 12:16)
Severity    : P1 (users unable to load /api/users)
Impact      : 100% of user-facing requests returning 503

Root Cause:
  DATABASE_URL environment variable was set to 'wrong-host' in the
  container configuration. This caused all DB connection attempts to fail
  with "connection refused" after a 1-second timeout.

Timeline:
  12:01  First 503 errors appear in logs
  12:03  Prometheus alert fires (error rate > 50%)
  12:05  On-call engineer paged via Alertmanager → PagerDuty
  12:09  Root cause identified (wrong DATABASE_URL in docker-compose.yml)
  12:14  Config corrected, container restarted
  12:16  Error rate returns to 0%, incident resolved

MTTR: 15 minutes

Action Items:
  1. Add config validation to deployment pipeline (prevents bad env vars)
  2. Add DATABASE_URL health check to /health endpoint
  3. Update runbook: check env vars early in troubleshooting checklist

Exam Tip: CompTIA loves "you see this error in the logs, what do you check next?"
          Always: logs → config → network → recent changes
EOF

echo ""
echo "Cleanup: docker compose -f $DEMO_DIR/docker-compose.yml down"
