#!/bin/bash
# CompTIA AutoOps+ | The SRE Toolchain
# Exam Objective 4.2 — SLOs, SLAs, uptime, MTBF, MTTR, feedback loop
#
# What this demo shows:
#   1. Python SRE calculator — quantify uptime, MTBF, MTTR, error budget
#   2. Error budget concept — the feedback loop that drives SRE decisions
#   3. Prometheus alert rules — automated SLO breach detection
#   4. Alertmanager — the routing layer between Prometheus and PagerDuty/Slack
#   5. Runbook structure — what on-call engineers actually follow
#
# REQUIRES: Docker (already used in demos 08, 21)
# Students: docker pull prom/alertmanager  (one-time, ~50MB)


DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===========================================================================
# BLOCK 0 — Setup: start the SRE observability stack
#
# The sre-app emits Prometheus metrics for a service that is BELOW its SLO.
# After ~1 minute, Prometheus will fire the SLOBreached alert and Alertmanager
# will show it active and ready to route to PagerDuty/Slack.
# ===========================================================================

docker compose -f "$DEMO_DIR/docker-compose.yml" down 2>/dev/null || true
docker rm -f sre-toolchain-sre-app-1 sre-toolchain-prometheus-1 sre-toolchain-alertmanager-1 2>/dev/null || true

rm -rf sre-toolchain-demo
mkdir sre-toolchain-demo
cd sre-toolchain-demo

echo "Starting SRE stack (Prometheus + Alertmanager + metrics app)..."
docker compose -f "$DEMO_DIR/docker-compose.yml" up -d --build

echo "Waiting for services..."
until curl -sf http://localhost:9090/-/healthy >/dev/null 2>&1; do sleep 2; done
until curl -sf http://localhost:9093/-/healthy >/dev/null 2>&1; do sleep 2; done
echo "Stack is ready."
echo ""
echo "  Metrics (raw)  : http://localhost:8766/metrics"
echo "  Prometheus     : http://localhost:9090"
echo "  Alertmanager   : http://localhost:9093"
echo ""
echo "NOTE: The SLOBreached and ErrorBudgetExhausted alerts will fire after ~1 minute."
echo "Begin recording."


# ===========================================================================
# BLOCK 1 — Calculate uptime, MTBF, MTTR from real incident data
#
# This is the math every SRE does. You need to know these definitions cold
# for the CompTIA exam. Uptime alone is not enough — you need MTBF and MTTR
# to understand the failure pattern and repair capability of your team.
# ===========================================================================

cat > sre_calculator.py << 'EOF'
from datetime import timedelta

# ---- 30-day incident history ----
WINDOW_HOURS = 30 * 24   # 720 hours

incidents = [
    {"start_hour": 48,  "duration_min": 12,  "cause": "database OOM"},
    {"start_hour": 156, "duration_min": 3,   "cause": "bad deploy — auto-rollback"},
    {"start_hour": 312, "duration_min": 45,  "cause": "regional network outage"},
    {"start_hour": 589, "duration_min": 8,   "cause": "certificate expiry"},
]

SLO_TARGET = 99.9   # 99.9% uptime SLO

total_min        = WINDOW_HOURS * 60
downtime_min     = sum(i["duration_min"] for i in incidents)
uptime_min       = total_min - downtime_min
availability     = (uptime_min / total_min) * 100
error_budget_min = total_min * ((100 - SLO_TARGET) / 100)
budget_remaining = error_budget_min - downtime_min
budget_pct_used  = (downtime_min / error_budget_min) * 100
mtbf_hours       = WINDOW_HOURS / len(incidents)
mttr_min         = downtime_min / len(incidents)

print("=== SRE Reliability Report (30-day window) ===")
print()
print(f"  Availability      : {availability:.4f}%")
print(f"  SLO target        : {SLO_TARGET}%")
print()
print(f"  Error budget      : {error_budget_min:.1f} min/month  (0.1% of 720 hours)")
print(f"  Budget used       : {downtime_min} min ({budget_pct_used:.1f}%)")
print(f"  Budget remaining  : {max(budget_remaining, 0):.1f} min")
print()
print(f"  MTBF              : {mtbf_hours:.1f} hours  (mean time BETWEEN failures)")
print(f"  MTTR              : {mttr_min:.1f} minutes (mean time TO REPAIR)")
print()

if availability >= SLO_TARGET:
    print(f"  ✓ SLO MET — {availability:.4f}% >= {SLO_TARGET}%")
else:
    print(f"  ✗ SLO MISSED — {availability:.4f}% < {SLO_TARGET}%")

if budget_remaining > 0:
    print(f"  ✓ Error budget: {budget_remaining:.1f} minutes remaining")
else:
    print(f"  ✗ Error budget EXHAUSTED — freeze non-critical deployments")

print()
print("Incident breakdown:")
for i, inc in enumerate(incidents, 1):
    print(f"  {i}. Hour {inc['start_hour']:3d} | {inc['duration_min']:3d} min | {inc['cause']}")
EOF

echo ""
echo "--- BLOCK 1: SRE reliability report ---"
python3 sre_calculator.py


# ===========================================================================
# BLOCK 2 — Error budget: the SRE feedback loop
#
# Error budget is what separates SRE from traditional ops.
# It's not "never go down" — it's "you have X minutes of failure allowed."
# When the budget is consumed, you stop shipping features and fix reliability.
# This feedback loop is what the CompTIA exam tests on for Exam Obj 4.2.
# ===========================================================================

cat > error_budget.py << 'EOF'
SLO      = 99.9
WINDOW_D = 30

total_min   = WINDOW_D * 24 * 60
budget_min  = total_min * ((100 - SLO) / 100)
budget_sec  = budget_min * 60

print(f"=== Error Budget at {SLO}% SLO over {WINDOW_D} days ===")
print()
print(f"  Allowed downtime  : {budget_min:.1f} minutes = {budget_sec:.0f} seconds / month")
print()
print("  What consumes the budget:")
print("    - Every minute of unplanned downtime")
print("    - Failed deploys that cause errors (even brief ones)")
print("    - Dependency outages if your SLA covers them")
print()
print("  When budget hits 0:")
print("    STOP  → no new feature deployments")
print("    FOCUS → 100% on reliability improvements")
print("    RESET → budget renews next calendar month")
print()
print("  The feedback loop (Exam Obj 4.2):")
print("    SLI measured → compared to SLO → budget consumed → team adjusts priorities")
print("    This is what keeps engineering teams honest about reliability.")
EOF

echo ""
echo "--- BLOCK 2: error budget explained ---"
python3 error_budget.py


# ===========================================================================
# BLOCK 3 — Prometheus: automated SLO monitoring
#
# The alert rules in alerts.yml define what triggers on-call.
# Prometheus evaluates these every 5 seconds against live metrics.
# The sre-app is emitting 99.84% uptime — the SLOBreached alert will fire.
# ===========================================================================

echo ""
echo "--- BLOCK 3: Prometheus SLO alert rules ---"
echo ""
echo "Alert rules (alerts.yml):"
cat "$DEMO_DIR/alerts.yml"

echo ""
echo "Query SLI metrics live:"
curl -s "http://localhost:9090/api/v1/query?query=service_uptime_pct" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d.get('data', {}).get('result', [])
if r:
    print(f\"  service_uptime_pct = {float(r[0]['value'][1]):.2f}%  (SLO target: 99.9%)\")
else:
    print('  (metrics not scraped yet — wait a few seconds and retry)')
"

echo ""
echo "Open your browser: http://localhost:9090/alerts"
echo "You will see SLOBreached and ErrorBudgetExhausted in FIRING state."
echo "Prometheus is running the exact same alert evaluation as production systems."


# ===========================================================================
# BLOCK 4 — Alertmanager: the on-call routing layer
#
# Alertmanager receives alerts from Prometheus and routes them.
# This is where PagerDuty, OpsGenie, Rootly, and Slack connect.
# In production: critical alerts page the on-call engineer immediately.
# In the exam: know that Alertmanager is the routing bridge between
#              Prometheus metrics and your incident management platform.
# ===========================================================================

echo ""
echo "--- BLOCK 4: Alertmanager — the PagerDuty integration point ---"
echo ""
echo "Routing config (alertmanager.yml):"
cat "$DEMO_DIR/alertmanager.yml"

echo ""
echo "Check active alerts via Alertmanager API:"
sleep 2
curl -s http://localhost:9093/api/v2/alerts | python3 -c "
import sys, json
alerts = json.load(sys.stdin)
if alerts:
    for a in alerts:
        labels = a.get('labels', {})
        ann    = a.get('annotations', {})
        status = a.get('status', {}).get('state', 'unknown')
        print(f\"  [{status.upper()}] {labels.get('alertname')} — {ann.get('summary', '')}\")
else:
    print('  (no active alerts yet — wait ~1 minute for SLO rules to fire)')
"

echo ""
echo "Open your browser: http://localhost:9093"
echo "You will see the active alerts and the routing tree."
echo ""
echo "In production, 'on-call-pager' receiver config would be:"
echo "  pagerduty_configs:"
echo "    - service_key: '<your-pagerduty-key>'"
echo "  opsgenie_configs:"
echo "    - api_key: '<your-key>'"
echo "    (Rootly and other tools also use this webhook/API pattern)"


# ===========================================================================
# BLOCK 5 — Runbook: what on-call engineers actually do when paged
#
# The alert fires → Alertmanager pages on-call → engineer opens runbook.
# This is the documented playbook that turns an alert into a fix.
# ===========================================================================

cat > runbook_db_failures.md << 'EOF'
# Runbook: SLO Breach — High Error Rate

**Alert:** `SLOBreached` — uptime below 99.9% for > 1 minute
**Severity:** P1 (production impacting)
**Owner:** Platform team

## Immediate steps (first 5 minutes)
1. `kubectl get pods -n production` — are all pods healthy?
2. `kubectl logs <failing-pod> --tail=50` — look for the FIRST error
3. Check Prometheus: `rate(http_requests_total{status=~"5.."}[5m])`
4. Check Grafana error rate dashboard — is error rate > 1%?

## Common causes and fixes
| Symptom                | Likely cause          | Fix                              |
|------------------------|-----------------------|----------------------------------|
| DB connection errors   | DB pod OOM or down    | Restart DB, check memory limits  |
| 502/503 errors          | Deployment rolling    | Wait 2min, check rollout status  |
| Auth failures           | Expired certificate   | Rotate cert, restart auth service|

## Escalation
- Not resolved in 15 min: page database team lead
- Not resolved in 30 min: page engineering manager

## After resolution
- Document in incident channel
- Schedule post-mortem within 48 hours
- Add/update alert runbook with what you learned
EOF

echo ""
echo "--- BLOCK 5: on-call runbook ---"
cat runbook_db_failures.md

echo ""
echo "Cleanup: docker compose -f $DEMO_DIR/docker-compose.yml down"
