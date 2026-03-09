#!/bin/bash
# CompTIA AutoOps+ | Workflow Triggers
# Exam Objective 3.3 — Pipeline triggers: push, manual, scheduled, tag, branch, commit
#                       Webhooks, ChatOps


# ===========================================================================
# BLOCK 0 — Setup: create four trigger example files
# ===========================================================================

rm -rf triggers-demo
mkdir -p triggers-demo/.github/workflows
cd triggers-demo
echo "Trigger examples ready."


# ===========================================================================
# BLOCK 1 — Push trigger
#
# Fires automatically when code is pushed to a branch.
# Most common trigger in CI — every commit gets tested immediately.
# You can scope it to specific branches or file paths.
# ===========================================================================

cat > .github/workflows/push-trigger.yml << 'EOF'
name: Push Trigger Example

on:
  push:
    # Only trigger on these branches
    branches:
      - main
      - "feature/*"
      - "release/*"
    # Only trigger if these paths changed (optional — saves CI minutes)
    paths:
      - "src/**"
      - "requirements.txt"

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Triggered by push to ${{ github.ref_name }}"
      - run: echo "Commit SHA: ${{ github.sha }}"
EOF

echo ""
echo "--- BLOCK 1: push trigger ---"
cat .github/workflows/push-trigger.yml


# ===========================================================================
# BLOCK 2 — Scheduled trigger (cron)
#
# Runs on a timer. Used for nightly builds, security scans, cleanup jobs.
# Uses standard cron syntax: minute hour day-of-month month day-of-week
# ===========================================================================

cat > .github/workflows/scheduled-trigger.yml << 'EOF'
name: Scheduled Trigger Example

on:
  schedule:
    # Every day at 2:00 AM UTC   (cron: minute hour dom month dow)
    - cron: "0 2 * * *"
    # Every Monday at 9:00 AM UTC
    - cron: "0 9 * * 1"

jobs:
  nightly-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Nightly security scan running..."
EOF

echo ""
echo "--- BLOCK 2: scheduled trigger ---"
cat .github/workflows/scheduled-trigger.yml


# ===========================================================================
# BLOCK 3 — Manual trigger (workflow_dispatch)
#
# Lets you kick off a pipeline by clicking a button in the GitHub UI
# or via the GitHub API. Supports input parameters.
# ===========================================================================

cat > .github/workflows/manual-trigger.yml << 'EOF'
name: Manual Trigger Example

on:
  workflow_dispatch:
    # Optional inputs shown in the GitHub UI when you click "Run workflow"
    inputs:
      environment:
        description: "Target environment"
        required: true
        default: "staging"
        type: choice
        options:
          - staging
          - production
      run_tests:
        description: "Run test suite?"
        required: false
        default: "true"
        type: boolean

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying to ${{ inputs.environment }}"
      - run: echo "Run tests: ${{ inputs.run_tests }}"
EOF

echo ""
echo "--- BLOCK 3: manual trigger ---"
cat .github/workflows/manual-trigger.yml


# ===========================================================================
# BLOCK 4 — Tag trigger
#
# Fires when a git tag is pushed. Used to trigger production releases.
# Only tags matching the pattern kick off the pipeline.
# ===========================================================================

cat > .github/workflows/tag-trigger.yml << 'EOF'
name: Tag Trigger Example

on:
  push:
    # Only fires when a tag matching this pattern is pushed
    tags:
      - "v*.*.*"        # matches v1.0.0, v2.3.1, etc.
      - "v*.*.*-rc.*"   # also matches v1.0.0-rc.1

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Releasing version ${{ github.ref_name }}"
EOF

echo ""
echo "--- BLOCK 4: tag trigger ---"
cat .github/workflows/tag-trigger.yml


# ===========================================================================
# BLOCK 5 — Summary: all four trigger types side by side
# ===========================================================================

echo ""
echo "--- All trigger files created ---"
ls .github/workflows/

echo ""
echo "Trigger type summary:"
echo "  push trigger      : fires on every qualifying git push"
echo "  scheduled trigger : fires on a cron timer (nightly builds, scans)"
echo "  manual trigger    : fires when a human clicks 'Run workflow'"
echo "  tag trigger       : fires when a version tag is pushed (releases)"
