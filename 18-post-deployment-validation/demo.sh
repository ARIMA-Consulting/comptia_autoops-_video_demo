#!/bin/bash
# CompTIA AutoOps+ | Post-Deployment Validation
# Exam Objective 4.1 — Validation and remediation: smoke testing,
#                       post-deployment testing, hotfixes


# ===========================================================================
# BLOCK 0 — Setup
#
# Post-deployment validation = confirming the deployment actually worked.
# It runs AFTER the code is live, not before.
#
# Two layers:
#   Smoke test        : quick "is it alive?" check — pass/fail in < 60 seconds
#   Post-deploy test  : deeper functional checks — did the features land correctly?
#
# If smoke tests fail → automatic rollback
# If post-deploy tests fail → hotfix or rollback
# ===========================================================================

rm -rf post-deploy-demo
mkdir post-deploy-demo
cd post-deploy-demo
python3 -m venv venv && source venv/bin/activate
pip install requests -q
echo "Setup done."


# ===========================================================================
# BLOCK 1 — Smoke tests
#
# A smoke test is the simplest possible health check.
# Name comes from hardware testing: turn it on, see if it smokes.
# In software: hit the health endpoint, verify a 200 comes back.
# ===========================================================================

cat > smoke_test.py << 'EOF'
"""
Smoke tests — run immediately after every deployment.
If ANY smoke test fails, trigger an automatic rollback.
"""
import requests
import sys

BASE_URL = "https://jsonplaceholder.typicode.com"   # stand-in for your deployed app
TIMEOUT  = 5
FAILURES = []

def check(name: str, url: str, expected_status: int = 200):
    try:
        r = requests.get(url, timeout=TIMEOUT)
        if r.status_code == expected_status:
            print(f"  ✓ PASS  {name}  (HTTP {r.status_code})")
        else:
            print(f"  ✗ FAIL  {name}  (expected {expected_status}, got {r.status_code})")
            FAILURES.append(name)
    except Exception as e:
        print(f"  ✗ FAIL  {name}  (connection error: {e})")
        FAILURES.append(name)

print("=== Smoke Tests ===")
check("Health endpoint",    f"{BASE_URL}/posts/1")
check("Users endpoint",     f"{BASE_URL}/users/1")
check("404 returns 404",    f"{BASE_URL}/posts/99999999", expected_status=404)

print()
if FAILURES:
    print(f"SMOKE TEST FAILED ({len(FAILURES)} checks failed): {FAILURES}")
    print("→ Triggering automatic rollback")
    sys.exit(1)
else:
    print("All smoke tests PASSED — deployment is healthy")
    sys.exit(0)
EOF

echo ""
echo "--- BLOCK 1: smoke tests ---"
python3 smoke_test.py


# ===========================================================================
# BLOCK 2 — Post-deployment functional tests
#
# Deeper checks that verify the specific features you just deployed.
# These run after the smoke test passes.
# ===========================================================================

cat > post_deploy_test.py << 'EOF'
"""
Post-deployment tests — verify features work correctly in production.
Run after smoke tests pass.
"""
import requests

BASE_URL = "https://jsonplaceholder.typicode.com"
PASSED = 0
FAILED = 0

def test(description: str, condition: bool):
    global PASSED, FAILED
    if condition:
        print(f"  ✓ {description}")
        PASSED += 1
    else:
        print(f"  ✗ {description}")
        FAILED += 1

print("=== Post-Deployment Tests ===")

# Test: can we read a post?
r = requests.get(f"{BASE_URL}/posts/1")
test("GET /posts/1 returns 200",       r.status_code == 200)
test("Response contains 'title' key",  "title" in r.json())
test("Response contains 'body' key",   "body"  in r.json())

# Test: can we create a resource?
r = requests.post(f"{BASE_URL}/posts",
    json={"title": "Post-deploy test", "body": "Validation run", "userId": 1})
test("POST /posts returns 201",        r.status_code == 201)
test("Created post has an id",         "id" in r.json())

# Test: does the users endpoint still work?
r = requests.get(f"{BASE_URL}/users/1")
test("GET /users/1 returns 200",       r.status_code == 200)
test("User has email field",           "email" in r.json())

print()
print(f"Result: {PASSED} passed, {FAILED} failed")
if FAILED:
    print("→ Post-deployment issues detected — consider hotfix or rollback")
else:
    print("→ All checks passed — deployment validated")
EOF

echo ""
echo "--- BLOCK 2: post-deployment functional tests ---"
python3 post_deploy_test.py


# ===========================================================================
# BLOCK 3 — What the pipeline looks like with validation gates
# ===========================================================================

cat > pipeline_with_validation.yml << 'EOF'
# Deployment pipeline with post-deployment validation gates
name: Deploy with Validation

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to staging
        run: echo "Deploying..."

  smoke-test:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install requests
      - name: Run smoke tests
        run: python smoke_test.py
      # If this step fails, the pipeline stops here and does NOT continue to production

  post-deploy-test:
    needs: smoke-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install requests
      - name: Run post-deployment tests
        run: python post_deploy_test.py

  promote-to-production:
    needs: post-deploy-test
    runs-on: ubuntu-latest
    steps:
      - name: Promote to production
        run: echo "All gates passed — promoting to production"
EOF

echo ""
echo "--- BLOCK 3: pipeline with validation gates ---"
cat pipeline_with_validation.yml

deactivate
