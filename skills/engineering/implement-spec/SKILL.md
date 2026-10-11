---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket closed through the issue tracker's **Close** operation (`docs/agents/issue-tracker.md`, "Implementation operations").

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

You orchestrate; you never edit code yourself. Every code change, merge and fix goes through a subagent.

Pass `model` and `effort` to the Agent tool on every spawn; no subagent inherits your model. Implementers take their ticket's resolved model (step 4). Helpers take theirs from the `helpers` key of the same `brain3 models --json` output: `exploration` for the **exploration subagent**, `merger` for the **merger subagent**, `reviewFixer` for the review fixer in step 8; the `code-review` skill resolves its own reviewers (`reviewer`). When the command is unavailable, fall back to exploration Sonnet, merger Haiku, review fixer Opus, each at effort `medium`. These are floors: raise a helper's model or effort when the spec warrants it (for example, a merge expected to need real conflict resolution).

## Steps

Copy this checklist into your reply and tick it as you go:

```
- [ ] 1. Read the spec and tickets
- [ ] 2. (optional) Exploration subagent
- [ ] 3. Integration branch
- [ ] 4. Resolve each ticket's model and effort
- [ ] 5. Implementers: claim first, build, merge the integration tip
- [ ] 6. Merge each finished ticket, ticket set to done
- [ ] 7. Frontier changed: back to 5 for the new tickets
- [ ] 8. Code review on the integration branch, repeated until clean
- [ ] 9. Every ticket closed, branch reported (or draft PR ready)
- [ ] 10. Clean up the worktrees
```

Go back when a check fails: a ticket whose merge leaves it short of `done` goes back to step 5; a frontier with tickets left goes back to step 5; a review with findings goes back through its fix to step 8; step 9 starts only when every ticket is `done` or `wontfix`.

1. Read the spec and tickets to understand the task graph.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch. If the issue tracker closes work through PRs, or the user asks for one, open a draft PR after the first merge in step 6 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets.

4. Resolve each ticket's model and effort before spawning its implementer:
   - read the ticket's `**Model:**`, `**Effort:**` and `**Complexity:**` lines;
   - take the class from `**Complexity:**`, or `normal` when the line is absent;
   - look the class up in the output of `brain3 models --json` (run it once per run; it maps each class to `{ model, effort }`, and its `helpers` key the helpers);
   - an explicit `**Model:**` or `**Effort:**` line overrides that half of the class's pair; the other half still comes from the class.

5. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. Each implementer subagent:
   - confirms its worktree is based on the integration branch before starting, and resets onto it if not;
   - claims its ticket before any other work: sets `**Status:** claimed` in the ticket file and saves (the tracker doc's **Claim** operation);
   - calls the Skill tool with `tdd` to build the ticket;
   - closes its ticket through the tracker doc's **Close** operation (boxes the work earned ticked, `**Status:** done`, one `## Comments` line naming its branch and final commit), leaving a dogfood or hand-check box unticked with a comment saying why;
   - merges the integration branch tip into its own branch before reporting done.

   Spawn each one with the model and effort resolved in step 4. When an implementer fails a ticket twice (reports it cannot finish, or its work fails the checks), raise the ticket one class (`easy` to `normal`, `normal` to `complex`), re-resolve it through step 4 and respawn. Explicit `**Model:**`/`**Effort:**` lines do not apply after a bump. If the ticket already ran at `complex`, stop and report it to the user instead.

6. Once an **implementer subagent** completes, merge its work to the integration branch with a **merger subagent**. The merge sets the ticket `done`: the merger checks the ticket on the integration branch reads as the **Close** operation leaves it (earned boxes ticked, `**Status:** done`, the `## Comments` line) and fills in the status or the comment line when the implementer left them out. An acceptance box left unticked (other than a dogfood or hand-check box) is not a close: the ticket stays `claimed` and goes back to step 5.

7. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

8. Once all tickets are complete, call the Skill tool with `code-review` on the integration branch. Fix all issues raised by the code review in a single implementer subagent, the review fixer, spawned with the `reviewFixer` helper entry (not a ticket class). Then run `code-review` again; repeat review and fix until a review comes back clean.

9. If a draft PR exists, mark it ready for review. Otherwise, check every ticket is closed through the tracker doc's **Close** operation (`**Status:** done` with its earned boxes ticked, or `wontfix` with a reason), have a subagent close any that are not, and report the integration branch. When the spec carries `**Bench:** true`, the integration branch is never merged into `main`, by you or by anyone you spawn: the run ends with the branch reported.

10. Clean up all **implementer subagent** worktrees.
