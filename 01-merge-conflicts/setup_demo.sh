#!/bin/bash
# =============================================================================
# CompTIA AutoOps+ | Topic 1: Merge Conflicts
# Exam Objective: 1.4 - Troubleshoot common issues with the code life cycle
#                        Git errors -> Merge conflicts
#
# This script builds a demo repo that puts you RIGHT BEFORE a merge conflict.
# Run it, then follow the presenter_notes.md to walk students through resolution.
# =============================================================================

set -e  # Stop immediately on any error

DEMO_DIR="merge-conflict-demo"

# --------------------------------------------------------------------------
# Clean up any previous run so the demo is always fresh
# --------------------------------------------------------------------------
if [ -d "$DEMO_DIR" ]; then
    echo "Removing previous demo folder..."
    rm -rf "$DEMO_DIR"
fi

echo ""
echo "======================================================"
echo "  Setting up: Merge Conflicts Demo"
echo "======================================================"

# --------------------------------------------------------------------------
# STEP 1 – Create the project folder and initialize Git
# git init  : turns any folder into a Git repository by creating a hidden
#             .git directory where all version history is stored.
# --------------------------------------------------------------------------
mkdir "$DEMO_DIR"
cd "$DEMO_DIR"

# git init -b main : initialize and immediately name the default branch "main".
# Older Git systems default to "master" — we use "main" to match GitHub conventions.
git init -b main

# Set a local identity so commits work even on a fresh machine
git config user.name  "Demo User"
git config user.email "demo@example.com"

echo ""
echo "[STEP 1] Initialized empty Git repo in ./$DEMO_DIR"

# --------------------------------------------------------------------------
# STEP 2 – Create the starting file and commit it to main
# git add .          : stages ALL changes in the current directory.
# git commit -m "…" : saves staged changes as a permanent snapshot
#                     with a human-readable message.
# --------------------------------------------------------------------------
cat > app.py << 'PYTHON'
# Simple greeting script

def greet():
    message = "Hello"
    print(message)

greet()
PYTHON

git add app.py
git commit -m "initial commit: add greet function"

echo "[STEP 2] Initial commit on main  ->  message = \"Hello\""

# --------------------------------------------------------------------------
# STEP 3 – Create the feature branch and change the same line
# git checkout -b <name> : creates a new branch AND switches to it in one step.
#                          Think of a branch as a parallel timeline of commits.
# --------------------------------------------------------------------------
git checkout -b feature/login

cat > app.py << 'PYTHON'
# Simple greeting script

def greet():
    message = "Hello, login user!"
    print(message)

greet()
PYTHON

git add app.py
git commit -m "feature/login: customize greeting for login flow"

echo "[STEP 3] feature/login branch  ->  message = \"Hello, login user!\""

# --------------------------------------------------------------------------
# STEP 4 – Go back to main and make a DIFFERENT change to the same line
# git checkout <branch> : switches to an existing branch.
# --------------------------------------------------------------------------
git checkout main

cat > app.py << 'PYTHON'
# Simple greeting script

def greet():
    message = "Hello from main!"
    print(message)

greet()
PYTHON

git add app.py
git commit -m "main: update greeting for homepage"

echo "[STEP 4] main branch           ->  message = \"Hello from main!\""

# --------------------------------------------------------------------------
# Summary of what was built
# --------------------------------------------------------------------------
echo ""
echo "======================================================"
echo "  Demo repo is READY.  cd into it to begin:"
echo ""
echo "    cd $DEMO_DIR"
echo ""
echo "  Both branches changed the SAME LINE differently."
echo "  Run the merge to trigger the conflict:"
echo ""
echo "    git merge feature/login"
echo ""
echo "  Then follow presenter_notes.md to resolve it."
echo "======================================================"
echo ""

# Show the branch graph so you can confirm the setup looks right
git log --oneline --graph --all
