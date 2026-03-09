#!/bin/bash
# CompTIA AutoOps+ | The SRE Toolchain
# Exam Objective 4.2 — SLOs, SLAs, uptime, MTBF, MTTR, feedback loop


# ===========================================================================
# BLOCK 0 — Setup
#
# SRE (Site Reliability Engineering) applies software engineering to operations.
# The SRE toolchain is how they measure and enforce reliability.
#
# Key metrics:
#   Uptime / Availability = (total time - downtime) / total time × 100%
#   MTBF  = Mean Time Between Failures  (how often does it break?)
#   MTTR  = Mean Time To Repair         (how fast can you fix it?)
#   Error budget = 100% - SLO target    (how much failure is "allowed"?)
# ===========================================================================

rm -rf sre-toolchain-demo
mkdir sre-toolchain-demo
cd sre-toolchain-demo
echo "Setup done."


# ===========================================================================
# BLOCK 1 — Calculate uptime and error budget from incident data
# ===========================================================================

cat > sre_calculator.py << 'EOF'
from datetime import timedelta

# ---- Input: incident history for the past 30 days ----
WINDOW_HOURS = 30 * 24   # 720 hours in a 30-day month

# Each tuple is (start_hour, duration_minutes) of an outage
incidents = [
    {"start_hour": 48,  "duration_min": 12,  "cause": "database OOM"},
    {"start_hour": 156, "duration_min": 3,   "cause": "bad deploy — auto-rollback"},
    {"start_hour": 312, "duration_min": 45,  "cause": "regional network outage"},
    {"start_hour": 589, "duration_min": 8,   "cause": "certificate expiry"},
]

SLO_TARGET = 99.9   # our internal target: 99.9% uptime

# ---- Calculations ----
total_minutes   = WINDOW_HOURS * 60
downtime_min    = sum(i["duration_min"] for i in incidents)
uptime_min      = total_minutes - downtime_min
availability    = (uptime_min / total_minutes) * 100
error_budget_min = total_minutes * ((100 - SLO_TARGET) / 100)
budget_remaining = error_budget_min - downtime_min
budget_pct_used  = (downtime_min / error_budget_min) * 100

# MTBF and MTTR
mtbf_hours = WINDOW_HOURS / len(incidents)
mttr_min   = downtime_min / len(incidents)

print("=== SRE Reliability Report (30-day window) ===")
print()
print(f"  Total window      : {total_minutes:,} minutes ({WINDOW_HOURS} hours)")
print(f"  Downtime          : {downtime_min} minutes")
print(f"  Availability      : {availability:.4f}%")
print(f"  SLO target        : {SLO_TARGET}%")
print()
print(f"  Error budget      : {error_budget_min:.1f} min/month at {SLO_TARGET}% SLO")
print(f"  Budget used       : {downtime_min} min ({budget_pct_used:.1f}%)")
print(f"  Budget remaining  : {max(budget_remaining, 0):.1f} min")
print()
print(f"  MTBF              : {mtbf_hours:.1f} hours between failures")
print(f"  MTTR              : {mttr_min:.1f} minutes average repair time")
print()

if availability >= SLO_TARGET:
    print(f"  ✓ SLO MET — {availability:.4f}% >= {SLO_TARGET}%")
else:
    print(f"  ✗ SLO MISSED — {availability:.4f}% < {SLO_TARGET}%")

if budget_remaining > 0:
    print(f"  ✓ Error budget has {budget_remaining:.1f} minutes remaining this month")
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
# BLOCK 2 — The error budget concept
#
# Error budget is what makes SRE different from just "keep it up."
# It gives engineers PERMISSION to take risks (deploy features, do maintenance)
# up to the point where the SLO would be violated.
# ===========================================================================

cat > error_budget.py << 'EOF'
SLO      = 99.9      # 99.9% uptime
WINDOW_D = 30        # days

total_min       = WINDOW_D * 24 * 60
budget_min      = total_min * ((100 - SLO) / 100)
budget_sec      = budget_min * 60

print(f"=== Error Budget at {SLO}% SLO over {WINDOW_D} days ===")
print()
print(f"  Budget = {budget_min:.1f} minutes = {budget_sec:.0f} seconds per month")
print()
print("  What eats into this budget:")
print("   - Every minute of unplanned downtime")
print("   - Failed deployments that cause errors (even brief ones)")
print("   - Dependency outages (if your SLA covers them)")
print()
print("  When the budget runs out:")
print("   - Stop deploying new features")
print("   - Focus 100% on reliability work")
print("   - Resume deployments next month when budget resets")
print()
print("  This is the FEEDBACK LOOP:")
print("   SLI measured → compared to SLO → budget consumed → team adjusts work")
EOF

echo ""
echo "--- BLOCK 2: error budget explained ---"
python3 error_budget.py


# ===========================================================================
# BLOCK 3 — On-call runbook structure
#
# SREs use runbooks to standardize incident response.
# A runbook is a script for humans: if X happens, do Y.
# ===========================================================================

cat > runbook_example.md << 'EOF'
# Runbook: Database Connection Failures

**Alert:** `db_connection_errors > 10 per minute for 5 minutes`
**Severity:** P1 (production impacting)
**Owner:** Platform team

## Immediate steps (< 5 minutes)
1. Check `kubectl get pods -n database` — are DB pods running?
2. Check `kubectl logs <db-pod>` — any OOM or crash messages?
3. Check DB CPU/memory metrics in Datadog dashboard

## If pods are healthy but errors continue
4. Check connection pool: `SELECT count(*) FROM pg_stat_activity`
5. If pool exhausted: `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle'`

## Escalation
- If not resolved in 15 minutes: page database team
- If resolved: update incident channel, schedule post-mortem within 48h

## Rollback trigger
- If errors exceed 50/min: initiate rollback to previous version
EOF

echo ""
echo "--- BLOCK 3: runbook structure ---"
cat runbook_example.md
