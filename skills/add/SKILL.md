---
name: add
description: Declares the issue-loop plugin in the current repository's committed .claude/settings.json, so everyone who opens it is offered the tooling (not just you). Installing the plugin is per-user; this makes the repo carry it. Run once per project; safe to re-run.
disable-model-invocation: true
---

Declare the issue-loop plugin in the repository in the current directory, so a
teammate who opens it is offered the marketplace and plugin instead of adding
them by hand. This writes two keys — `extraKnownMarketplaces` and
`enabledPlugins` — into the committed `.claude/settings.json`; it does not
install anything, since Claude Code still asks each person before installing a
plugin.

Run the script the plugin ships, against the current repo:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/add-issue-loop.sh"
```

It creates `.claude/settings.json` if it is missing, merges the two keys into
an existing one (keeping its hooks and permissions), and is idempotent. Then:

- Show the resulting `.claude/settings.json` and tell the user to commit it.
- If they have not set the project up yet, point them at `/issue-loop:setup`
  for the labels, issue forms and hooks.
