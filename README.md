# Useful Dev Skills

A collection of [Claude Code](https://claude.com/claude-code) skills for day-to-day software engineering. Each skill is a drop-in directory with a `SKILL.md` that Claude reads progressively — metadata stays in context, body loads when the skill fires, bundled scripts and references load on demand.

## Installation

### ⭐ Star this repo first

If you find these skills useful, please **star the repo** before installing. It takes one click, helps others discover the collection, and is the main signal I use to decide what to build next.

> Not starred yet? → [click the ⭐ at the top of the page](https://github.com/slark-prime/Useful-Dev-Skills/stargazers) ← thanks!

### Install a skill

Skills live under `~/.claude/skills/<skill-name>/`. Clone the repo and copy the skills you want:

```bash
git clone https://github.com/slark-prime/Useful-Dev-Skills.git
mkdir -p ~/.claude/skills
cp -r Useful-Dev-Skills/multi-agent-worktrees ~/.claude/skills/
```

Restart Claude Code (or start a new conversation) and the skill is live. Confirm with `/help` — it should show up in the available skills list.

To install every skill in this repo:

```bash
for dir in Useful-Dev-Skills/*/; do
  name=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] && cp -r "$dir" ~/.claude/skills/
done
```

## Skills

### [`multi-agent-worktrees`](./multi-agent-worktrees/)

Prevents git `.git` checkout collisions when multiple coding agents (or humans) work on the same repo in parallel. Fires **before** feature implementation begins, runs a 1-second concurrency check, and then:

- **Concurrency signal present** (other worktrees exist, recent commits on other branches, user mentions parallel work, or cwd is already a linked worktree) → enforces the SOP: new branch, sibling worktree directory, registry entry.
- **No signal** → one-line note, proceeds on the current branch. No ceremony imposed.

**Benchmark** (1 iteration, 4 test cases, 1 run each):

| Metric | With Skill | Baseline | Delta |
|---|---|---|---|
| Pass rate | 100% (18/18) | 74% (13/18) | **+26 pp** |
| Wall time | 114s ± 31 | 103s ± 48 | +11s |
| Tokens | 29.8k ± 3.4k | 25.3k ± 5.7k | +4.5k |

Biggest win: catching user-phrase signals (e.g. "have another agent do X in parallel") that a baseline agent otherwise ignores. See [`multi-agent-worktrees/SKILL.md`](./multi-agent-worktrees/SKILL.md) for the full decision tree.

## Contributing

Issues and PRs welcome. If you add a skill:

1. Put it under a top-level directory with a `SKILL.md` at its root.
2. Include evals if the skill has objectively verifiable outputs (test prompts + setup scripts under `evals/`).
3. Update this README's **Skills** section with a one-paragraph summary and a link.

## License

MIT — see [LICENSE](./LICENSE).
