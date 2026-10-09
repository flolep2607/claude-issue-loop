---
name: setup
description: Sets up the issue loop in the current GitHub repository — creates the four agent labels, and optionally adds issue forms (including a one-step task form), a PR template, a CONTRIBUTING section, a label-repair workflow, the agent git hooks and a .claude/issue-loop.md settings file. Shows the plan and asks before writing anything. Run once per project, or again to add what was skipped.
disable-model-invocation: true
---

Set up the issue loop in the repository in the current directory. Nothing here
is written until the user has seen the plan and said yes; existing files and
hooks are never overwritten unless the user asks for that file by name.

The plugin's own files are in `${CLAUDE_PLUGIN_ROOT}/templates/`:

- `github/ISSUE_TEMPLATE/bug.yml`, `idea.yml`, `task.yml`, `config.yml`
- `github/workflows/issue-loop-labels.yml`
- `CONTRIBUTING-issue-loop.md` — a section for human contributors
- `github/pull_request_template.md`
- `git-hooks/prepare-commit-msg`, `post-commit`, `post-merge`
- `issue-loop.md` — the commented settings template

## 1. Look before proposing

```bash
git rev-parse --show-toplevel
gh repo view --json nameWithOwner,defaultBranchRef,visibility,viewerPermission
gh label list --limit 200 --json name
ls .github/ISSUE_TEMPLATE .github/pull_request_template.md .github/workflows/issue-loop-labels.yml .claude/issue-loop.md 2>/dev/null
ls CONTRIBUTING.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md 2>/dev/null
git config --get core.hooksPath
ls "$(git rev-parse --git-path hooks)"
ls -d .husky .githooks 2>/dev/null; grep -s '"prepare"\|husky\|lefthook\|pre-commit' package.json; ls lefthook.yml .pre-commit-config.yaml 2>/dev/null
```

Stop and say why if this is not a git repository, `gh` is not authenticated, or
`viewerPermission` is below `WRITE` (labels need it).

## 2. Show the plan, then ask

Present the steps below as a short numbered list, marking for each one what
already exists and what would be skipped. Then ask (with AskUserQuestion when
available) which of the optional parts to do. Default answers: labels yes,
settings file yes, issue forms and PR template yes where nothing exists,
the CONTRIBUTING section yes, the label workflow no (it is optional), git
hooks yes only when step 5 finds a clean place for them.

## 3. Labels — always offered

```bash
gh label create agent-ready    --force --color 0E8A16 --description "Written and waiting for an agent to solve it"
gh label create agent-working  --force --color FBCA04 --description "An agent is on it, with a draft PR from issue-<N>"
gh label create agent-question --force --color D93F0B --description "The agent asked on the issue and is waiting for an answer"
gh label create agent-pr       --force --color 1D76DB --description "The PR is ready for review"
```

`--force` updates a label that already exists instead of failing. If the user
wants other names, create those instead and record them in the settings file
(`label_ready`, `label_working`, `label_question`, `label_pr`).

The forms label new issues `bug` or `enhancement`; GitHub creates those by
default, but create them too (`gh label create bug --force …`) if step 1 shows
they are missing.

## 4. Issue forms and PR template — optional

Copy each file from `${CLAUDE_PLUGIN_ROOT}/templates/github/ISSUE_TEMPLATE/`
and `pull_request_template.md` into `.github/` at the same relative path,
**only where no file exists**. For each one that
exists, say so and leave it; overwrite it only if the user names it. If the
project already has its own PR template, offer instead to add the one line the
solver relies on (`Fixes #`) if it is missing.

### Task form label

`task.yml` applies the ready label through its own `labels:` list, so something
filed from a phone is picked up by `/issues` in one step. A form cannot read
`.claude/issue-loop.md`: if the project renamed `label_ready`, rewrite
`labels: [agent-ready]` in the copied file to the new name.

## 4b. CONTRIBUTING section — optional

Offer to add `${CLAUDE_PLUGIN_ROOT}/templates/CONTRIBUTING-issue-loop.md`,
which tells human contributors how the loop works, what each label means, how
to file for the agents, and that agents never merge. Never overwrite:

- If a `CONTRIBUTING.md` exists (root, `.github/` or `docs/`), offer to append
  the section to the end, after a blank line, only if no
  "Working with the issue agents" heading is already there. Show it first.
- If none exists, offer to create `CONTRIBUTING.md` containing the section
  under a `# Contributing` heading.

If labels were renamed, change the names in the section's table to match.

## 4c. Label-repair workflow — optional

Offer `github/workflows/issue-loop-labels.yml` to `.github/workflows/`, only
where it does not exist. It runs on `workflow_dispatch` and weekly, and
re-creates the four labels if someone deleted them (`gh label create --force`,
`permissions: issues: write`). Mention that it adds a scheduled Actions run.
If labels were renamed, edit the names in the file to match.

## 5. Git hooks — optional

The hooks act only inside a Claude Code session (`CLAUDECODE=1`); a person's
own commits are untouched. `prepare-commit-msg` adds the `co_author` trailer
from the settings file (nothing without one); `post-commit` and `post-merge`
push an agent's commit in the background when its branch already tracks a
remote one, never on the base branch. Without them the solver adds the trailer
and pushes by hand, so this part is a convenience, not a requirement.

Choose the place from what step 1 found, in this order:

- **A hook manager is in use** (husky, lefthook, pre-commit, or any
  `core.hooksPath`): do not change `core.hooksPath` and do not replace any of
  its files. Offer to copy the three scripts into
  `.claude/issue-loop-hooks/` (committed) and to add one line to each matching
  hook the manager runs — for husky, `.husky/post-commit` with
  `.claude/issue-loop-hooks/post-commit "$@"` — showing the exact change
  first. If that is not simple, explain what to add and leave it to the user.
- **No `core.hooksPath`, and the hooks dir has none of the three hooks** (only
  `*.sample` files): copy the scripts into `$(git rev-parse --git-path hooks)`
  and `chmod +x` them. This is per clone and shared by all its worktrees, and
  nothing is committed. Alternatively, if the user wants every clone to get
  them: copy into a committed `.githooks/` and
  `git config core.hooksPath .githooks` — say that each clone then needs that
  one config command.
- **A hook of the same name already exists** in the hooks dir: do not replace
  it. Offer to copy ours under `.git/hooks/issue-loop-<name>` and append
  `"$(dirname "$0")/issue-loop-<name>" "$@"` to the existing hook, showing the
  diff first.

Afterwards confirm with `ls -l` on the installed files.

## 6. Settings file — offered

If `.claude/issue-loop.md` does not exist, copy
`${CLAUDE_PLUGIN_ROOT}/templates/issue-loop.md` there. Then fill in only what
the user answered — for example uncomment `co_author` if they want a trailer,
`base` if the PR base is not the default branch, renamed labels — and leave
every other line commented, so the defaults stay visible. If the project has
no CLAUDE.md / AGENTS.md / CONTRIBUTING.md naming its build and test commands,
suggest filling in `gate`, with the commands read from CI as a proposal.
Keep the commented example block at the end of the file ("always run X before
pushing", "never touch the vendored folder"): it is how the project's own
instructions are discovered. Offer to replace its examples with real ones.

## 7. Report

List what was created, changed, and skipped (with why), and that nothing was
committed: the user decides whether to commit `.github/` and `.claude/` files.
End with the next steps:

```
/issues <one-line bug or idea>   # file an issue
/issues                          # one pass over the queue
/loop /issues                    # keep the queue moving
```
