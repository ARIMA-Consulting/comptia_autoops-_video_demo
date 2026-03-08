#!/bin/bash
# CompTIA AutoOps+ | Merge Conflicts
# Exam Objective 1.4 — Git errors -> Merge conflicts


# ===========================================================================
# BLOCK 0 — Setup: wipe any previous attempt and create a fresh repo
# ===========================================================================

rm -rf merge-conflict-demo
mkdir merge-conflict-demo
cd merge-conflict-demo
git init -b main
git config user.name "Demo User"
git config user.email "demo@example.com"


# ===========================================================================
# BLOCK 1 — Write the first version of the code and commit it on main,
#           then create a feature branch and commit a different version
#
# git checkout -b : creates a new branch and switches to it in one step
# git add         : stages the file (queues it up for the next commit)
# git commit      : saves the staged snapshot permanently with a message
# ===========================================================================

cat > app.py << 'EOF'
def greet():
    message = "Hello"
    print(message)

greet()
EOF

git add app.py
git commit -m "initial commit: add greet function"

git checkout -b feature/login

cat > app.py << 'EOF'
def greet():
    message = "Hello, login user!"
    print(message)

greet()
EOF

git add app.py
git commit -m "feature/login: customize greeting"

git log --oneline --graph --all


# ===========================================================================
# BLOCK 2 — Switch back to main and commit a different change to the same line
#
# git checkout main : switches back to the main branch
# Both branches now have a different value on the same line — this is what
# causes Git to stop and ask us to decide which version to keep.
# ===========================================================================

git checkout main

cat > app.py << 'EOF'
def greet():
    message = "Hello from main!"
    print(message)

greet()
EOF

git add app.py
git commit -m "main: update greeting for homepage"

git log --oneline --graph --all


# ===========================================================================
# BLOCK 3 — Attempt the merge and trigger the conflict
#
# git merge feature/login : tries to combine feature/login into main.
#                           Git can merge lines that changed in different spots,
#                           but when the SAME line has two different values it
#                           stops and marks both versions inside the file.
# ===========================================================================

git merge feature/login

git status


# ===========================================================================
# BLOCK 4 — Read the conflict markers Git wrote into the file
#
# <<<<<<< HEAD           = what your current branch (main) has
# =======                = the dividing line
# >>>>>>> feature/login  = what the incoming branch has
#
# These markers are not code. You delete all three and keep what you want.
# ===========================================================================

cat app.py


# ===========================================================================
# BLOCK 5 — Resolve the conflict in VS Code, then complete the merge
#
# Open app.py, delete the three marker lines, set message = "Hello, World!"
#
# git add app.py : marks the file as resolved
# git commit     : creates the merge commit (it will have two parents)
# ===========================================================================

git add app.py
git commit -m "resolve merge conflict: use Hello, World! greeting"

git log --oneline --graph --all
