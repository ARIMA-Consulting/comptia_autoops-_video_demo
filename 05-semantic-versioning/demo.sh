#!/bin/bash
# CompTIA AutoOps+ | Semantic Versioning Explained Visually
# Exam Objective 1.2 — Semantic versioning: MAJOR.MINOR.PATCH, pre-release, filtering


# ===========================================================================
# BLOCK 0 — Setup
# ===========================================================================

rm -rf semver-demo
mkdir semver-demo
cd semver-demo
git init -b main
git config user.name "Demo User"
git config user.email "demo@example.com"

echo "# My App" > README.md
git add README.md
git commit -m "initial commit"
echo "Repo ready."


# ===========================================================================
# BLOCK 1 — The format: MAJOR.MINOR.PATCH
#
# MAJOR : breaking change — callers must update their code
# MINOR : new feature added, backwards compatible
# PATCH : bug fix, no new features
#
# git tag <name>         : creates a lightweight tag on the current commit
# git tag -a <name> -m   : creates an annotated tag (stores message + author)
# ===========================================================================

# Patch releases — bug fixes only
echo "v1 code" > app.py
git add app.py && git commit -m "fix: correct null pointer on startup"
git tag -a v1.0.1 -m "patch: fix null pointer"

echo "v1 update" >> app.py
git add app.py && git commit -m "fix: handle empty config file"
git tag -a v1.0.2 -m "patch: handle empty config"

# Minor release — new feature, nothing breaks
echo "def new_feature(): pass" >> app.py
git add app.py && git commit -m "feat: add new_feature function"
git tag -a v1.1.0 -m "minor: new_feature added"

# Major release — breaking change, callers must adapt
echo "# v2 — breaking API change" > app.py
git add app.py && git commit -m "feat!: redesign public API (breaking)"
git tag -a v2.0.0 -m "major: breaking API redesign"

echo ""
echo "--- BLOCK 1 RESULT: all tags ---"
git tag


# ===========================================================================
# BLOCK 2 — Pre-release versions
#
# Pre-release labels come AFTER the version number with a hyphen:
#   v2.1.0-alpha.1   = early internal build
#   v2.1.0-beta.1    = external testing
#   v2.1.0-rc.1      = release candidate — almost ready to ship
#
# Pre-release versions sort BEFORE the release: v2.1.0-beta.1 < v2.1.0
# ===========================================================================

echo "alpha build" >> app.py
git add app.py && git commit -m "wip: start v2.1.0 alpha"
git tag -a v2.1.0-alpha.1 -m "pre-release: first alpha"

echo "beta build" >> app.py
git add app.py && git commit -m "fix: beta stabilization"
git tag -a v2.1.0-beta.1 -m "pre-release: first beta"

echo "rc build" >> app.py
git add app.py && git commit -m "fix: release candidate polish"
git tag -a v2.1.0-rc.1 -m "pre-release: release candidate 1"

echo "final v2.1.0" >> app.py
git add app.py && git commit -m "release: v2.1.0 stable"
git tag -a v2.1.0 -m "stable release v2.1.0"

echo ""
echo "--- BLOCK 2 RESULT: all tags in order ---"
git tag --sort=version:refname


# ===========================================================================
# BLOCK 3 — Filtering techniques
#
# git tag -l "pattern" : list only tags matching the pattern
# Useful in CI/CD to trigger pipelines only on specific version types.
# ===========================================================================

echo ""
echo "--- Only v1.x.x tags ---"
git tag -l "v1.*"

echo ""
echo "--- Only v2.x.x tags ---"
git tag -l "v2.*"

echo ""
echo "--- Only pre-release tags ---"
git tag -l "*-*"

echo ""
echo "--- Only stable (no pre-release) tags ---"
git tag --sort=version:refname | grep -v '-'


# ===========================================================================
# BLOCK 4 — Inspect a specific tag and see the commit graph
#
# git show <tag>           : displays the tag message and the tagged commit
# git log --oneline --decorate : shows which commits have tags attached
# ===========================================================================

echo ""
echo "--- Show v2.0.0 tag details ---"
git show v2.0.0 --quiet

echo ""
echo "--- Full graph with tags ---"
git log --oneline --decorate --graph
