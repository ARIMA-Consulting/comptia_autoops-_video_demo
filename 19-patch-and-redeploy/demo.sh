#!/bin/bash
# CompTIA AutoOps+ | Patch and Redeploy
# Exam Objective 4.1 — Validation and remediation: hotfixes
# Exam Objective 1.2 — Branching strategies (hotfix branching)


# ===========================================================================
# BLOCK 0 — Setup: a repo with a live bug in production
# ===========================================================================

rm -rf patch-redeploy-demo
mkdir patch-redeploy-demo
cd patch-redeploy-demo
git init -b main
git config user.name "Demo User"
git config user.email "demo@example.com"

cat > app.py << 'EOF'
def calculate_discount(price, discount_pct):
    # BUG: divides by 100 twice — returns 1/100th of the correct discount
    return price * (discount_pct / 100 / 100)

def get_final_price(price, discount_pct):
    discount = calculate_discount(price, discount_pct)
    return price - discount
EOF

cat > test_app.py << 'EOF'
from app import get_final_price

def test_10_percent_off_100():
    # $100 with 10% off should be $90
    assert get_final_price(100, 10) == 90.0

def test_25_percent_off_200():
    # $200 with 25% off should be $150
    assert get_final_price(200, 25) == 150.0
EOF

git add .
git commit -m "initial release v1.0.0"
git tag v1.0.0

echo ""
echo "--- BLOCK 0 RESULT: repo with buggy v1.0.0 on main ---"
git log --oneline


# ===========================================================================
# BLOCK 1 — Reproduce the bug (tests fail)
#
# In production someone reports: discounts are wrong.
# First step: reproduce the bug with a failing test.
# ===========================================================================

echo ""
echo "--- BLOCK 1: run tests to confirm the bug ---"
python3 -m venv venv && source venv/bin/activate
pip install pytest -q
pytest test_app.py -v || true


# ===========================================================================
# BLOCK 2 — Create a hotfix branch from the production tag
#
# Cut the hotfix from the PRODUCTION VERSION (the tag), not from whatever
# is in main — main might have unfinished work you do not want to ship.
# ===========================================================================

echo ""
echo "--- BLOCK 2: create hotfix branch from v1.0.0 ---"

git checkout -b hotfix/discount-calculation v1.0.0

echo "Now on:"
git branch --show-current


# ===========================================================================
# BLOCK 3 — Fix the bug and run tests to confirm
# ===========================================================================

echo ""
echo "--- BLOCK 3: apply the fix ---"

cat > app.py << 'EOF'
def calculate_discount(price, discount_pct):
    # FIXED: divide by 100 once to convert percentage to decimal
    return price * (discount_pct / 100)

def get_final_price(price, discount_pct):
    discount = calculate_discount(price, discount_pct)
    return price - discount
EOF

pytest test_app.py -v


# ===========================================================================
# BLOCK 4 — Commit the fix, tag it, merge back to main
#
# Hotfix gets its own patch version tag: v1.0.0 → v1.0.1
# Merge back to main so the fix is not lost in the next release.
# ===========================================================================

echo ""
echo "--- BLOCK 4: commit, tag, merge back to main ---"

git add app.py
git commit -m "fix: correct discount calculation (was dividing by 100 twice)"
git tag v1.0.1

git checkout main
git merge hotfix/discount-calculation --no-ff --no-edit
git branch -d hotfix/discount-calculation

echo ""
echo "--- BLOCK 4 RESULT: tags and commit graph ---"
git tag
git log --oneline --graph --all


# ===========================================================================
# BLOCK 5 — Redeploy
#
# In a real pipeline, tagging v1.0.1 triggers the deployment automatically.
# Here we simulate the deploy step.
# ===========================================================================

echo ""
echo "--- BLOCK 5: simulated redeploy of v1.0.1 ---"
echo "Tag v1.0.1 pushed → pipeline triggered"
echo "Tests passing ✓"
echo "Deploying v1.0.1 to production..."
python3 -c "
from app import get_final_price
print(f'  \$100 - 10% off = \${get_final_price(100, 10):.2f}  ✓')
print(f'  \$200 - 25% off = \${get_final_price(200, 25):.2f}  ✓')
print('Redeploy complete. Bug resolved.')
"

deactivate
