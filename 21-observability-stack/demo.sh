#!/bin/bash
# CompTIA AutoOps+ | Observability Stack Overview
# Exam Objective 4.2 — Uptime, SLOs, SLAs, feedback loop, MTBF
# Exam Objective 3.2 — AI-based log analysis


# ===========================================================================
# BLOCK 0 — Setup
#
# Observability = knowing what your system is doing, without having to guess.
# The three pillars:
#   Logs    : timestamped records of what happened (text events)
#   Metrics : numerical measurements over time (CPU %, request count, latency)
#   Traces  : follow a single request through multiple services
#
# You can have a working system without observability.
# You just won't know it's broken until a customer tells you.
# ===========================================================================

rm -rf observability-demo
mkdir observability-demo
cd observability-demo
python3 -m venv venv && source venv/bin/activate
pip install requests -q
echo "Setup done."


# ===========================================================================
# BLOCK 1 — Structured logging
#
# Plain text logs are hard to search. Structured logs (JSON) can be
# queried by any log aggregator (Splunk, Datadog, CloudWatch, ELK stack).
# ===========================================================================

cat > logger.py << 'EOF'
import json, time
from datetime import datetime, timezone

def log(level: str, message: str, **context):
    """Emit a structured JSON log line."""
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level":     level,
        "message":   message,
        **context,
    }
    print(json.dumps(entry))

# Simulate a request being processed
log("INFO",  "Request received",  method="GET", path="/api/users", request_id="req-001")
log("INFO",  "Database query",    table="users", rows_returned=42, duration_ms=12)
log("INFO",  "Response sent",     status=200, duration_ms=18, request_id="req-001")

# Simulate an error
log("ERROR", "Database timeout",  table="orders", duration_ms=5001,
             error="connection timed out", request_id="req-002")
log("WARN",  "Retry attempt",     attempt=1, max_retries=3, request_id="req-002")
EOF

echo ""
echo "--- BLOCK 1: structured logs ---"
python3 logger.py


# ===========================================================================
# BLOCK 2 — Metrics collection
#
# Metrics are numbers sampled over time. You alert on metrics thresholds.
# Common metric types: counter (always goes up), gauge (up and down), histogram
# ===========================================================================

cat > metrics.py << 'EOF'
import time, statistics, random

class SimpleMetrics:
    def __init__(self):
        self.request_count    = 0
        self.error_count      = 0
        self.response_times   = []

    def record_request(self, duration_ms: float, success: bool):
        self.request_count += 1
        self.response_times.append(duration_ms)
        if not success:
            self.error_count += 1

    def report(self):
        total = self.request_count
        if total == 0:
            return
        error_rate = (self.error_count / total) * 100
        times = sorted(self.response_times)
        print(f"  request_count   : {total}")
        print(f"  error_count     : {self.error_count}")
        print(f"  error_rate      : {error_rate:.1f}%")
        print(f"  latency_avg_ms  : {statistics.mean(times):.0f}")
        print(f"  latency_p95_ms  : {times[int(len(times)*0.95)]:.0f}")
        print(f"  latency_max_ms  : {max(times):.0f}")

        SLO_ERROR_RATE  = 1.0
        SLO_LATENCY_P95 = 300
        print()
        p95 = times[int(len(times)*0.95)]
        print(f"  SLO error_rate  <= {SLO_ERROR_RATE}%   : {'✓ MET' if error_rate <= SLO_ERROR_RATE else '✗ BREACHED'}")
        print(f"  SLO p95_latency <= {SLO_LATENCY_P95}ms : {'✓ MET' if p95 <= SLO_LATENCY_P95 else '✗ BREACHED'}")

m = SimpleMetrics()
random.seed(42)
for _ in range(100):
    duration = random.gauss(150, 40)
    success  = random.random() > 0.005   # 0.5% error rate
    m.record_request(max(duration, 10), success)

print("=== Metrics Report ===")
m.report()
EOF

echo ""
echo "--- BLOCK 2: metrics ---"
python3 metrics.py


# ===========================================================================
# BLOCK 3 — Log analysis: find errors in a log file
#
# The most common observability task: search the logs to answer
# "what happened right before the system went down?"
# ===========================================================================

cat > app.log << 'EOF'
{"timestamp":"2024-03-01T12:00:01Z","level":"INFO","message":"Request received","path":"/api/users"}
{"timestamp":"2024-03-01T12:00:02Z","level":"INFO","message":"Response sent","status":200}
{"timestamp":"2024-03-01T12:00:03Z","level":"ERROR","message":"Database timeout","duration_ms":5001}
{"timestamp":"2024-03-01T12:00:04Z","level":"WARN","message":"Retry attempt","attempt":1}
{"timestamp":"2024-03-01T12:00:05Z","level":"ERROR","message":"Connection refused","host":"db-primary"}
{"timestamp":"2024-03-01T12:00:06Z","level":"INFO","message":"Failover to replica","host":"db-replica"}
{"timestamp":"2024-03-01T12:00:07Z","level":"INFO","message":"Response sent","status":200}
EOF

echo ""
echo "--- BLOCK 3: find all ERROR entries in the log ---"
python3 -c "
import json
errors = []
with open('app.log') as f:
    for line in f:
        entry = json.loads(line)
        if entry['level'] == 'ERROR':
            errors.append(entry)

print(f'Found {len(errors)} errors:')
for e in errors:
    print(f'  [{e[\"timestamp\"]}] {e[\"message\"]}')
"

deactivate
