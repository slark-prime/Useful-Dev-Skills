---
name: multi-agent-worktrees
description: Set up git worktree isolation before implementing a feature so parallel coding agents on the same repo never collide on `.git` checkouts. FIRE on any feature-implementation request ("implement X", "add feature Y", "build Z", "refactor A", "wire up B", substantive bug fixes, migration work, scaffolding new modules). The skill runs a 1-second concurrency check first; if no parallel work is happening, it notes the SOP and proceeds on the current branch — no ceremony imposed. If concurrency signals are present (other worktrees, recent commits on other branches, explicit multi-agent framing, or running inside a linked worktree already), it enforces the SOP: new branch, new sibling worktree directory, registry entry. Trigger liberally — the no-op path is cheap.
---

# multi-agent-worktrees

Keep feature work isolated so multiple coding agents (or humans) on the same repo do not step on each other's checkouts. One agent → one worktree → one branch → one directory.

This skill fires **before** feature implementation begins. It makes an adaptive call:

- **Concurrency signal present** → enforce the full SOP (new worktree, new branch).
- **No signal** → one-line note, proceed on current branch. The SOP exists; ceremony is not imposed when there's no collision risk.

## When this skill fires

Treat any of these as a feature-implementation request that triggers the skill:

- "Implement / add / build / create / scaffold / set up [something non-trivial]"
- "Refactor / migrate / rewrite [module / subsystem]"
- "Wire up / integrate / introduce [new concept]"
- Multi-file fixes, bug fixes that touch > ~1 file or add code paths
- Any task that would naturally produce a PR

Do **not** fire for: read-only questions, explain-this-code, typo fixes, single-line comment edits, file renames without behavior changes. If the user's ask would realistically be a one-commit fix on whatever branch is already checked out, skip the skill.

## Step 1 — Concurrency check

Run these in one batch. They should take under a second together.

```bash
# Are there other worktrees on this repo already?
git worktree list

# Who/what has been active across branches recently?
git log --all --since='2 hours' --format='%an|%cr|%D' | head -20

# Is the current cwd already a linked worktree (not the main checkout)?
if [ "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" ]; then
  echo "CWD: main checkout"
else
  echo "CWD: already in a linked worktree"
fi

# Multi-agent marker declared by the repo?
test -f .claude/multi-agent.yaml && echo "marker: multi-agent.yaml present"
grep -l -i "multi-agent" CLAUDE.md 2>/dev/null
```

Also scan the **user's own recent messages** for explicit signals:

- "another agent", "parallel", "teammate is on X", "I'll have someone else do Y", "split this", "in parallel", "while you work on Z"
- A paste of a `.git` checkout-collision error (`fatal: '…' is already checked out at …`)

## Step 2 — Decide

| Observation | Action |
|---|---|
| `git worktree list` shows only the main checkout, no recent multi-branch commits, no user signals, cwd is main | **No signal.** Output one line: *"Single-agent signals only — proceeding on current branch. Worktree SOP is available if parallelism becomes relevant."* Then continue with the task normally. |
| CWD is already a linked worktree | **Already isolated.** Do *not* create a nested worktree. Work in place. Note the existing branch. |
| Any other signal present | **Enforce SOP** (Step 3+). |

The no-signal path is the common case. It is fine. Claude should not treat it as a failure to "properly use" the skill — the skill's whole job is to make this call cheap.

## Step 3 — Propose the worktree plan

Before creating anything, show the user:

- **Branch name.** Slug from their task. Examples: `feat/oauth-notion`, `fix/webhook-retry`, `refactor/chat-streaming`. Keep the prefix conventional for the repo (check `git log --oneline | head -20` for established style).
- **Worktree path.** Sibling to the main checkout, with a short descriptive suffix:
  ```
  <parent>/<repo>/              # main checkout
  <parent>/<repo>-<slug>/       # this worktree
  ```
  Example: if the repo is at `/Users/you/projects/hachimi/`, the worktree for `feat/oauth-notion` goes to `/Users/you/projects/hachimi-oauth-notion/`.
- **Base branch.** The repo's default branch (usually `main` or `master`), resolved via `git symbolic-ref refs/remotes/origin/HEAD` or by checking what the user last diverged from.

Ask once, briefly:

> *Setting up an isolated worktree for this: branch `feat/oauth-notion`, path `../hachimi-oauth-notion`, based on `origin/master`. Go?*

If the user has already indicated they want the SOP applied (explicit framing, prior sign-off this session), skip the confirmation.

## Step 4 — Create the worktree

```bash
# From the main checkout
cd <path-to-main-checkout>
git fetch origin --prune
git worktree add -b <branch-name> <worktree-path> origin/<base-branch>
```

Append a registry entry so future sessions can see what's active:

```bash
mkdir -p ~/.claude/worktrees
REG=~/.claude/worktrees/registry.json
# (read-modify-write with jq or a tiny inline script; create {"entries": []} if missing)
```

Entry shape:

```json
{
  "branch": "feat/oauth-notion",
  "path": "/Users/you/projects/hachimi-oauth-notion",
  "base": "origin/master",
  "base_commit": "<sha>",
  "created_at": "2026-04-19T18:00:00Z",
  "session_id": "<claude session id if available>",
  "task_summary": "Short description of what this worktree is for",
  "status": "active"
}
```

The registry is **advisory**, not authoritative — `git worktree list` is the ground truth. The registry's purpose is human-readable task summaries and session attribution, which `git worktree list` doesn't provide.

## Step 5 — Work in the new worktree

From this point, all edits, commits, and tool calls happen in the new worktree path. Switch cwd:

```bash
cd <worktree-path>
```

Inside the worktree: edit, test, commit, push. Use the branch name as conventional.

Do **not**:

- `git switch` or `git checkout` to a different branch inside this worktree — the branch is pinned for this task.
- Edit files in the main checkout while this worktree is active on another branch.
- Create a nested worktree inside this one.
- Reassign this worktree to a different task midway. If the task changes, clean this worktree up and create a new one.

If dependencies need to be installed (e.g., `pnpm install`, `uv sync`), do it once per worktree. `node_modules` is per-directory; that's the cost.

## Step 6 — Handoff

Agent's responsibility ends at **"branch ready for review"**:

1. Commit all pending changes.
2. Push the branch: `git push -u origin <branch-name>`.
3. Report to user: branch name, path, PR URL (if opened), one-line status.
4. Update registry `status: "ready_for_review"`.

Merging, rebasing, combining, or discarding is the user's decision, not the agent's.

## Step 7 — Cleanup (when user says done)

```bash
cd <main-checkout>
git worktree remove <worktree-path>
git worktree prune
# optionally: git branch -d <branch> after merge
```

Update registry `status: "done"` (or remove the entry).

## Guardrails

- **One branch in one worktree.** Git refuses to check out a branch that's already checked out in another worktree. Do not override with `--ignore-other-worktrees` or `--force` — that safeguard exists because two active checkouts of the same branch create ownership ambiguity.
- **Two agents on the same initiative** → separate branches (e.g., `feat/search-rewrite-part-a`, `feat/search-rewrite-part-b`). Never the same branch.
- **Uncommitted work on the main checkout** before creating a worktree is fine (worktrees don't affect it), but note it to the user so they don't lose track.
- If `git fetch` fails (offline), still proceed — use the local `origin/<base>` ref.

## Rationale (why this shape)

- Worktrees give per-directory `HEAD` and `index`. Two agents can `commit` simultaneously without race conditions on the index file. That's the collision this prevents.
- Sibling directory layout (vs. nested `.worktrees/` or a central `/worktrees/project/`) keeps paths short and matches the pattern most dev tooling already expects. It's what shows up naturally when you tab-complete from the parent directory.
- Adaptive firing (signal-based) keeps the skill universal without imposing overhead on single-agent sessions. If Claude enforces the full SOP every single time, users disable the skill out of frustration — and then it's not there for the cases that actually need it.
- Agents stop at "branch ready." Merge decisions require context (who owns what, release timing, conflicts with parallel work) that an agent shouldn't unilaterally resolve.

## Quick reference

```bash
# Create
cd <main>
git fetch origin --prune
git worktree add -b feat/slug ../<repo>-slug origin/<base>
cd ../<repo>-slug

# List
git worktree list

# Remove
cd <main>
git worktree remove ../<repo>-slug
git worktree prune
```
