#!/bin/bash
# CompTIA AutoOps+ | Run a Triggered Build
# Exam Objective 3.3 — Pipeline triggers: push trigger, git variables (tag/branch/commit)
#
# BLOCK 3 (local simulation) runs offline — no setup needed.
# BLOCK 4 (act) runs GitHub Actions locally in Docker — no GitHub account needed.
#
# For BLOCK 4 (act):
#   Install act:
#     curl -Lo ~/.local/bin/act.tar.gz \
#       https://github.com/nektos/act/releases/latest/download/act_Linux_x86_64.tar.gz \
#       && tar -xz -C ~/.local/bin/ -f ~/.local/bin/act.tar.gz act \
#       && rm ~/.local/bin/act.tar.gz
#   Docker must be running.
#
# To also push to GitHub (BLOCK 2):
#   1. Create a GitHub repo and enable Actions on it
#   2. Update REPO_URL below

export PATH="$HOME/.local/bin:$PATH"
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO"


# ===========================================================================
# BLOCK 0 — Setup: create the project with a CI workflow
# ===========================================================================

rm -rf triggered-build-demo
mkdir -p triggered-build-demo/.github/workflows
cd triggered-build-demo
git init -b main
git config user.name "Demo User"
git config user.email "demo@example.com"

cat > app.py << 'EOF'
def greet():
    print("Hello from the build!")

greet()
EOF

cat > test_app.py << 'EOF'
from app import greet

def test_greet(capsys):
    greet()
    captured = capsys.readouterr()
    assert "Hello" in captured.out
EOF

cat > requirements.txt << 'EOF'
pytest
EOF

echo "Project files ready."


# ===========================================================================
# BLOCK 1 — The workflow file that responds to a push
#
# When you push to main, GitHub reads this file and runs the pipeline.
# The pipeline accesses git variables automatically:
#   github.sha        = the exact commit hash that triggered the build
#   github.ref_name   = the branch or tag name
#   github.actor      = who pushed
# ===========================================================================

cat > .github/workflows/triggered-build.yml << 'EOF'
name: Triggered Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Print git context variables
        run: |
          echo "Triggered by : ${{ github.actor }}"
          echo "Branch       : ${{ github.ref_name }}"
          echo "Commit SHA   : ${{ github.sha }}"
          echo "Event type   : ${{ github.event_name }}"

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - run: pip install -r requirements.txt

      - name: Run tests
        run: pytest test_app.py -v

      - name: Confirm build passed
        run: echo "Build ${{ github.sha }} passed."
EOF

cat .github/workflows/triggered-build.yml


# ===========================================================================
# BLOCK 2 — Commit and push to trigger the build
#           (requires the manual GitHub setup noted at the top)
#
# This is the moment students see: one git push = one pipeline run.
# ===========================================================================

git add .
git commit -m "add app and CI workflow"

echo ""
echo "--- BLOCK 2: push to trigger the build ---"
echo "Run this to push and trigger GitHub Actions:"
echo ""
echo "  git remote add origin $REPO_URL"
echo "  git push -u origin main"
echo ""
echo "Then open: $REPO_URL/actions"
echo "You will see the pipeline start within seconds of the push."


# ===========================================================================
# BLOCK 3 — Local simulation: run the same steps the CI runner would
#
# No GitHub needed. This proves the pipeline logic works before you push.
# ===========================================================================

echo ""
echo "--- BLOCK 3: local simulation of the triggered build ---"

SIMULATED_SHA=$(git rev-parse HEAD)
SIMULATED_BRANCH="main"
SIMULATED_ACTOR="Demo User"

echo "Triggered by : $SIMULATED_ACTOR"
echo "Branch       : $SIMULATED_BRANCH"
echo "Commit SHA   : $SIMULATED_SHA"
echo ""

python3 -m venv venv && source venv/bin/activate
pip install pytest -q
pytest test_app.py -v
echo ""
echo "Build $SIMULATED_SHA passed."
deactivate


# ===========================================================================
# BLOCK 4 — Run GitHub Actions locally with act
#
# act (github.com/nektos/act) runs your GitHub Actions workflows
# inside Docker containers — no push to GitHub required.
# This is exactly what GitHub's runners do, running on your machine.
#
# We use python:3.12-slim as the runner image (already cached from other demos).
# The --bind flag mounts this directory into the container so pytest finds your files.
# ===========================================================================

echo ""
echo "--- BLOCK 4: GitHub Actions running locally via act ---"
echo ""

# Create a workflow tuned for local act execution with python:3.12-slim
mkdir -p .github/workflows

cat > .github/workflows/ci-act.yml << 'EOF'
name: CI (local act runner)

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Show build context
        run: |
          echo "Branch   : ${{ github.ref_name }}"
          echo "Commit   : ${{ github.sha }}"
          echo "Workflow : ${{ github.workflow }}"

      - name: Install dependencies
        run: pip install pytest -q

      - name: Run tests
        run: pytest test_app.py -v

      - name: Confirm build
        run: echo "Build passed — artifact would be published here."
EOF

echo "Running workflow with act (using python:3.12-slim as the runner)..."
echo ""

act push \
  --platform ubuntu-latest=python:3.12-slim \
  --bind \
  --container-architecture linux/amd64 \
  -W .github/workflows/ci-act.yml \
  --artifact-server-path /tmp/act-artifacts \
  2>&1

echo ""
echo "act replays EXACTLY what GitHub Actions would run."
echo "Use this to test and debug workflows before you push."
echo ""
echo "To run a specific job:  act push -j build"
echo "To list available jobs: act --list"
