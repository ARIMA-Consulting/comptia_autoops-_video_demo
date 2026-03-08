#!/bin/bash
# CompTIA AutoOps+ | Branching Strategy in Practice
# Exam Objective 1.2 — Branching strategies (feature, release), branch naming conventions


# ===========================================================================
# BLOCK 0 — Setup: wipe any previous attempt, create a clean repo
# ===========================================================================

rm -rf branching-demo
mkdir branching-demo
cd branching-demo
git init -b main
git config user.name "Demo User"
git config user.email "demo@example.com"

echo "# My App" > README.md
git add README.md
git commit -m "initial commit"

echo "Repo ready. Open this folder in VS Code, then start BLOCK 1."


# ===========================================================================
# BLOCK 1 — Feature branching
#
# Feature branches isolate new work from stable code on main.
# Naming convention: feature/<short-description>
# They are created from main and merged back when the work is done.
#
# git checkout -b : create a new branch and switch to it
# git merge       : bring the feature branch commits into main
# git branch -d   : delete the branch after merging (it has served its purpose)
# ===========================================================================

git checkout -b feature/user-auth

echo "def login(user, password): pass" > auth.py
git add auth.py
git commit -m "feature/user-auth: add login function stub"

git checkout main
git merge feature/user-auth --no-ff --no-edit
git branch -d feature/user-auth

echo ""
echo "--- BLOCK 1 RESULT: feature branch created, merged, deleted ---"
git log --oneline --graph --all
git branch


# ===========================================================================
# BLOCK 2 — Release branching
#
# A release branch is a snapshot of main taken when the team is ready to ship.
# It lets you stabilize and do final fixes without blocking new feature work.
# Naming convention: release/<version>
#
# git tag : marks a specific commit with a version label
#           Tags are permanent labels — they do not move like branches do.
# ===========================================================================

git checkout -b release/v1.0

echo "VERSION = '1.0.0'" > version.py
git add version.py
git commit -m "release/v1.0: set version to 1.0.0"

git tag v1.0

git checkout main
git merge release/v1.0 --no-ff --no-edit

echo ""
echo "--- BLOCK 2 RESULT: release branch created, tagged, merged ---"
git log --oneline --graph --all
git tag


# ===========================================================================
# BLOCK 3 — Hotfix branching
#
# A hotfix branch is cut from main (not a feature branch) to patch
# a bug in production as fast as possible.
# Naming convention: hotfix/<what-you-are-fixing>
#
# The key difference from a feature branch:
#   feature/* comes from main, goes back to main after planned work
#   hotfix/*  comes from main, goes back to main urgently after a bug
# ===========================================================================

git checkout -b hotfix/fix-login-crash

echo "def login(user, password): return user is not None" > auth.py
git add auth.py
git commit -m "hotfix/fix-login-crash: prevent crash on null user"

git checkout main
git merge hotfix/fix-login-crash --no-ff --no-edit
git branch -d hotfix/fix-login-crash

echo ""
echo "--- BLOCK 3 RESULT: hotfix merged back to main ---"
git log --oneline --graph --all


# ===========================================================================
# BLOCK 4 — The full picture
#
# git branch   : lists every branch still open (deleted ones are gone)
# git log      : shows the complete history with all branch lines
# git tag      : shows every version tag
#
# Exam tip: know the three naming conventions and when each is used.
#   feature/*  = new functionality, merges to main when done
#   release/*  = version snapshot, gets a tag before merging to main
#   hotfix/*   = emergency fix, merges to main immediately
# ===========================================================================

echo ""
echo "--- Active branches ---"
git branch

echo ""
echo "--- Full commit graph ---"
git log --oneline --graph --all

echo ""
echo "--- Tags ---"
git tag
