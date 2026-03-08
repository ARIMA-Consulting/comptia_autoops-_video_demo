#!/bin/bash
# CompTIA AutoOps+ | Setting up a Coding Workstation
# Exam Objective 1.1 — Dependency management: requirements.txt, packages, libraries
#
# Demoed on Ubuntu/Linux. See platform-notes.md for Windows and macOS translations.


# ===========================================================================
# BLOCK 0 — Cleanup: remove any previous attempt
# ===========================================================================

rm -rf workstation-demo
mkdir workstation-demo
cd workstation-demo

echo "Clean project folder ready."


# ===========================================================================
# BLOCK 1 — Confirm Python is installed and check the version
#
# You cannot use a tool you haven't installed.
# Always verify the version — some systems have Python 2 and Python 3 both,
# and they are not interchangeable.
# ===========================================================================

python3 --version
pip3 --version


# ===========================================================================
# BLOCK 2 — Create a virtual environment
#
# python3 -m venv venv : creates an isolated Python environment in a folder
#                        called "venv". Packages installed here do NOT affect
#                        the rest of your system.
#
# source venv/bin/activate : activates the environment. After this, "python"
#                            and "pip" point to the venv versions, not system ones.
#
# Your terminal prompt will change to show (venv) when it is active.
# ===========================================================================

python3 -m venv venv
source venv/bin/activate

echo ""
echo "Active Python:"
which python
python --version


# ===========================================================================
# BLOCK 3 — Create requirements.txt and install the packages
#
# requirements.txt lists every package your project needs and their versions.
# This file is how you share dependencies with teammates and CI/CD pipelines —
# anyone can reproduce your exact environment with one command.
#
# pip install -r requirements.txt : reads the file and installs everything in it.
# ===========================================================================

cat > requirements.txt << 'EOF'
requests
pyyaml
python-dotenv
EOF

cat requirements.txt

pip install -r requirements.txt


# ===========================================================================
# BLOCK 4 — Verify what was installed
#
# pip list  : shows every package installed in the current environment.
# pip freeze > requirements.txt : captures exact installed versions back into
#                                 the file — useful for locking a known-good state.
# ===========================================================================

echo ""
echo "--- Installed packages ---"
pip list

echo ""
echo "--- Lock exact versions into requirements.txt ---"
pip freeze > requirements.txt
cat requirements.txt


# ===========================================================================
# BLOCK 5 — Write a small script that uses the installed packages
#           to prove the environment actually works
# ===========================================================================

cat > verify.py << 'EOF'
import requests
import yaml
from dotenv import dotenv_values

print("requests version :", requests.__version__)
print("pyyaml  version  :", yaml.__version__)
print("All packages imported successfully.")
EOF

python verify.py


# ===========================================================================
# BLOCK 6 — Deactivate when done
#
# deactivate : exits the virtual environment and returns your terminal
#              to the system Python. Always deactivate before switching projects.
# ===========================================================================

deactivate

echo ""
echo "Venv deactivated. Active Python is now system Python:"
which python3
