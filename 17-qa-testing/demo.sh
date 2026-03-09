#!/bin/bash
# CompTIA AutoOps+ | QA Testing in DevOps Pipelines
# Exam Objective 4.1 — QA testing: load testing, regression testing, integration testing


# ===========================================================================
# BLOCK 0 — Setup
#
# QA in DevOps is automated — tests run in the pipeline on every push.
# Three types on the exam:
#   Integration testing : does component A talk to component B correctly?
#   Regression testing  : did we break something that used to work?
#   Load testing        : does the app hold up under traffic?
# ===========================================================================

rm -rf qa-testing-demo
mkdir qa-testing-demo
cd qa-testing-demo
python3 -m venv venv && source venv/bin/activate
pip install pytest requests -q

cat > app.py << 'EOF'
def add(a, b):
    return a + b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

def get_user(user_id: int) -> dict:
    if user_id <= 0:
        raise ValueError("user_id must be positive")
    return {"id": user_id, "name": f"User {user_id}", "active": True}
EOF

echo "Files ready."


# ===========================================================================
# BLOCK 1 — Regression tests
#
# Regression tests confirm that existing behaviour still works after a change.
# Run these on every single commit — they are the safety net.
# A failing regression test means "you broke something that used to work."
# ===========================================================================

cat > test_regression.py << 'EOF'
"""Regression tests — run on every commit to catch regressions."""
import pytest
from app import add, divide, get_user

# --- arithmetic ---
def test_add_positive():
    assert add(2, 3) == 5

def test_add_negative():
    assert add(-1, -1) == -2

def test_add_zero():
    assert add(0, 100) == 100

def test_divide_basic():
    assert divide(10, 2) == 5.0

def test_divide_by_zero_raises():
    with pytest.raises(ValueError, match="Cannot divide by zero"):
        divide(10, 0)

# --- user lookup ---
def test_get_user_returns_dict():
    user = get_user(1)
    assert isinstance(user, dict)
    assert user["id"] == 1

def test_get_user_invalid_id():
    with pytest.raises(ValueError):
        get_user(-1)
EOF

echo ""
echo "--- BLOCK 1: regression tests ---"
pytest test_regression.py -v


# ===========================================================================
# BLOCK 2 — Integration tests
#
# Integration tests verify that two or more components work together.
# Here we test our app against the real external API it depends on.
# REQUIRES: internet connection
# ===========================================================================

cat > test_integration.py << 'EOF'
"""Integration tests — verify our code works with real external dependencies."""
import requests
import pytest

BASE_URL = "https://jsonplaceholder.typicode.com"

def test_external_api_is_reachable():
    """Verify the API we depend on is up."""
    response = requests.get(f"{BASE_URL}/posts/1", timeout=5)
    assert response.status_code == 200

def test_api_returns_expected_schema():
    """Verify the response has the fields our code expects."""
    response = requests.get(f"{BASE_URL}/posts/1", timeout=5)
    data = response.json()
    assert "id" in data
    assert "title" in data
    assert "body" in data
    assert "userId" in data

def test_create_post_returns_201():
    """Verify we can create resources via the API."""
    response = requests.post(
        f"{BASE_URL}/posts",
        json={"title": "Test", "body": "Integration test post", "userId": 1},
        timeout=5,
    )
    assert response.status_code == 201
EOF

echo ""
echo "--- BLOCK 2: integration tests ---"
pytest test_integration.py -v


# ===========================================================================
# BLOCK 3 — Load test simulation
#
# Load tests measure how the system behaves under concurrent traffic.
# We simulate multiple requests and track response times.
# Real load testing tools: k6, Locust, JMeter, Artillery
# ===========================================================================

cat > load_test_sim.py << 'EOF'
"""Simplified load test — measures response time under simulated traffic."""
import requests, time, statistics

URL = "https://jsonplaceholder.typicode.com/posts/1"
NUM_REQUESTS = 10
LATENCY_SLO_MS = 500   # SLO: 95% of requests must complete in under 500ms

print(f"Load test: {NUM_REQUESTS} sequential requests to {URL}")
print()

times = []
errors = 0

for i in range(NUM_REQUESTS):
    start = time.time()
    try:
        r = requests.get(URL, timeout=5)
        elapsed_ms = (time.time() - start) * 1000
        times.append(elapsed_ms)
        print(f"  Request {i+1:2d}: {elapsed_ms:6.0f}ms  HTTP {r.status_code}")
    except Exception as e:
        errors += 1
        print(f"  Request {i+1:2d}: ERROR — {e}")

print()
print(f"Results ({NUM_REQUESTS} requests):")
print(f"  Errors    : {errors}")
print(f"  Avg (ms)  : {statistics.mean(times):.0f}")
print(f"  p95 (ms)  : {sorted(times)[int(len(times)*0.95)]:.0f}")
print(f"  Max (ms)  : {max(times):.0f}")

p95 = sorted(times)[int(len(times)*0.95)]
if p95 < LATENCY_SLO_MS:
    print(f"  ✓ p95 {p95:.0f}ms is within SLO ({LATENCY_SLO_MS}ms)")
else:
    print(f"  ✗ p95 {p95:.0f}ms EXCEEDS SLO ({LATENCY_SLO_MS}ms) — investigate")
EOF

echo ""
echo "--- BLOCK 3: load test simulation ---"
python3 load_test_sim.py

deactivate
