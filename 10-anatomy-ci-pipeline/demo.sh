#!/bin/bash
# CompTIA AutoOps+ | Anatomy of a CI Pipeline
# Exam Objective 3.2 — Orchestration: parallel vs sequential, step dependencies,
#                       conditional execution, failure handling, security scanning,
#                       code quality scanning, containerization


# ===========================================================================
# BLOCK 0 — Setup
# ===========================================================================

rm -rf pipeline-anatomy-demo
mkdir -p pipeline-anatomy-demo/.github/workflows
cd pipeline-anatomy-demo

cat > app.py << 'EOF'
def add(a, b):
    return a + b
EOF

cat > test_app.py << 'EOF'
from app import add

def test_add():
    assert add(2, 3) == 5

def test_add_negative():
    assert add(-1, 1) == 0
EOF

cat > requirements.txt << 'EOF'
pytest
EOF

echo "Files created. Opening pipeline.yml..."


# ===========================================================================
# BLOCK 1 — The full annotated pipeline
#
# A CI pipeline has a clear anatomy:
#   trigger  -> who starts it
#   jobs     -> groups of work (can run in parallel or sequence)
#   steps    -> individual commands inside a job
#   needs    -> declares a dependency between jobs (forces sequential order)
#   if       -> conditional execution
#   on error -> failure handling
# ===========================================================================

cat > .github/workflows/pipeline.yml << 'EOF'
name: Full CI Pipeline

on:
  push:
    branches: [main, "feature/*"]

jobs:

  # -----------------------------------------------------------------------
  # JOB 1: lint — runs in parallel with "test" (no "needs" declared)
  # Checks code style. Fast. Fails early before wasting test time.
  # -----------------------------------------------------------------------
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install flake8
      - name: Run linter
        run: flake8 app.py --max-line-length=88

  # -----------------------------------------------------------------------
  # JOB 2: test — also runs in parallel with "lint"
  # Runs the test suite and uploads a coverage report as an artifact.
  # -----------------------------------------------------------------------
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - name: Run tests
        run: pytest test_app.py -v
      - name: Upload test results
        if: always()    # upload results even if tests fail
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: .pytest_cache/

  # -----------------------------------------------------------------------
  # JOB 3: security-scan — runs in parallel with lint and test
  # Scans dependencies for known vulnerabilities.
  # -----------------------------------------------------------------------
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install safety
      - name: Scan dependencies
        run: safety check -r requirements.txt
        continue-on-error: true   # don't block the pipeline for known-safe packages

  # -----------------------------------------------------------------------
  # JOB 4: build — runs AFTER lint AND test both pass
  # "needs" creates a dependency — this job will not start until both
  # lint and test complete successfully.
  # -----------------------------------------------------------------------
  build:
    runs-on: ubuntu-latest
    needs: [lint, test]    # sequential: waits for both parallel jobs above
    steps:
      - uses: actions/checkout@v4
      - name: Build application
        run: echo "Building and packaging app..."
      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-artifact
          path: app.py

  # -----------------------------------------------------------------------
  # JOB 5: notify — runs after build, even if build failed
  # "if: always()" means this job fires regardless of upstream status.
  # -----------------------------------------------------------------------
  notify:
    runs-on: ubuntu-latest
    needs: [build]
    if: always()
    steps:
      - name: Send status notification
        run: |
          echo "Pipeline finished."
          echo "Build status: ${{ needs.build.result }}"
EOF

cat .github/workflows/pipeline.yml


# ===========================================================================
# BLOCK 2 — Run the tests locally (same as what the "test" job does)
# ===========================================================================

echo ""
echo "--- BLOCK 2: run tests locally the same way CI would ---"
python3 -m venv venv && source venv/bin/activate
pip install pytest -q
pytest test_app.py -v
deactivate
