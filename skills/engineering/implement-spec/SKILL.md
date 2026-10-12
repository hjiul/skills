---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket closed through the issue tracker's **Close** operation (`docs/agents/issue-tracker.md`, "Implementation operations"), then landed on `main`. This run is the whole life of the feature folder: it lands its own branch, so `/finalize` (the close-out for folders built one `/solve` session per issue) never follows it.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

You orchestrate; you never edit code yourself. Every code change, real merge and fix goes through a subagent; the one git command you run yourself is step 6's fast-forward.

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
- [ ] 9. Every ticket closed (or draft PR ready)
- [ ] 10. Land the branch on main, spec set to done
- [ ] 11. Clean up the worktrees and branches
```

Go back when a check fails: a ticket whose merge leaves it short of `done` goes back to step 5; a frontier with tickets left goes back to step 5; a review with findings goes back through its fix to step 8; step 9 starts only when every ticket is `done` or `wontfix`; checks failing in step 10 go to the review fixer and back to step 10.

1. Read the spec and tickets to understand the task graph.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch, named after the feature folder (`git branch <feature> main`, the tracker doc's "Branches and worktrees"). If the issue tracker closes work through PRs, or the user asks for one, open a draft PR after the first merge in step 6 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets.

4. Resolve each ticket's model and effort before spawning its implementer:
   - read the ticket's `**Model:**`, `**Effort:**` and `**Complexity:**` lines;
   - take the class from `**Complexity:**`, or `normal` when the line is absent;
   - look the class up in the output of `brain3 models --json` (run it once per run; it maps each class to `{ model, effort }`, and its `helpers` key the helpers);
   - an explicit `**Model:**` or `**Effort:**` line overrides that half of the class's pair; the other half still comes from the class.

5. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. Each implementer subagent:
   - confirms its worktree is based on the integration branch before starting, and resets onto it if not;
   - claims its ticket before any other work (the tracker doc's **Claim** operation);
   - weighs the ticket (the tracker doc's **Weight**) and calls the Skill tool with `tdd` only when it is logic; docs and light code are built directly;
   - closes its ticket through the tracker doc's **Close** operation, its `## Comments` line naming its branch and final commit;
   - merges the integration branch tip into its own branch before reporting done.

   Spawn each one with the model and effort resolved in step 4. When an implementer fails a ticket twice (reports it cannot finish, or its work fails the checks), raise the ticket one class (`easy` to `normal`, `normal` to `complex`), re-resolve it through step 4 and respawn. Explicit `**Model:**`/`**Effort:**` lines do not apply after a bump. If the ticket already ran at `complex`, stop and report it to the user instead.

6. Once an **implementer subagent** completes, fast-forward the integration branch to its branch yourself (`git fetch . <ticket-branch>:<integration>`; the implementer merged the integration tip first, so this is a fast-forward), then read the ticket there (`git show <integration>:<ticket path>`): it must read as the tracker doc's **Close** operation leaves it. Spawn a **merger subagent** only when the fetch refuses (the integration branch moved: a real merge) or the ticket needs its status or comment line filled in. A ticket the Close rules leave short of `done` stays `claimed` and goes back to step 5.

7. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

8. Once all tickets are complete, call the Skill tool with `code-review` on the integration branch. Fix all issues raised by the code review in a single implementer subagent, the review fixer, spawned with the `reviewFixer` helper entry (not a ticket class). Then run `code-review` again; repeat review and fix until a review comes back clean.

9. If a draft PR exists, mark it ready for review; the PR's merge replaces step 10. Otherwise, check every ticket is closed through the tracker doc's **Close** or **Won't fix** operation, and have a subagent close any that are not.

10. Land the integration branch with a **merger subagent**, following `/finalize`'s steps 2 to 4 and 8 to 10 (`.claude/skills/finalize/SKILL.md`) with the integration branch as `<feature>`: bring `main` in and rerun the checks, set the spec's `**Status:** done`, carry the board copies over and restore them, merge into `main` with `--no-ff`, push. Steps 5 to 7 there are this run's step 8, already clean, so the merge goes ahead without asking (finalize when clean) and the report comes after. A check failing twice, a conflict the merger cannot resolve, or another session's files blocking the merge stop the run and go to the user. When the spec carries `**Bench:** true`, skip this step: the integration branch is never merged into `main`, by you or by anyone you spawn, and the run ends with the branch reported.

11. Clean up every worktree the run created, then delete the ticket branches and the integration branch once `main` holds them (`git branch -d`). On a bench run, keep the integration branch.
