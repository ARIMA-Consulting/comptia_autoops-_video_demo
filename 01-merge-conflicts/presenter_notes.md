# Presenter Notes — Merge Conflicts
**CompTIA AutoOps+ | Exam Objective 1.4**
**Target runtime: ~3:30 | Format: screenshare + audio only**

---

## Before You Hit Record

1. Run the setup script in a clean terminal:
   ```
   bash setup_demo.sh
   cd merge-conflict-demo
   ```
2. Open VS Code in that folder:
   ```
   code .
   ```
3. Have two panes visible: **VS Code** (left) and **terminal** (right).
4. Make your terminal font size large (18–20pt) so text is readable on recording.
5. Confirm `git log --oneline --graph --all` shows two diverged branches before starting.

---

## The Conflict in Plain English (internalize this before recording)

- Both `main` and `feature/login` started from the same base commit.
- Each branch changed **line 4 of app.py** to something different.
- Git can auto-merge files that change *different* lines — but when **the same line** is changed in two branches, Git stops and says "I don't know which one to keep. You decide."
- That decision point is a **merge conflict**.

---

## Script

---

### [0:00 – 0:20] Hook + Objective

> "If you've ever worked on a team and tried to combine two people's code at the same time, you've probably hit a merge conflict. It's one of the most common Git errors — and it's on the CompTIA AutoOps+ exam under objective 1.4. In the next three and a half minutes I'm going to show you exactly how one happens and how to fix it."

---

### [0:20 – 0:50] Explain the Setup

*Point at the terminal. Run:*
```bash
git log --oneline --graph --all
```

> "Here's where we are. We have a `main` branch and a `feature/login` branch. They both started from the same initial commit — you can see them diverge right here. `main` changed the greeting to 'Hello from main!' and `feature/login` changed the same line to 'Hello, login user!' — same line, different values. This is the recipe for a conflict."

*Show `app.py` in VS Code. Point out line 4.*

> "Both branches touched line 4. That's the problem. Watch what happens when we try to merge."

---

### [0:50 – 1:20] Trigger the Conflict

*In terminal, make sure you're on main:*
```bash
git status
```

> "We're on main. Now let's pull in the feature branch."

```bash
git merge feature/login
```

**Expected output:**
```
Auto-merging app.py
CONFLICT (content): Merge conflict in app.py
Automatic merge failed; fix conflicts and then commit the result.
```

> "There it is. Git tells us exactly which file has the problem: `app.py`. It cannot finish the merge on its own. It's waiting for us."

---

### [1:20 – 2:00] Read the Conflict Markers

*Click on `app.py` in VS Code. The conflict will be highlighted.*

> "VS Code shows us the conflict in color. Let me also look at the raw text so you can see what Git actually wrote."

*In terminal:*
```bash
cat app.py
```

**What students will see:**
```python
# Simple greeting script

def greet():
<<<<<<< HEAD
    message = "Hello from main!"
=======
    message = "Hello, login user!"
>>>>>>> feature/login
    print(message)

greet()
```

> "Git inserted three markers:"
>
> - `<<<<<<< HEAD` — everything below this is what YOUR current branch (`main`) had.
> - `=======` — the dividing line between the two versions.
> - `>>>>>>> feature/login` — everything above this is what the incoming branch had.
>
> "Your job is to delete the markers and keep whichever version is correct — or combine them if you need both."

---

### [2:00 – 2:40] Resolve the Conflict

> "For this demo, let's say the team decided the final message should be 'Hello, World!' — a clean merge of both ideas. I'll edit this in VS Code."

*Click into VS Code. Manually delete the conflict markers and edit so the file reads:*

```python
# Simple greeting script

def greet():
    message = "Hello, World!"
    print(message)

greet()
```

> "I deleted the `<<<<<<<`, `=======`, and `>>>>>>>` lines entirely — they are NOT code, they are Git bookmarks. Then I wrote the resolved value. The file must be valid Python when I'm done."

---

### [2:40 – 3:10] Complete the Merge

*Back in terminal:*
```bash
git add app.py
```

> "`git add` tells Git: I resolved this file, include it in the final merge commit."

```bash
git commit -m "resolve merge conflict: use Hello, World! greeting"
```

> "`git commit` seals the deal. Git now has a **merge commit** — a special commit that has TWO parents: one from main and one from feature/login."

```bash
git log --oneline --graph --all
```

> "Look at that graph. The two branches have been joined back into one line. The conflict is gone, the history is clean, and both sides of the work are preserved."

---

### [3:10 – 3:30] Exam Tip + Wrap-Up

> "Before I go — two things that show up on the CompTIA exam:"
>
> 1. **`git mergetool`** — Git's built-in command to open a visual diff editor. Examiners love asking about this as an alternative to editing manually.
> 2. **VS Code's built-in merge UI** — those 'Accept Current Change / Accept Incoming Change' buttons you saw are the GUI equivalent of what we just did in the terminal.
>
> "The pattern is always the same: conflict markers appear, you remove them and keep the right code, then `git add` and `git commit`. That's it."
>
> "Next up: Finding and Fixing Syntax Errors."

---

## Every Git Command Used — With Explanations for Students

| Command | What it does | Why it matters |
|---|---|---|
| `git init` | Turns a folder into a Git repository | Creates the `.git` directory that tracks all history |
| `git config user.name` / `user.email` | Sets your identity for this repo | Every commit is stamped with who made it |
| `git add <file>` | Stages a file — moves it to the "ready to commit" area | Git has a two-step save: stage first, then commit |
| `git add .` | Stages ALL changed files at once | Shortcut for multi-file projects |
| `git commit -m "message"` | Saves staged changes as a permanent snapshot | The message should describe *why*, not just *what* |
| `git checkout -b <name>` | Creates a new branch AND switches to it | `-b` = "branch new"; without it you'd get an error |
| `git checkout <branch>` | Switches to an existing branch | Changes your working files to match that branch |
| `git merge <branch>` | Brings another branch's commits into your current branch | This is what triggers conflicts when lines collide |
| `git status` | Shows what branch you're on and what files are changed | Use this constantly — it's your GPS |
| `git log --oneline --graph --all` | Draws an ASCII graph of all branches and commits | Essential for visualizing what happened |

---

## If Something Goes Wrong During the Demo

**Already committed the conflict markers by accident?**
```bash
git reset HEAD~1
```
This un-commits the last commit but keeps your files. Fix the file, then `git add` and `git commit` again.

**Want to abort the merge entirely and start over?**
```bash
git merge --abort
```
Returns both branches to exactly where they were before `git merge` was run.

**Re-run the whole demo from scratch:**
```bash
cd ..
bash setup_demo.sh
cd merge-conflict-demo
```

---

## Exam Objective Cross-Reference

| Exam Objective | How This Demo Covers It |
|---|---|
| **1.4** — Git errors → Merge conflicts | Full conflict creation, conflict marker reading, and resolution |
| **1.2** — Git commands (local: `git add`, `git commit`) | Used throughout to stage and commit |
| **1.2** — Branching strategies → Feature branching | `feature/login` branch is a textbook feature branch |
| **1.2** — Commit life cycle | Students see the full path from change → stage → commit |
