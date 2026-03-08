#!/bin/bash
# CompTIA AutoOps+ | Topic 1: Merge Conflicts — LIVE DEMO STEPS
# Exam Objective 1.4 — Git errors -> Merge conflicts
#
# PURPOSE: These are the commands you paste live on camera.
#          Run setup_demo.sh first, then cd into merge-conflict-demo/.
#
# HOW TO USE:
#   Step by step: paste each numbered block into your terminal one at a time.
#   Full run    : bash demo_steps.sh  (auto-resolves so the script completes)
#
# NOTE: In "step by step" mode, BLOCK 7 requires you to edit app.py in
#       VS Code first. In full-run mode the script writes the resolved
#       file for you automatically — same end result either way.


# ===========================================================================
# BLOCK 5 — Trigger the conflict
#
# git merge feature/login : tries to bring feature/login into main.
#                           Git cannot auto-resolve line 4 because both
#                           branches changed it differently. It stops and
#                           writes conflict markers into the file instead.
# ===========================================================================

git merge feature/login

echo ""
echo "--- BLOCK 5 RESULT ---"
git status


# ===========================================================================
# BLOCK 6 — Read what Git wrote inside the file
#
# cat app.py : prints the raw file so you can see the conflict markers:
#
#   <<<<<<< HEAD            = what YOUR current branch (main) had
#   =======                 = the dividing line between the two versions
#   >>>>>>> feature/login   = what the incoming branch had
#
# These markers are NOT code. Delete all three lines when you resolve.
# ===========================================================================

cat app.py


# ===========================================================================
# BLOCK 7 — Resolve the conflict, then complete the merge
#
# STEP BY STEP: Open app.py in VS Code, delete the three marker lines,
#               and set:  message = "Hello, World!"
#               Then paste just the git add and git commit lines below.
#
# FULL SCRIPT:  The cat heredoc below writes the resolved file automatically.
#               Remove it if you are pasting this block live on camera.
#
# git add app.py   : tells Git "this file is resolved, include it in the merge"
# git commit       : seals the merge — creates a commit with TWO parents
# ===========================================================================

# -- For full-script run only: write the resolved file --
cat > app.py << 'PYTHON'
# Simple greeting script

def greet():
    message = "Hello, World!"
    print(message)

greet()
PYTHON

# -- Always paste these two lines after editing --
git add app.py
git commit -m "resolve merge conflict: use Hello, World! greeting"

echo ""
echo "--- BLOCK 7 RESULT: final clean graph ---"
git log --oneline --graph --all
