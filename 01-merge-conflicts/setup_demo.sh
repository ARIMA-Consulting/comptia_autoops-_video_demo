#!/bin/bash
# CompTIA AutoOps+ | Topic 1: Merge Conflicts
# Exam Objective 1.4 — Git errors -> Merge conflicts
#
# PURPOSE: Builds the demo repo and creates the conflict situation.
#          Run this BEFORE recording. Students never see this part.
#
# HOW TO USE:
#   Full run   : bash setup_demo.sh
#   Step by step: copy/paste each numbered block below into your terminal.
#                 Blocks 2-4 must be run from inside merge-conflict-demo/


# ===========================================================================
# BLOCK 0 — Clean up any previous run so the demo is always fresh
# ===========================================================================

rm -rf merge-conflict-demo

echo "Old demo folder removed (or did not exist). Ready to build."


# ===========================================================================
# BLOCK 1 — Create the project folder and initialize Git
#
# mkdir            : creates the project folder
# cd               : moves into it
# git init -b main : creates the .git directory and names the branch "main"
#                    (older Git defaults to "master" — we match GitHub's default)
# git config       : sets who is making commits (required for any commit to work)
# ===========================================================================

mkdir merge-conflict-demo
cd merge-conflict-demo
git init -b main
git config user.name  "Demo User"
git config user.email "demo@example.com"

echo ""
echo "--- BLOCK 1 RESULT ---"
git status


# ===========================================================================
# BLOCK 2 — Create the starting file and commit it on main
#
# cat > app.py << 'PYTHON' ... PYTHON : writes a file using a heredoc
# git add app.py                       : stages the file (moves it to the
#                                        "ready to commit" area)
# git commit -m "..."                  : saves the staged snapshot with a message
# ===========================================================================

cat > app.py << 'PYTHON'
# Simple greeting script

def greet():
    message = "Hello"
    print(message)

greet()
PYTHON

git add app.py
git commit -m "initial commit: add greet function"

echo ""
echo "--- BLOCK 2 RESULT ---"
git log --oneline


# ===========================================================================
# BLOCK 3 — Create the feature branch and change the same line
#
# git checkout -b feature/login : creates the branch AND switches to it.
#                                  Think of branches as parallel timelines.
# Same file, same line — different value than what main will have.
# ===========================================================================

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

echo ""
echo "--- BLOCK 3 RESULT ---"
git log --oneline --graph --all


# ===========================================================================
# BLOCK 4 — Go back to main and make a DIFFERENT change to the same line
#
# git checkout main : switches back to the main branch.
# We change line 4 to something different than feature/login did.
# Same file + same line + two different values = guaranteed conflict on merge.
# ===========================================================================

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

echo ""
echo "--- BLOCK 4 RESULT: two branches diverged, same line changed differently ---"
git log --oneline --graph --all
echo ""
echo "Setup complete. Open demo_steps.sh and follow the live demo blocks."
