---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

When working a ticket, pass a model and effort on every Agent tool spawn you make for it: the ticket's `**Model:**` and `**Effort:**` lines win; else take its `**Complexity:**` class (`normal` when absent) and look it up in `brain3 models --json`. Do not change your own model.

Copy this checklist into your reply and tick it as you go:

```
- [ ] 1. Fetch the ticket, state its title
- [ ] 2. Build it with tdd
- [ ] 3. Suite and typecheck green
- [ ] 4. Code review without hard findings
- [ ] 5. Close the issue
- [ ] 6. Commit
```

## 1. Fetch the ticket, state its title

If the user passes a ticket reference, fetch it from the issue tracker and state its title in one line before starting. If the reference is ambiguous, ask. When the work comes from a spec or the conversation with no ticket, state what you are building instead.

## 2. Build it with tdd

Call the Skill tool with "tdd" where possible, at pre-agreed seams. Run typechecking and single test files regularly as you go.

## 3. Suite and typecheck green

Run the typecheck and the full test suite. Done when both pass. Red: go back to step 2 and fix the cause.

## 4. Code review without hard findings

Call the Skill tool with "code-review" to review the work. Done when it raises no hard finding (a bug, a broken standard, a gap against the ticket). Findings: fix them, then go back to step 3, since a fix can break the suite.

## 5. Close the issue

When working a ticket, close it through the issue tracker doc's **Close** operation (`docs/agents/issue-tracker.md`, "Implementation operations"): tick each acceptance box the work earned, set `**Status:** done`, and append one line under `## Comments` naming the branch or commit. A box the work did not earn is not a close: the status stays and the comment says why. With no ticket, skip this step.

## 6. Commit

Commit your work, the closed issue included, to the current branch.
