---
name: implement
description: "Make a small code fix inside this conversation, on main: build it by its weight, run the checks and a code review, and commit it with a ticket written as done in the right standing folder. Use when a conversation lands on a small code change to make now; a spec is built by /implement-spec, a board ticket by /solve."
---

Make the fix the conversation settled, here, on `main`. This is the in-chat path of the tracker
(`docs/agents/issue-tracker.md`, "Branches and worktrees"): no branch, no worktree, no extra session. The fix stays
part of this session's work: never close or analyse the session from here; its own close covers it.

Only code changes come here. A doc, wiki or tracker edit made in the conversation needs no ticket and no review: make
it, run `brain3 lint`, commit it.

When you spawn a subagent for the work, pass a model and effort on every Agent tool spawn: take the work's class
(`normal` unless it is mechanical, `easy`, or crosses modules, `complex`) and look it up in `brain3 models --json`.
Do not change your own model.

Copy this checklist into your reply and tick it as you go:

```
- [ ] 1. State what you are fixing
- [ ] 2. Build it, by its weight
- [ ] 3. Checks green
- [ ] 4. Write the ticket as done
- [ ] 5. Commit on main
- [ ] 6. Code review without hard findings
- [ ] 7. Push
```

## 1. State what you are fixing

One line: the fix, and the project it touches. Check the conversation's checkout is on `main`
(`git branch --show-current`); when it is not, ask before going on. If the user passes a ticket path, fetch it and
state its title instead: step 4 closes that ticket rather than writing a new one.

## 2. Build it, by its weight

Weigh the work first (the tracker doc's **Weight**, "Implementation operations"): light code or logic. Logic: call the
Skill tool with "tdd" at pre-agreed seams. Light code: build directly. The standing rules are
`docs/agents/implementer-brief.md`; its "Test by moment" tiers apply: the one test file while iterating, the package
suite before the commit, the root suite once in step 3.

Before your first edit of a file, read its state (`git status --porcelain -- <file>`): a file already modified holds
another session's uncommitted lines (other sessions share this checkout). Note it; step 5 refuses to commit it.

## 3. Checks green

`pnpm check <each project the change touches>`, once (each runs with its project group), plus
`pnpm --silent brain3 lint` when the wiki or the tracker changed. Done when all pass. Red: go back to step 2 with the
failing file and fix the cause; the checks run again only when you come back here.

## 4. Write the ticket as done

The fix gets a history line on the board: a ticket in the fitting standing folder of the project's group
(`groups/<group>/.scratch/<folder>/issues/<NN>-<slug>.md`, next free number; usually `bugs` for a fix, `tasks` for a
small change; the tracker doc's "Where a ticket goes"). It carries the title, a `**What to build:**` line saying what
was fixed and why, its `**Project:**` line, `**Status:** done`, `**Complexity:**`, the boxes the fix earned, ticked,
and a `## Comments` line saying it was fixed in the conversation on `main`, with the date. A fix touching a path an
alma project ships carries its `**Patch:** <name>` line (`docs/agents/implementer-brief.md`, "Patches and the
commit's trailer"; `bug-fixes` for a bug of no patch, or ask in chat, proposing a name). When no standing folder
fits, propose one in chat and wait for the user's word. With a ticket path from step 1, close that ticket through the
tracker doc's **Close** operation instead.

A step only the user can take is a `ready-for-human` ticket of the same folder; a behaviour only a live call proves is
a ticket in the group's `live-checks` (the tracker doc's "Implementation operations").

## 5. Commit on main

Note the tip first (`git rev-parse HEAD`, the review's fixed point: other sessions may commit on `main` too). Commit
the fix and the ticket together on `main`, staging explicit paths (`git add <paths>`, never `-A`: other sessions
share the checkout), with the attribution lines the conversation gives and `Ticket: <group> <folder> <NN>` (the ticket
of step 4) on the line above `Co-Authored-By:` in the same last paragraph: the trailer the patch finds the commit by,
which the `commit-msg` hook requires on shipped files. Do not push yet.

**Refuse a file that was already modified.** A file step 2 noted as modified before your own edit is not committed:
its other lines are another session's half-done work, and your ticket would carry them. Stop and tell the user which
file and which session: the newest transcript that edited it other than yours
(`grep -l '"file_path":"<absolute path>"' ~/.claude/projects/<this checkout's folder>/*.jsonl`, newest first), named
by its session id; when none did, the user's own hand edit. Commit the rest only on the user's word.

## 6. Code review without hard findings

Call the Skill tool with "code-review", the tip noted in step 5 as the fixed point, the ticket as the spec. Done when
it raises no hard finding (a bug, a broken standard, a gap against the ticket). Findings: fix them, rerun step 3,
commit the fix with explicit paths and the same `Ticket:` line, and review again.

## 7. Push

Push `main` when the work is clean (`wiki/projects/brain/decisions/finalize-when-clean.md`); a finding that needs the
user's ruling stops here and goes to them. Then say in one line what landed and carry on with the conversation.
