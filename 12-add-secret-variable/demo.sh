#!/bin/bash
# CompTIA AutoOps+ | Add a Secret Variable
# Exam Objective 3.1 — Secrets management: encrypted storage, tokenization,
#                       zero trust, dynamic secret rotation


# ===========================================================================
# BLOCK 0 — Setup
#
# The golden rule: NEVER hardcode secrets in source code.
# Secrets belong in environment variables or a secrets manager —
# never in a file that gets committed to git.
# ===========================================================================

docker rm -f vault-dev 2>/dev/null || true
rm -rf secrets-demo
mkdir secrets-demo
cd secrets-demo
git init -b main
git config user.name "Demo User"
git config user.email "demo@example.com"

echo "Project ready."


# ===========================================================================
# BLOCK 1 — The WRONG way: hardcoded secret in source code
#
# This gets committed to git and is visible to everyone who clones the repo.
# Once pushed, it is in the history forever even if you delete it later.
# ===========================================================================

cat > bad_config.py << 'EOF'
# BAD — never do this
API_KEY = "sk-abc123supersecretkey"
DB_PASSWORD = "hunter2"

print(f"Connecting with key: {API_KEY}")
EOF

cat bad_config.py

echo ""
echo "If this gets pushed to GitHub, that secret is EXPOSED."
echo "Rotating the key is the only fix — just deleting the file is not enough."


# ===========================================================================
# BLOCK 2 — The RIGHT way: load secrets from environment variables
#
# The code never sees the actual value — it reads it from the environment
# at runtime. The source code is safe to commit and share.
# ===========================================================================

cat > app.py << 'EOF'
import os

# Read from environment — the value is never written in the code
api_key  = os.environ.get("API_KEY")
db_pass  = os.environ.get("DB_PASSWORD")

if not api_key:
    raise EnvironmentError("API_KEY is not set — check your secrets configuration")

print(f"API key loaded: {api_key[:4]}****")   # only show first 4 chars in logs
print("Connection ready.")
EOF

cat app.py


# ===========================================================================
# BLOCK 3 — The .env file pattern (local development only)
#
# A .env file stores secrets for local development.
# It is loaded by python-dotenv and MUST be in .gitignore.
# ===========================================================================

cat > .env << 'EOF'
API_KEY=sk-abc123supersecretkey
DB_PASSWORD=hunter2
EOF

cat > .gitignore << 'EOF'
.env
venv/
__pycache__/
EOF

echo ""
echo "--- .env file (local dev only — NEVER commit this) ---"
cat .env

echo ""
echo "--- .gitignore (protects the .env from being committed) ---"
cat .gitignore

echo ""
echo "--- git status: confirm .env is not tracked ---"
git add app.py .gitignore requirements.txt 2>/dev/null || git add app.py .gitignore
git status


# ===========================================================================
# BLOCK 4 — Load the .env and run the app
#
# python-dotenv reads the .env file and injects the values as environment
# variables before the app code runs.
# ===========================================================================

cat > requirements.txt << 'EOF'
python-dotenv
EOF

python3 -m venv venv && source venv/bin/activate
pip install python-dotenv -q

cat > run.py << 'EOF'
from dotenv import load_dotenv
load_dotenv()   # reads .env and sets environment variables

import os
api_key = os.environ.get("API_KEY")
print(f"API key loaded: {api_key[:4]}****")
print("Connection ready.")
EOF

python3 run.py
deactivate


# ===========================================================================
# BLOCK 5 — How GitHub Actions handles secrets
#
# In CI/CD you store secrets in the platform (GitHub Settings → Secrets).
# They are injected as environment variables at runtime and are MASKED in logs.
# ===========================================================================

mkdir -p .github/workflows

cat > .github/workflows/with-secrets.yml << 'EOF'
name: Pipeline with Secrets

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Secrets are injected as environment variables
      # They are never visible in logs — GitHub masks them automatically
      - name: Use secret in a step
        env:
          API_KEY: ${{ secrets.API_KEY }}        # set in GitHub Settings → Secrets
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
        run: |
          echo "API key length: ${#API_KEY} chars"
          echo "Running deployment..."
          # If you accidentally echo the secret, GitHub replaces it with ***
EOF

echo ""
echo "--- BLOCK 5: GitHub Actions secrets workflow ---"
cat .github/workflows/with-secrets.yml

echo ""
echo "To add secrets in GitHub:"
echo "  Repo → Settings → Secrets and variables → Actions → New repository secret"


# ===========================================================================
# BLOCK 6 — HashiCorp Vault: live secrets manager demo
#
# Vault is the industry standard for enterprise secrets management.
# Apps never see secrets on disk — they authenticate to Vault and
# fetch them at runtime via API. Vault logs every access.
#
# Dev mode = single-node, in-memory, instant start. Perfect for demos.
# Production: HA cluster with encrypted storage (Raft or Consul).
#
# Exam Objective 3.1: encrypted key vault, revocation, lease management,
#                     tokenization, dynamic secret rotation.
#
# REQUIRES: Docker (already needed for demo 08 and 21)
# Students: docker pull hashicorp/vault  (one-time, ~100MB)
# ===========================================================================

echo ""
echo "--- BLOCK 6: HashiCorp Vault — live secrets manager ---"

# Clean up any previous run
docker rm -f vault-dev 2>/dev/null || true

# Start Vault in dev mode — instant, no config needed
docker run -d --name vault-dev \
  -p 8200:8200 \
  --cap-add=IPC_LOCK \
  -e VAULT_DEV_ROOT_TOKEN_ID=root \
  -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
  hashicorp/vault:latest

echo "Waiting for Vault..."
until docker exec vault-dev sh -c \
  "VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault status" \
  >/dev/null 2>&1; do sleep 1; done
echo "Vault is up."
echo ""

# Write secrets (this is what an admin or a deployment pipeline does)
docker exec vault-dev sh -c \
  "VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
   vault kv put secret/myapp api_key=sk-demo-key-abc123 db_password=s3cr3t_pass"

echo ""
echo "--- Read the secret back (what the app does at runtime): ---"
docker exec vault-dev sh -c \
  "VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
   vault kv get secret/myapp"

echo ""
echo "--- List all secret paths (full audit trail in production): ---"
docker exec vault-dev sh -c \
  "VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
   vault kv list secret/"

echo ""
echo "Open the Vault UI in your browser:"
echo "  URL  : http://localhost:8200"
echo "  Token: root"
echo ""
echo "In the UI you can see: secrets, access policies, audit logs."
echo ""
echo "Key difference from .env:"
echo "  .env file : secret on disk, manually rotated, commit risk"
echo "  Vault     : fetched via API at runtime, audit logged, auto-rotates"
echo ""
echo "Cleanup: docker rm -f vault-dev"
