# issue-loop

A Claude Code plugin that makes GitHub issues the queue for coding agents.

You write a one-line request — from the terminal, or as an issue from your
phone. An agent turns it into an issue another agent can solve. A solver agent
claims the issue with a draft pull request, works in its own git worktree,
pushes every step, asks on the issue when a choice is yours, runs the
project's gate, and hands back a green, ready-for-review PR. You review and
merge. It never merges, never bumps a version, and never publishes.

Everything is in GitHub: the issue thread is the conversation, the draft PR is
the state. A session that dies loses only the step it was on, and the next one
resumes from the draft.

## The loop

```
  "the export button does nothing on Safari"
        │  /issues <request>
        ▼
  issue-writer (sonnet, read-only, ~5 min)
        │  files an issue: Problem · Where · Done when · Test plan
        ▼
  [agent-ready] ──── /issues (one pass, or /loop /issues) ────┐
                                                              ▼
                                         issue-solver (opus)
                                           1. push branch issue-<N>   ← the lock
                                           2. open a draft PR (Session · Plan · Progress)
                                           3. label agent-working
                                           4. commit + push each step in a worktree
        ┌────────── unsure about a choice you would notice ───┤
        ▼                                                     │
  [agent-question]  asks on the issue, stops                  │
        │  you reply on the issue                             │
        └──► [agent-ready] → a solver resumes from the draft  │
                                                              ▼
                                           5. run the project's gate
                                           6. PR ready, CI watched in the background
                                                              │
                                                              ▼
                                         [agent-pr]  you review and merge
                                           review comments → a solver addresses them
```

## Install

Inside Claude Code:

```
/plugin marketplace add flolep2607/claude-issue-loop
/plugin install issue-loop@claude-issue-loop
```

Or from a shell:

```bash
claude plugin marketplace add flolep2607/claude-issue-loop
claude plugin install issue-loop@claude-issue-loop
```

Update later with `claude plugin update issue-loop@claude-issue-loop`.

Requirements: `git` (2.32+), and the GitHub CLI `gh`, authenticated with write
access to the repository.

## Set up a project

In the project's directory, start Claude Code and run:

```
/issue-loop:setup
```

It looks first, shows what it would do, and asks before writing anything:

- **Labels** — creates the four labels below with `gh label create --force`.
- **Issue forms and PR template** (optional) — copies `bug.yml`, `idea.yml`,
  `config.yml` and `pull_request_template.md` into `.github/`, skipping any
  file that already exists unless you name it.
- **Git hooks** (optional) — see [Git hooks](#git-hooks). It checks for an
  existing `core.hooksPath`, husky, lefthook or pre-commit and never replaces
  their hooks.
- **Settings** — writes a commented `.claude/issue-loop.md`.

Nothing is committed; you decide what to commit.

## Use

| command | what it does |
|---|---|
| `/issues <request>` | files an issue from a one-line request (one writer per request, in parallel) |
| `/issues` | one pass over the queue: starts solvers, resumes answered questions, sends review comments back |
| `/loop /issues` | keeps the queue moving; passes are self-paced, about every 20 minutes when idle |

The skills are also reachable by their full names, `/issue-loop:issues` and
`/issue-loop:setup` (use the full name if another `/issues` command exists).
The agents are `issue-loop:issue-writer` and `issue-loop:issue-solver`; you can
also ask for one directly ("solve #42 with the issue-solver").

You can file issues anywhere — the GitHub app included. Add the `agent-ready`
label when an issue says enough for an agent to act on it without asking.

## Labels

| label | meaning | moved on by |
|---|---|---|
| `agent-ready` | written and waiting for a solver | the loop |
| `agent-working` | a solver has it, with a draft PR from `issue-<N>` | the solver |
| `agent-question` | the solver asked on the issue and stopped | your reply |
| `agent-pr` | the PR is ready for review, CI watched | you: merge, or review comments |

Agent comments end with the marker `<!-- issue-loop-agent -->`. Agents post
under your own `gh` account, so the marker is how the loop tells their text
from yours; your comments outrank the issue body.

## Configuration

The project's own instructions decide. The agents read, in order:

1. `.claude/issue-loop.md`, if present;
2. `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`;
3. the CI workflows, for the gate when nothing above names one.

From those they take the gate (build, lint, test commands, run as CI runs
them), commit conventions, PR title rules, and anything that must not be run.

`.claude/issue-loop.md` is optional. Its front matter overrides the defaults;
its body is free-form notes for the agents:

```markdown
---
base: develop                 # PR base [the repo's default branch]
label_ready: agent-ready      # label names [the four defaults]
label_working: agent-working
label_question: agent-question
label_pr: agent-pr
max_solvers: 3                # solvers at once [3]
co_author: "Co-Authored-By: Claude <noreply@anthropic.com>"   # [none]
gate:                         # [from CLAUDE.md / AGENTS.md / CONTRIBUTING.md / CI]
  - npm run lint
  - npm test
---

Check UI changes with `npm run dev` and a screenshot at phone width.
Never run `npm run deploy`.
```

- **Commit identity** is whatever the project's git config says; the agents
  never set or change it.
- **Co-author trailer** comes from `co_author`, or there is none.
- **Repository** is read from `gh repo view`; nothing is hard-coded.

## Git hooks

Optional, installed by setup. They act only inside a Claude Code session
(`CLAUDECODE=1`); your own commits are untouched.

- `prepare-commit-msg` adds the `co_author` trailer (nothing without one).
- `post-commit` pushes an agent's commit in the background, only on a branch
  that already tracks a remote one and never on the base branch, `main` or
  `master`; failures go to `issue-loop-push.log` in the git directory.
- `post-merge` does the same after a merge or pull.

Without the hooks the solver adds the trailer and pushes by hand.

## Safety rules

The agents follow these in every project:

- **Never merge, never bump a version, never publish** a package, tag or
  release. Those stay with you.
- **The branch push is the lock.** A solver claims issue N by pushing a new
  branch `issue-<N>`; if the push is rejected or a PR from it exists, someone
  else has the issue and the solver stops.
- **Only its own branch.** A solver never touches a branch, worktree or PR that
  is not its `issue-<N>`, never pushes to the base branch, and works in its own
  worktree under `.claude/worktrees/`, never in your checkout.
- **Ask, don't guess.** A choice you would notice becomes one question on the
  issue, with a recommended answer.
- **No secrets** in issues, PRs, comments, commits or logs.
- **CI waits in the background**, never as a blocking foreground watch.
- **No transcript links.** A PR's Session line carries only a session id and
  `claude --resume <id>` — useful on the machine that ran it, and nowhere
  else, which is what a public repository needs.

## Layout

```
.claude-plugin/plugin.json        the plugin
.claude-plugin/marketplace.json   this repo as a one-plugin marketplace
agents/issue-writer.md            one-line request → solvable issue
agents/issue-solver.md            issue → draft PR → ready PR
skills/issues/SKILL.md            /issues: file, or one pass over the queue
skills/setup/SKILL.md             /issue-loop:setup
templates/                        issue forms, PR template, git hooks, settings
```

## License

MIT — see [LICENSE](LICENSE).
