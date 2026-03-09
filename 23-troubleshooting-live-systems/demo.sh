#!/bin/bash
# CompTIA AutoOps+ | Troubleshooting Live Systems
# Exam Objective 1.4 — Troubleshoot code lifecycle issues
# Exam Objective 2.4 — Troubleshoot system configuration issues
# Exam Objective 4.2 — Feedback loop, MTTR


# ===========================================================================
# BLOCK 0 — Setup: create a broken system to troubleshoot
#
# The troubleshooting order that always works:
#   1. Is it running?       (process check)
#   2. What does the log say?  (last known state)
#   3. Is it reachable?     (network / port)
#   4. Is the config valid? (YAML / JSON / env vars)
#   5. Did something change? (git log, deploy history)
# ===========================================================================

rm -rf troubleshooting-demo
mkdir troubleshooting-demo
cd troubleshooting-demo
python3 -m venv venv && source venv/bin/activate
pip install requests -q

# Broken config file
cat > config.yaml << 'EOF'
database:
  host: localhost
  port: 5432
  name: mydb
  password: secret123
cache:
  host: redis-host
  port: 6379
  ttl_seconds: 300
app:
  port: 8080
  debug: false
  log_level: INFO
EOF

# A simulated app log with errors embedded
cat > app.log << 'EOF'
2024-03-01 11:58:00 INFO  Application starting...
2024-03-01 11:58:01 INFO  Config loaded from config.yaml
2024-03-01 11:58:02 INFO  Database connection established
2024-03-01 11:58:03 INFO  Cache connection established
2024-03-01 11:58:04 INFO  Server listening on port 8080
2024-03-01 12:00:00 INFO  GET /api/health 200 12ms
2024-03-01 12:01:00 ERROR ConnectionError: database query timed out after 5000ms
2024-03-01 12:01:01 ERROR Failed to load user id=4423: database unavailable
2024-03-01 12:01:02 WARN  Retry 1/3: reconnecting to database...
2024-03-01 12:01:05 ERROR Retry 2/3 failed: connection refused (host=localhost port=5432)
2024-03-01 12:01:08 ERROR Max retries exceeded. Returning 503 to client.
2024-03-01 12:01:09 INFO  GET /api/users 503 5032ms
2024-03-01 12:02:00 INFO  GET /api/health 200 11ms
2024-03-01 12:03:15 ERROR MemoryError: heap allocation failed (used: 3.8GB / 4GB)
2024-03-01 12:03:16 ERROR Service degraded — rejecting new connections
EOF

echo "Demo files created."


# ===========================================================================
# BLOCK 1 — Step 1: check what processes are actually running
#
# Before touching anything — find out what is alive and what is not.
# ===========================================================================

echo ""
echo "--- BLOCK 1: process and port checks ---"

echo "[Check 1] Python processes running:"
ps aux | grep python | grep -v grep || echo "  (none)"

echo ""
echo "[Check 2] What is listening on port 8080?"
ss -tlnp 2>/dev/null | grep 8080 || echo "  Nothing on 8080 (process may be down)"

echo ""
echo "[Check 3] System memory and disk:"
free -h | head -2
df -h / | tail -1


# ===========================================================================
# BLOCK 2 — Step 2: read the logs — most answers are here
#
# grep for ERROR and WARN first. Find the FIRST error, not the last.
# The first error is the cause; everything after is the cascade.
# ===========================================================================

echo ""
echo "--- BLOCK 2: log analysis ---"

echo "[Logs] All errors and warnings:"
grep -E "ERROR|WARN" app.log

echo ""
echo "[Logs] First error timestamp:"
grep "ERROR" app.log | head -1

echo ""
echo "[Logs] Timeline of events around the first error:"
grep -A 5 "12:01:00 ERROR" app.log


# ===========================================================================
# BLOCK 3 — Step 3: validate the config file
# ===========================================================================

echo ""
echo "--- BLOCK 3: validate config.yaml ---"

python3 -c "
import yaml
try:
    with open('config.yaml') as f:
        cfg = yaml.safe_load(f)
    print('Config is valid YAML')
    print(f'  Database host : {cfg[\"database\"][\"host\"]}')
    print(f'  App port      : {cfg[\"app\"][\"port\"]}')
    print(f'  Log level     : {cfg[\"app\"][\"log_level\"]}')
except yaml.YAMLError as e:
    print(f'CONFIG ERROR: {e}')
"


# ===========================================================================
# BLOCK 4 — Step 4: check external connectivity
#
# Can the system reach the services it depends on?
# ===========================================================================

echo ""
echo "--- BLOCK 4: connectivity checks ---"

echo "[Network] Can we reach the internet?"
curl -s --max-time 3 https://jsonplaceholder.typicode.com/posts/1 > /dev/null \
  && echo "  ✓ External HTTP reachable" \
  || echo "  ✗ External HTTP UNREACHABLE"

echo ""
echo "[Network] DNS resolution:"
python3 -c "
import socket
try:
    ip = socket.gethostbyname('jsonplaceholder.typicode.com')
    print(f'  ✓ DNS working (jsonplaceholder.typicode.com → {ip})')
except socket.gaierror as e:
    print(f'  ✗ DNS FAILED: {e}')
"


# ===========================================================================
# BLOCK 5 — Step 5: build the incident timeline and summarize
#
# Write down what you found. This becomes the post-mortem.
# ===========================================================================

cat > incident_summary.py << 'EOF'
"""Automated incident summary from log file."""
import re
from collections import Counter

with open("app.log") as f:
    lines = f.readlines()

errors  = [l.strip() for l in lines if "ERROR" in l]
warns   = [l.strip() for l in lines if "WARN"  in l]
infos   = [l.strip() for l in lines if "INFO"  in l]

print("=== Incident Summary ===")
print(f"  Total log lines : {len(lines)}")
print(f"  INFO events     : {len(infos)}")
print(f"  WARN events     : {len(warns)}")
print(f"  ERROR events    : {len(errors)}")
print()

# Extract unique error types
error_types = Counter()
for e in errors:
    match = re.search(r"ERROR (.+?):", e)
    if match:
        error_types[match.group(1)] += 1
    else:
        error_types["unknown"] += 1

print("Error types:")
for err_type, count in error_types.most_common():
    print(f"  {count}x  {err_type}")

print()
print("Recommended next steps:")
print("  1. Database: check if postgres process is running")
print("  2. Memory: investigate heap allocation failure at 12:03")
print("  3. Review recent deploys: did anything change before 12:01?")
EOF

echo ""
echo "--- BLOCK 5: incident summary ---"
python3 incident_summary.py

deactivate
