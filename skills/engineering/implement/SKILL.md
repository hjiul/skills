---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

When working a ticket, pass a model and effort on every Agent tool spawn you make for it: the ticket's `**Model:**` and `**Effort:**` lines win; else take its `**Complexity:**` class (`normal` when absent) and look it up in `brain3 models --json`. Do not change your own model.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "code-review" to review the work.

Commit your work to the current branch.
