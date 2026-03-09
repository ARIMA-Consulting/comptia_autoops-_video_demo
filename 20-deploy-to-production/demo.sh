#!/bin/bash
# CompTIA AutoOps+ | Deploy to Production Safely
# Exam Objective 4.1 — Delivery methods + validation and remediation
# Exam Objective 4.3 — CLI configuration, IAM machine identities


# ===========================================================================
# BLOCK 0 — Setup
#
# "Deploy to production safely" means every step is gated and automated.
# No manual SSH into a server. No "fingers crossed" moments.
# The pipeline enforces the safety checks — not the human.
# ===========================================================================

rm -rf prod-deploy-demo
mkdir prod-deploy-demo
cd prod-deploy-demo
python3 -m venv venv && source venv/bin/activate
pip install requests -q
echo "Setup done."


# ===========================================================================
# BLOCK 1 — Pre-flight checklist
#
# Before anything touches production, run automated pre-flight checks.
# These are fast, cheap gates that catch obvious problems.
# ===========================================================================

cat > preflight.py << 'EOF'
"""Pre-flight checks — run before every production deployment."""
import sys, os, requests

checks_passed = 0
checks_failed = 0

def gate(name: str, condition: bool, blocking: bool = True):
    global checks_passed, checks_failed
    status = "✓ PASS" if condition else ("✗ FAIL" if blocking else "⚠ WARN")
    print(f"  {status}  {name}")
    if condition:
        checks_passed += 1
    else:
        checks_failed += 1 if blocking else 0

print("=== Pre-flight Checks ===")

# Environment checks
gate("DEPLOY_ENV is set",        os.environ.get("DEPLOY_ENV") is not None, blocking=False)
gate("APP_VERSION is set",       os.environ.get("APP_VERSION") is not None, blocking=False)

# Dependency check — staging API still reachable
try:
    r = requests.get("https://jsonplaceholder.typicode.com/posts/1", timeout=5)
    gate("Staging API is reachable", r.status_code == 200)
except:
    gate("Staging API is reachable", False)

# Simulated checks (would be real in production)
gate("All tests passed in CI",       True)   # CI enforces this before we get here
gate("Security scan clean",          True)
gate("Required approvals received",  True)
gate("Deployment window is open",    True)   # e.g., not Friday afternoon

print()
print(f"Pre-flight: {checks_passed} passed, {checks_failed} failed")

if checks_failed > 0:
    print("BLOCKED — fix failing checks before deploying")
    sys.exit(1)
else:
    print("All gates GREEN — safe to proceed")
EOF

export DEPLOY_ENV=production
export APP_VERSION=2.1.0

echo ""
echo "--- BLOCK 1: pre-flight checks ---"
python3 preflight.py


# ===========================================================================
# BLOCK 2 — The GitHub Actions production deployment workflow
#
# Key safety features:
#   1. Only deploys from main branch on a version tag
#   2. Requires pre-flight to pass before deploy step runs
#   3. Runs smoke tests after deploy
#   4. Notifies on success or failure
# ===========================================================================

mkdir -p .github/workflows

cat > .github/workflows/deploy-production.yml << 'EOF'
name: Deploy to Production

on:
  push:
    tags:
      - "v*.*.*"     # only fires when a version tag is pushed

jobs:

  pre-flight:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install requests
      - run: python preflight.py
        env:
          DEPLOY_ENV: production
          APP_VERSION: ${{ github.ref_name }}

  deploy:
    needs: pre-flight          # blocked until pre-flight passes
    runs-on: ubuntu-latest
    environment: production    # requires manual approval in GitHub Settings
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to production
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
        run: |
          echo "Deploying ${{ github.ref_name }} to production..."
          echo "Using deploy key: ${DEPLOY_KEY:0:4}****"

  smoke-test:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install requests
      - run: python smoke_test.py    # same smoke test from demo 18

  notify:
    needs: [deploy, smoke-test]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - run: |
          echo "Deploy status : ${{ needs.deploy.result }}"
          echo "Smoke test    : ${{ needs.smoke-test.result }}"
EOF

echo ""
echo "--- BLOCK 2: production deployment workflow ---"
cat .github/workflows/deploy-production.yml


# ===========================================================================
# BLOCK 3 — Rollback plan
#
# Every production deployment needs a documented rollback procedure.
# With git tags and a CI pipeline, rollback is just deploying the previous tag.
# ===========================================================================

cat > rollback.sh << 'EOF'
#!/bin/bash
# Rollback to the previous stable version
# Usage: bash rollback.sh v2.0.0

ROLLBACK_TAG="${1:-}"

if [ -z "$ROLLBACK_TAG" ]; then
    echo "Usage: bash rollback.sh <tag>"
    echo "Available tags:"
    git tag --sort=-version:refname | head -5
    exit 1
fi

echo "Rolling back to $ROLLBACK_TAG..."
echo "In a real pipeline: git push origin $ROLLBACK_TAG re-triggers the deploy job"
echo "Rollback complete."
EOF

chmod +x rollback.sh

echo ""
echo "--- BLOCK 3: rollback procedure ---"
cat rollback.sh

deactivate
