# Platform Notes — Setting up a Coding Workstation
**For students following along on Windows or macOS**

The demo video is recorded on Ubuntu Linux. Every command below does the
exact same thing — only the syntax changes per platform.

---

## Installing Python

### Ubuntu / Linux
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```
Verify:
```bash
python3 --version
pip3 --version
```

### macOS
Option 1 — Homebrew (recommended):
```bash
brew install python
```
Option 2 — Download the installer from [python.org](https://python.org/downloads)

Verify:
```bash
python3 --version
pip3 --version
```

### Windows
Option 1 — winget (built into Windows 10/11):
```powershell
winget install Python.Python.3
```
Option 2 — Download the installer from [python.org](https://python.org/downloads)
  - Check **"Add Python to PATH"** during install — without this nothing works

Verify (in PowerShell or Command Prompt):
```powershell
python --version
pip --version
```
> Windows uses `python` and `pip`, not `python3` and `pip3`.

---

## Creating and Activating a Virtual Environment

### Ubuntu / macOS
```bash
python3 -m venv venv
source venv/bin/activate
```
Your prompt changes to `(venv)` when it is active.

### Windows — Command Prompt
```cmd
python -m venv venv
venv\Scripts\activate
```

### Windows — PowerShell
```powershell
python -m venv venv
venv\Scripts\Activate.ps1
```
If you get a permissions error on the Activate.ps1 line, run this once first:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Installing from requirements.txt

Same command on all platforms once the venv is active:
```bash
pip install -r requirements.txt
```

---

## Locking Exact Versions

Same on all platforms:
```bash
pip freeze > requirements.txt
```
This overwrites requirements.txt with the exact installed versions (e.g. `requests==2.31.0`).
Commit this file to git so teammates and CI/CD pipelines get identical environments.

---

## Deactivating the Virtual Environment

Same on all platforms:
```bash
deactivate
```

---

## Quick Reference — Command Differences by Platform

| Action | Linux / macOS | Windows |
|---|---|---|
| Run Python | `python3` | `python` |
| Run pip | `pip3` or `pip` (in venv) | `pip` |
| Create venv | `python3 -m venv venv` | `python -m venv venv` |
| Activate venv | `source venv/bin/activate` | `venv\Scripts\activate` |
| Deactivate venv | `deactivate` | `deactivate` |

---

## Installing Git

### Ubuntu / Linux
```bash
sudo apt install git
git --version
```

### macOS
```bash
brew install git
```
Or install Xcode Command Line Tools:
```bash
xcode-select --install
```

### Windows
Download from [git-scm.com](https://git-scm.com/download/win) or:
```powershell
winget install Git.Git
```

---

## Setting up VS Code or Cursor

1. Download from [code.visualstudio.com](https://code.visualstudio.com) or [cursor.com](https://cursor.com)
2. Install the **Python** extension (search "Python" in the Extensions panel)
3. Open your project folder: `code .` or `cursor .` from the terminal
4. Select your interpreter: `Ctrl+Shift+P` → **Python: Select Interpreter** → choose the `venv` version

> In Cursor, the AI bar (Ctrl+L or Cmd+L) lets you ask questions about your code
> directly in the editor without leaving the workstation.
