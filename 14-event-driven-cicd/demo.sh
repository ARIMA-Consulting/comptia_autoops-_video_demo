#!/bin/bash
# CompTIA AutoOps+ | Event-Driven CI/CD
# Exam Objective 2.2 — Cloud-based events: notification-based, messaging queues,
#                       webhooks, FaaS; Exam Objective 3.3 — Webhooks, ChatOps


# ===========================================================================
# BLOCK 0 — Setup
#
# Event-driven means something HAPPENING triggers the pipeline automatically.
# No human needed. The event fires → the handler runs.
#
# Common events in CI/CD:
#   git push         → trigger a build pipeline
#   PR opened        → trigger code review checks
#   tag created      → trigger a release pipeline
#   schedule fires   → trigger a nightly scan
#   external webhook → trigger from a third-party system (Slack, Jira, etc.)
# ===========================================================================

rm -rf event-driven-demo
mkdir event-driven-demo
cd event-driven-demo
python3 -m venv venv && source venv/bin/activate
pip install flask -q
echo "Setup done."


# ===========================================================================
# BLOCK 1 — What a webhook payload looks like
#
# When GitHub detects a push, it sends an HTTP POST to a URL you configure.
# The body is a JSON payload describing what happened.
# This is the raw event that kicks off your CI pipeline.
# ===========================================================================

cat > sample_webhook_payload.json << 'EOF'
{
  "event": "push",
  "ref": "refs/heads/main",
  "repository": {
    "name": "my-app",
    "full_name": "demo-user/my-app"
  },
  "pusher": {
    "name": "demo-user"
  },
  "head_commit": {
    "id": "abc123def456",
    "message": "fix: resolve login crash",
    "timestamp": "2024-03-01T12:00:00Z"
  }
}
EOF

echo ""
echo "--- BLOCK 1: a GitHub push webhook payload ---"
cat sample_webhook_payload.json


# ===========================================================================
# BLOCK 2 — A webhook receiver in Python
#
# This is what a CI server does when it receives a webhook.
# It reads the payload and decides what action to take.
# ===========================================================================

cat > webhook_handler.py << 'EOF'
import json

def handle_event(payload: dict):
    """Decide what to do based on the event type and context."""
    event  = payload.get("event")
    ref    = payload.get("ref", "")
    commit = payload.get("head_commit", {})

    print(f"Event received : {event}")
    print(f"Ref            : {ref}")
    print(f"Commit         : {commit.get('id', '')[:7]}  —  {commit.get('message')}")
    print()

    # Event routing: different events trigger different actions
    if event == "push" and ref == "refs/heads/main":
        print("→ Action: trigger CI build pipeline")
        run_ci_pipeline(commit["id"])

    elif event == "push" and ref.startswith("refs/tags/"):
        tag = ref.replace("refs/tags/", "")
        print(f"→ Action: trigger release pipeline for tag {tag}")

    elif event == "pull_request":
        print("→ Action: run PR checks (lint, test)")

    else:
        print(f"→ Action: no handler for event={event} ref={ref}, skipping")

def run_ci_pipeline(commit_sha):
    print(f"  [CI] Checking out {commit_sha[:7]}")
    print(f"  [CI] Installing dependencies")
    print(f"  [CI] Running tests")
    print(f"  [CI] Build complete")

# Simulate receiving the webhook
with open("sample_webhook_payload.json") as f:
    payload = json.load(f)

handle_event(payload)
EOF

echo ""
echo "--- BLOCK 2: webhook handler ---"
python3 webhook_handler.py


# ===========================================================================
# BLOCK 3 — Simulate different events going through the router
# ===========================================================================

echo ""
echo "--- BLOCK 3: what happens when a tag is pushed ---"

cat > tag_payload.json << 'EOF'
{
  "event": "push",
  "ref": "refs/tags/v2.0.0",
  "repository": {"name": "my-app", "full_name": "demo-user/my-app"},
  "pusher": {"name": "demo-user"},
  "head_commit": {"id": "def789ghi012", "message": "release: v2.0.0", "timestamp": "2024-03-01T14:00:00Z"}
}
EOF

python3 -c "
import json
import sys
sys.path.insert(0, '.')
from webhook_handler import handle_event
with open('tag_payload.json') as f:
    handle_event(json.load(f))
"

deactivate
