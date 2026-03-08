#!/bin/bash
# CompTIA AutoOps+ | Finding and Fixing Syntax Errors
# Exam Objectives 1.4 (syntax errors, undefined variable) and 2.4 (config file syntax)


# ===========================================================================
# BLOCK 0 — Setup: wipe any previous attempt, create the broken files
# ===========================================================================

rm -rf syntax-errors-demo
mkdir syntax-errors-demo
cd syntax-errors-demo

# Broken Python script — has TWO errors baked in:
#   Line 3: missing colon after if statement  (SyntaxError)
#   Line 4: uses 'user' which was never defined  (NameError — hidden until line 3 is fixed)
cat > script.py << 'EOF'
username = "admin"

if username == "admin"
    print("Welcome, " + user)
EOF

# Broken JSON config — missing comma after line 2  (JSONDecodeError)
cat > config.json << 'EOF'
{
  "environment": "production"
  "version": "1.0.0",
  "debug": false
}
EOF

echo "Files created. Open this folder in VS Code, then start BLOCK 1."
ls -1


# ===========================================================================
# BLOCK 1 — Run the broken Python script and read the error
#
# Python stops at the FIRST error it finds. The traceback tells you:
#   - which file
#   - which line number
#   - what kind of error it is
# ===========================================================================

python3 script.py


# ===========================================================================
# BLOCK 2 — Fix the SyntaxError in VS Code (add the colon on line 3),
#           then run again — a second error is now visible
#
# SyntaxError was masking a NameError underneath.
# 'user' was never defined — the variable is actually called 'username'.
# ===========================================================================

python3 script.py


# ===========================================================================
# BLOCK 3 — Fix the NameError in VS Code (change 'user' to 'username'),
#           then run again — script works
# ===========================================================================

python3 script.py


# ===========================================================================
# BLOCK 4 — Try to parse the broken JSON config
#
# python3 -m json.tool : built-in JSON validator, no installs needed.
# It prints the exact line and column where the syntax breaks.
# ===========================================================================

python3 -m json.tool config.json


# ===========================================================================
# BLOCK 5 — Fix the JSON in VS Code (add the missing comma after line 2),
#           then validate again — config parses cleanly
#
# Exam tip: always read the LINE and COLUMN number in the error output.
#           That is where Git, Python, and JSON validators all point you first.
# ===========================================================================

python3 -m json.tool config.json
