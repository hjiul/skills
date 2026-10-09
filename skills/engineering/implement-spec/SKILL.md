---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket resolved the way the issue tracker closes work.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

You orchestrate; you never edit code yourself. Every code change, merge and fix goes through a subagent.

Pass `model` and `effort` to the Agent tool on every spawn; no subagent inherits your model. Implementers take their ticket's resolved model (step 4). Helpers have defaults: **exploration subagent** Sonnet, **merger subagent** Haiku, the review fixer in step 8 Opus, each at effort `medium` by default. These are floors: raise a helper's model or effort when the spec warrants it (for example, a merge expected to need real conflict resolution).

## Steps

1. Read the spec and tickets to understand the task graph.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch. If the issue tracker closes work through PRs, or the user asks for one, open a draft PR after the first merge in step 6 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets.

4. Resolve each ticket's model and effort before spawning its implementer:
   - read the ticket's `**Model:**`, `**Effort:**` and `**Complexity:**` lines;
   - take the class from `**Complexity:**`, or `normal` when the line is absent;
   - look the class up in the output of `brain3 models --json` (run it once per run; it maps each class to `{ model, effort }`);
   - an explicit `**Model:**` or `**Effort:**` line overrides that half of the class's pair; the other half still comes from the class.

5. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. Each implementer subagent:
   - confirms its worktree is based on the integration branch before starting, and resets onto it if not;
   - calls the Skill tool with `tdd` to build the ticket;
   - merges the integration branch tip into its own branch before reporting done.

   Spawn each one with the model and effort resolved in step 4. When an implementer fails a ticket twice (reports it cannot finish, or its work fails the checks), raise the ticket one class (`easy` to `normal`, `normal` to `complex`), re-resolve it through step 4 and respawn. Explicit `**Model:**`/`**Effort:**` lines do not apply after a bump. If the ticket already ran at `complex`, stop and report it to the user instead.

6. Once an **implementer subagent** completes, merge its work to the integration branch with a **merger subagent**.

7. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

8. Once all tickets are complete, call the Skill tool with `code-review` on the integration branch. Fix all issues raised by the code review in a single **implementer subagent**.

9. If a draft PR exists, mark it ready for review. Otherwise, resolve each ticket the way the issue tracker closes work, and report the integration branch.

10. Clean up all **implementer subagent** worktrees.
