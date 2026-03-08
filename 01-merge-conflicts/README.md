# Merge Conflicts
**CompTIA AutoOps+ AT0-001 | Video Demo 1 of 23**

---

## Exam Objective
**1.4** — Given a scenario, troubleshoot common issues with the code life cycle
→ Git errors → **Merge conflicts**

---

## What This Demo Shows

A merge conflict happens when two branches change the **same line** of the same file. Git cannot decide which version to keep, so it stops and marks the conflict inside the file using special markers. This demo walks through:

1. Creating a conflict (two branches, same line, different values)
2. Reading the conflict markers Git inserts
3. Resolving the conflict manually
4. Completing the merge with `git add` and `git commit`
5. Verifying a clean history with `git log --graph`

---

## Files

| File | Purpose |
|---|---|
| `setup_demo.sh` | Builds the demo repo with the conflict ready to trigger |
| `presenter_notes.md` | Full script with timing, commands, explanations, and exam tips |

---

## Quick Start

```bash
# 1. Run the setup script
bash setup_demo.sh

# 2. Move into the demo repo
cd merge-conflict-demo

# 3. Open in VS Code (optional but recommended for visual conflict view)
code .

# 4. Trigger the conflict
git merge feature/login

# 5. Follow presenter_notes.md to resolve it
```

---

## Prerequisites

- Git installed (`git --version`)
- VS Code installed (optional — conflict is also visible in the terminal)
- No GitHub account needed — this is 100% local

---

## Key Takeaways for Students

- Conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) are NOT code — delete them
- After resolving: `git add <file>` → `git commit`
- `git merge --abort` cancels the merge if you want to start over
- `git mergetool` opens a visual diff editor (common exam topic)
