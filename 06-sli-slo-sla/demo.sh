#!/bin/bash
# CompTIA AutoOps+ | Understanding SLIs, SLOs, and SLAs
# Exam Objective 4.2 — SLOs, SLAs, uptime, MTBF, feedback loop


# ===========================================================================
# BLOCK 0 — Setup: create the demo files
#
# SLI = Service Level Indicator  — a measurement (e.g., uptime %)
# SLO = Service Level Objective  — the internal target (e.g., >= 99.9%)
# SLA = Service Level Agreement  — the contractual commitment to customers
#
# The chain: you MEASURE an SLI, you SET an SLO, you PROMISE an SLA.
# ===========================================================================

rm -rf slo-demo
mkdir slo-demo
cd slo-demo

# Simulated request log: each line is one request with a status code
cat > requests.log << 'EOF'
2024-03-01 00:01:00 GET /api/health 200
2024-03-01 00:02:00 GET /api/users 200
2024-03-01 00:03:00 GET /api/data  500
2024-03-01 00:04:00 GET /api/data  500
2024-03-01 00:05:00 GET /api/users 200
2024-03-01 00:06:00 GET /api/health 200
2024-03-01 00:07:00 GET /api/data  200
2024-03-01 00:08:00 GET /api/users 200
2024-03-01 00:09:00 GET /api/health 503
2024-03-01 00:10:00 GET /api/data  200
EOF

cat > slo_check.py << 'EOF'
# SLI, SLO, SLA calculator

SLO_TARGET = 99.0   # internal goal: 99% uptime
SLA_PROMISE = 95.0  # contractual promise to customers

with open("requests.log") as f:
    lines = f.readlines()

total    = len(lines)
success  = sum(1 for l in lines if " 200" in l)
failures = total - success

# SLI: what we actually measured
sli = (success / total) * 100

print(f"Total requests : {total}")
print(f"Successful     : {success}  (2xx)")
print(f"Failed         : {failures}  (5xx / 503)")
print()
print(f"SLI (measured uptime) : {sli:.1f}%")
print(f"SLO (internal target) : {SLO_TARGET}%")
print(f"SLA (customer promise): {SLA_PROMISE}%")
print()

if sli >= SLO_TARGET:
    print("✓ SLO MET — within internal goal")
else:
    print("✗ SLO MISSED — investigate and remediate")

if sli >= SLA_PROMISE:
    print("✓ SLA MET — no customer credit triggered")
else:
    print("✗ SLA BREACHED — customer credits may apply")
EOF

echo "Files created."


# ===========================================================================
# BLOCK 1 — Look at the raw log and understand the SLI data source
#
# An SLI is only as good as what you measure.
# Here we are measuring HTTP success rate from a request log.
# Other common SLIs: latency (p99 response time), error rate, throughput.
# ===========================================================================

cat requests.log


# ===========================================================================
# BLOCK 2 — Run the SLO check and read the output
#
# Watch how the SLI compares against both the SLO and the SLA.
# The SLO is tighter than the SLA — you want to catch problems internally
# before they hit the customer-facing threshold.
# ===========================================================================

python3 slo_check.py


# ===========================================================================
# BLOCK 3 — Change the log to show an SLA breach and re-run
#
# We add more failures so the SLI drops below even the SLA threshold.
# This is what the feedback loop catches: SLI drops → alert fires →
# team investigates → root cause fixed → SLI recovers.
# ===========================================================================

cat >> requests.log << 'EOF'
2024-03-01 00:11:00 GET /api/health 503
2024-03-01 00:12:00 GET /api/users  503
2024-03-01 00:13:00 GET /api/health 503
2024-03-01 00:14:00 GET /api/data   503
2024-03-01 00:15:00 GET /api/health 503
EOF

python3 slo_check.py
