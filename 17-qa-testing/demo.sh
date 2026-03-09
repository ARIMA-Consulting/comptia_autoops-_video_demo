#!/bin/bash
# CompTIA AutoOps+ | QA Testing in DevOps Pipelines
# Exam Objective 4.1 — QA testing: load testing, regression testing, integration testing
#
# REQUIRES for BLOCK 3 (Locust load testing):
#   pip install locust   (or: pip3 install locust --break-system-packages)


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
# BLOCK 3 — Real load test with Locust
#
# Locust is an industry-standard open-source load testing tool.
# You define user behaviour in Python, then Locust spawns concurrent users.
# It shows real-time stats: requests/sec, response times, failure rate.
#
# REQUIRES: pip install locust
# REQUIRES: internet (hits jsonplaceholder.typicode.com)
# ===========================================================================

cat > locustfile.py << 'EOF'
"""
Locust load test targeting jsonplaceholder.typicode.com.
Each simulated user randomly runs the three @task methods.
The weight (number) controls how often each task is chosen.
"""
from locust import HttpUser, task, between

class APIUser(HttpUser):
    # Each user waits 0.5–1.5s between tasks (simulate real users)
    wait_time = between(0.5, 1.5)

    @task(3)
    def read_post(self):
        """GET a single post — most common operation"""
        self.client.get("/posts/1", name="/posts/[id]")

    @task(1)
    def create_post(self):
        """POST a new post — write operation"""
        self.client.post("/posts", json={
            "title": "load test post",
            "body": "generated by locust",
            "userId": 1,
        })

    @task(1)
    def list_posts(self):
        """GET all posts — heavier read"""
        self.client.get("/posts")
EOF

echo ""
echo "--- BLOCK 3: Locust load test (10 users, 15 seconds) ---"
echo ""
echo "Running headless load test against jsonplaceholder.typicode.com..."
echo "(Locust spawns 10 virtual users, ramps up at 2/sec, runs for 15s)"
echo ""

# Run Locust in headless mode — prints stats to terminal
locust \
  --headless \
  --users 10 \
  --spawn-rate 2 \
  --run-time 15s \
  --host https://jsonplaceholder.typicode.com \
  -f locustfile.py \
  --html load_report.html \
  2>&1

echo ""
echo "Load report saved to: load_report.html"
echo "Open it in a browser to see the full results chart."
echo ""
echo "--- To run with the Locust web UI instead (interactive): ---"
echo "  locust -f locustfile.py --host https://jsonplaceholder.typicode.com"
echo "  Then open: http://localhost:8089"
echo "  Set users=20, spawn-rate=5, click Start swarming."

deactivate
