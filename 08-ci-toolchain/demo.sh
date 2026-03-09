#!/bin/bash
# CompTIA AutoOps+ | Inside a CI Toolchain
# Exam Objective 3.1 — Artifact management, secrets management, task runners
# Exam Objective 3.3 — Pipeline definition files
#
# This demo creates annotated CI config files and walks through their components.
# These files are what a real CI/CD system reads to run your pipeline.


# ===========================================================================
# BLOCK 0 — Setup
# ===========================================================================

rm -rf ci-toolchain-demo
mkdir ci-toolchain-demo
cd ci-toolchain-demo

echo "# My App" > README.md
echo 'print("Hello from CI")' > app.py

cat > requirements.txt << 'EOF'
requests
pytest
EOF

echo "Files created."


# ===========================================================================
# BLOCK 1 — The GitHub Actions workflow file
#
# A CI toolchain has three main jobs:
#   1. Source control trigger  — something kicks off the pipeline (a push, a tag)
#   2. Build / test steps      — the actual work
#   3. Artifact output         — what comes out the other end (built image, package)
#
# GitHub Actions is one of the most common CI tools and uses YAML syntax.
# The file lives at .github/workflows/<name>.yml in your repo.
# ===========================================================================

mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'EOF'
# The name shows up in the GitHub Actions UI
name: CI Pipeline

# TRIGGER: this pipeline runs on every push to main or any feature/* branch
on:
  push:
    branches:
      - main
      - "feature/*"

# A workflow is made of jobs. Jobs run on a "runner" (a VM GitHub provides).
jobs:

  build-and-test:
    # The OS image for the runner
    runs-on: ubuntu-latest

    steps:
      # Step 1: check out the source code onto the runner
      - name: Checkout code
        uses: actions/checkout@v4

      # Step 2: install the Python version we need
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      # Step 3: install project dependencies from requirements.txt
      - name: Install dependencies
        run: pip install -r requirements.txt

      # Step 4: run the test suite
      - name: Run tests
        run: pytest

      # Step 5: upload the build output as an artifact so other jobs can use it
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-build
          path: app.py
EOF

echo ""
echo "--- BLOCK 1 RESULT: workflow file ---"
cat .github/workflows/ci.yml


# ===========================================================================
# BLOCK 2 — Simulate the pipeline steps locally
#
# CI is just automation. Every command the pipeline runs, you can run too.
# This is exactly what the runner executes when your push triggers a build.
# ===========================================================================

echo ""
echo "--- BLOCK 2: run the same steps a CI runner would ---"

echo "[Step 1] Code is already here (checkout happened when you cloned)"
ls -1

echo ""
echo "[Step 2] Python version"
python3 --version

echo ""
echo "[Step 3] Install dependencies"
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt -q
echo "Done."

echo ""
echo "[Step 4] Run tests (no tests yet — this is what a green build looks like)"
python3 -m pytest --tb=short 2>&1 || echo "(no test files found — add test_*.py files to fix this)"

echo ""
echo "[Step 5] The artifact would be uploaded here in real CI"
echo "Artifact ready: app.py ($(wc -c < app.py) bytes)"

deactivate
