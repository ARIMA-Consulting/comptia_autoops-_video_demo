#!/bin/bash
# CompTIA AutoOps+ | Create an Event Notification
# Exam Objective 2.2 — Cloud-based events: notification-based events, FaaS
#
# Uses https://httpbin.org/post — a free echo server that returns whatever
# you POST to it. No account needed. REQUIRES: internet connection.


# ===========================================================================
# BLOCK 0 — Setup
#
# An event notification is a message your system sends when something happens:
#   build passed / failed → notify the team
#   deployment completed  → notify monitoring
#   error threshold hit   → notify on-call
#
# The most common format is a JSON payload sent via HTTP POST (webhook).
# ===========================================================================

rm -rf notification-demo
mkdir notification-demo
cd notification-demo
python3 -m venv venv && source venv/bin/activate
pip install requests -q
echo "Setup done."


# ===========================================================================
# BLOCK 1 — Send a simple build notification with curl
#
# This is exactly what a CI pipeline does when it finishes.
# httpbin.org/post echoes the request back so we can see it was received.
# ===========================================================================

echo ""
echo "--- BLOCK 1: send a build notification via curl ---"

curl -s -X POST https://httpbin.org/post \
  -H "Content-Type: application/json" \
  -d '{
    "event":       "build.complete",
    "status":      "success",
    "pipeline":    "CI Build",
    "branch":      "main",
    "commit":      "abc123",
    "message":     "All tests passed.",
    "duration_s":  42
  }' | python3 -m json.tool


# ===========================================================================
# BLOCK 2 — A reusable notification function in Python
#
# In real pipelines this function is called at the end of each stage.
# ===========================================================================

cat > notify.py << 'EOF'
import requests
import json
from datetime import datetime

WEBHOOK_URL = "https://httpbin.org/post"   # swap in your real Slack/Teams URL

def send_notification(event: str, status: str, detail: str):
    payload = {
        "event":     event,
        "status":    status,
        "detail":    detail,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }

    print(f"Sending notification: {event} → {status}")

    response = requests.post(
        WEBHOOK_URL,
        headers={"Content-Type": "application/json"},
        json=payload,
        timeout=10,
    )

    if response.status_code == 200:
        echo_data = response.json().get("json", {})
        print(f"Server received: {json.dumps(echo_data, indent=2)}")
    else:
        print(f"Notification failed: HTTP {response.status_code}")

if __name__ == "__main__":
    # Simulate a pipeline sending three different notifications
    send_notification("build.started",  "info",    "Pipeline triggered by push to main")
    print()
    send_notification("tests.passed",   "success", "42 tests passed in 8.3s")
    print()
    send_notification("deploy.failed",  "error",   "Deployment to production timed out")
EOF

echo ""
echo "--- BLOCK 2: Python notification function ---"
python3 notify.py


# ===========================================================================
# BLOCK 3 — How this maps to real notification platforms
#
# Slack and Microsoft Teams both accept the same webhook POST pattern.
# You just swap the URL and adjust the payload format.
# ===========================================================================

cat > slack_notify.py << 'EOF'
import requests

# Slack webhook payload format
# Get your URL from: Slack → Apps → Incoming Webhooks
SLACK_WEBHOOK = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

def slack_alert(message: str, color: str = "good"):
    payload = {
        "attachments": [
            {
                "color": color,          # "good" = green, "danger" = red, "warning" = yellow
                "text": message,
                "footer": "CompTIA AutoOps+ CI",
            }
        ]
    }
    # requests.post(SLACK_WEBHOOK, json=payload)
    print(f"Would send to Slack: {message}")

slack_alert("✓ Build passed on main — v1.2.3 is ready to deploy", color="good")
slack_alert("✗ Deploy failed — rolling back", color="danger")
EOF

echo ""
echo "--- BLOCK 3: Slack notification pattern ---"
python3 slack_notify.py

deactivate
