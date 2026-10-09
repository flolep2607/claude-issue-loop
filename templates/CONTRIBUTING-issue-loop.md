## Working with the issue agents

This project uses [issue-loop](https://github.com/flolep2607/claude-issue-loop):
coding agents work through GitHub issues, and people review what they produce.

**How it works.** An issue labelled `agent-ready` is picked up by an agent,
which opens a draft pull request from a branch named `issue-<N>`, pushes its
work in steps, runs the project's checks, and marks the PR ready. If it needs
a decision it asks on the issue and waits for your reply.

**Labels.**

| label | meaning |
|---|---|
| `agent-ready` | written and waiting for an agent |
| `agent-working` | an agent has it; a draft PR exists |
| `agent-question` | the agent asked on the issue and is waiting for you |
| `agent-pr` | the PR is ready for your review |

**Filing for an agent.** Use the "Task for an agent" issue form: what to do,
and how to tell it is done. It applies `agent-ready` for you. Any other issue
becomes agent work once you add that label; say enough that nobody has to ask.
Never put secrets in an issue.

**Answering.** Reply on the issue when an agent asks; your comment outranks
the issue text. Review comments on an agent's PR are picked up and addressed
like any other review.

**Agents never merge.** They do not merge, bump versions, tag or publish.
A person reviews every PR and decides.
