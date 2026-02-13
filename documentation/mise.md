## What is `mise`, in plain English?

**mise** (pronounced _“meez”_) is a **tool version manager and task runner** for developers.
Think of it as a **single, modern replacement** for tools like:
- `nvm` (Node versions)
- `pyenv` (Python versions)
- `asdf`
- `.env` files
- project setup docs that say “install X version Y manually”

With `mise`, a project can declare:
- _Which tools it needs_
- _Which versions_
- _Optional environment variables_
- _Common commands_

And then any developer can run **one command** and be ready.

---
## Core problems mise solves

### 1. “This project only works on Node 18…”
Mise ensures **everyone uses the same versions**, automatically.
### 2. “Onboarding takes hours”
Mise makes onboarding **repeatable and documented in code**.
### 3. “My local setup broke another project”
Mise keeps **per-project environments isolated**.
### 4. “We use 5 different version managers”
Mise **unifies them into one tool**.

---
## Common use cases for mise
### ✅ Use case 1: Language version management
Manage versions of:
- Node.js
- Python
- Ruby
- Java
- Go
- Terraform
- And many more

Per project. Automatically.

---
### ✅ Use case 2: Team consistency
Everyone on the team:
- Same Node version
- Same Python version
- Same CLI tools

No “works on my machine”.

---
### ✅ Use case 3: Project-based environments
When you `cd` into a project:
- Correct tools activate
- Environment variables load
- Wrong versions disappear

When you leave:
- Everything resets

---
### ✅ Use case 4: Simple task runner
Mise can define common commands:
- `mise run dev`
- `mise run test`
- `mise run build`
Instead of long README instructions.

---
## An invented example (end-to-end)
### The scenario
You’re on a team building **“TimeWizard”**, a web app.
**Requirements:**
- Node.js 20
- Python 3.11 (for scripts)
- A shared `DATABASE_URL`
- Easy onboarding for new devs

Without mise:

> “Install Node 20, but don’t use 21.  
> Install Python but not from the Microsoft Store.  
> Set env vars manually…”

With mise:

> “Clone repo → run `mise install` → done.”

---
## How mise works (mental model)
### 3 key ideas
1. **A config file lives in the repo**
2. **mise reads it automatically**
3. **mise activates tools per directory**

The main file is usually:
```
.mise.toml
```

This file is **the contract** between the project and the developer.

---
## Step-by-step guide: Using mise from scratch

### Step 1: Install mise
#### macOS / Linux
```bash
curl https://mise.run | sh
```
#### Windows (native)
```powershell
winget install jdx.mise
```

Then restart your terminal.

---

### Step 2: Enable shell integration (important)
This lets mise automatically activate tools when you enter a folder.
#### Bash / Zsh
```bash
eval "$(mise activate bash)"
```

#### PowerShell
```powershell
mise activate pwsh | Invoke-Expression
```

> You usually add this to your shell profile so it runs every time.

---
### Step 3: Create a project

```bash
mkdir timewizard
cd timewizard
```

Initialize mise:

```bash
mise init
```

This creates:

```
.mise.toml
```

---

### Step 4: Declare tool versions

Edit `.mise.toml`:
```toml
[tools]
node = "20"
python = "3.11"
```

That’s it.

Now install them:

```bash
mise install
```

✔ Node 20 installed  
✔ Python 3.11 installed  
✔ Scoped to this project

---
### Step 5: Verify
```bash
node -v
python --version
```
Mise ensures these versions are active **only inside this directory**.

---
### Step 6: Add environment variables
In `.mise.toml`:
```toml
[env]
DATABASE_URL = "postgres://localhost:5432/timewizard"
```
Now whenever you enter the folder:

```bash
echo $DATABASE_URL
```

It’s there.  
Leave the folder → it’s gone.

---

### Step 7: Add common tasks (optional but powerful)

```toml
[tasks.dev]
run = "npm run dev"

[tasks.test]
run = "npm test"
```

Now instead of remembering commands:

```bash
mise run dev
mise run test
```

This is **self-documenting** for the team.

---

## Daily developer workflow with mise

### Typical day

```bash
cd timewizard
```

Mise automatically:

- Activates Node 20
    
- Activates Python 3.11
    
- Loads env vars
    

You code.

You leave the directory:

```bash
cd ..
```

Mise deactivates everything.

No pollution. No conflicts.

---

## Why teams like mise (vs alternatives)

|Feature|mise|nvm|pyenv|asdf|
|---|---|---|---|---|
|Multi-language|✅|❌|❌|✅|
|Fast (Rust)|✅|❌|❌|❌|
|Tasks|✅|❌|❌|❌|
|Env vars|✅|❌|❌|❌|
|Single config file|✅|❌|❌|✅|

Mise feels like:

> **“asdf, but modern, fast, and opinionated in a good way.”**

---

## When mise is especially worth it

- Teams with **multiple languages**
    
- Repos with frequent onboarding
    
- Developers switching between many projects
    
- Companies tired of environment-related bugs
    

---
