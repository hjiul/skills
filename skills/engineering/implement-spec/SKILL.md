---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket closed through the issue tracker's **Close** operation (`docs/agents/issue-tracker.md`, "Implementation operations"), then landed on `main` through this skill's own **Landing** steps (step 10). This run is the whole life of the feature folder (`docs/agents/issue-tracker.md`, "Folders and project groups"): it is the only builder of a feature folder, the board's Implement button launches it, and nothing else lands the folder after it.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers. The standing rules every implementer works under are `docs/agents/implementer-brief.md`: a spawn brief is the ticket's path, the branch and worktree, the model and effort, the ticket-specific lines and one line pointing at that file, never a restatement of the ticket (the V5 reshape run retyped 133k characters of ticket content into 54 briefs). A rule you learn mid-run is appended to that file the moment you learn it, so the next spawn gets it; your memory never reaches a subagent.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

You orchestrate; you never edit code yourself. Every code change and fix goes through a subagent; the git you run yourself is step 6's fast-forward, its read, a conflict-free merge, and the **Landing** (its status lines, the board copies and the merge into `main`).

**Live steps**: n8n, Vapi and the test site's hosted areas are development infrastructure an implementer acts on itself (`docs/agents/auto-mode-settings.md`; `wiki/decisions/dev-infrastructure-grant.md`). A Coolify deploy, or any step the grant leaves to the user, is never an implementer's step: the implementer files it as a new `ready-for-human` ticket of the folder (next free number, the step as a complete command, the ticket that needs it and why) and closes its own ticket on its own boxes. A behaviour only a live call proves goes to the group's `live-checks` standing folder as a ticket (the tracker doc's "Live checks"), never a box and never a hold on a close. A brief that names a deploy as the implementer's work is refused at spawn time by the permission classifier (ticket 04, 2026-10-15; the Gotchas of `wiki/tools/claude-code/README.md`).

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
- [ ] 12. Close the session
```

Go back when a check fails: a ticket whose merge leaves it short of `done` goes back to step 5; a frontier with tickets left goes back to step 5; a review with findings goes back through its fix to step 8; step 9 starts only when every ticket is `done` or `wontfix`, but the `ready-for-human` ones and the tickets they block; checks failing in step 10 go to the review fixer and back to step 10.

1. Read the spec, then of each ticket only its header lines: the title, `**Blocked by:**`, `**Status:**`, `**Complexity:**` and any `**Model:**`/`**Effort:**` pin (`grep -n '^# \|^\*\*' <ticket>` gives them). That is the task graph; the implementer reads its own ticket's body. Reading 22 tickets in full carried about 90k characters across every later request of the V5 reshape run for nothing the orchestrator used. A `ready-for-human` ticket is never spawned: it is the user's step, written up front or filed mid-run (Implement lights while one is open, as long as a `ready-for-agent` ticket is on the frontier): skip it, build what does not depend on it, and report it.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch, named after the feature folder (`git branch <feature> main`, the tracker doc's "Branches and worktrees"). If the issue tracker closes work through PRs, or the user asks for one, open a draft PR after the first merge in step 6 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets.

4. Resolve each ticket's model and effort before spawning its implementer:
   - read the ticket's `**Model:**`, `**Effort:**` and `**Complexity:**` lines;
   - take the class from `**Complexity:**`, or `normal` when the line is absent;
   - look the class up in the output of `brain3 models --json` (run it once per run; it maps each class to `{ model, effort }`, and its `helpers` key the helpers);
   - an explicit `**Model:**` or `**Effort:**` line overrides that half of the class's pair; the other half still comes from the class.

5. Use **implementer subagents** to implement each ticket, each in its own worktree on its own branch. Each implementer subagent:
   - confirms its worktree is based on the integration branch before starting, and resets onto it if not;
   - claims its ticket before any other work (the tracker doc's **Claim** operation), naming its patch then when the ticket touches a path an alma project ships (the tracker doc's "Ticket patch"; when none fits it asks you, proposing a name, and you ask the user);
   - ends every commit message on shipped files with its ticket's trailer, `Ticket: <group> <folder> <NN>`, beside `Co-Authored-By:` in the last paragraph, its merges of the integration tip included (the tracker doc's "The commit's trailer");
   - weighs the ticket (the tracker doc's **Weight**) and calls the Skill tool with `tdd` only when it is logic; docs and light code are built directly;
   - tests by moment (`docs/agents/implementer-brief.md`): the one file while iterating, its package's suite before each commit, the root suite for the projects it changed (`pnpm check <projects>`) once at the close;
   - files any step only the user can take as a new `ready-for-human` ticket of the folder, and a live check as a ticket in the group's `live-checks`, and never waits on either;
   - closes its ticket through the tracker doc's **Close** operation, its `## Comments` line naming its branch and final commit;
   - merges the integration branch tip into its own branch before reporting done.

   Spawn each one with the model and effort resolved in step 4, with a brief of the shape the brief file describes (ticket path, branch, worktree, model, effort, ticket-specific lines, the pointer). When an implementer fails a ticket twice (reports it cannot finish, or its work fails the checks), raise the ticket one class (`easy` to `normal`, `normal` to `complex`), re-resolve it through step 4 and respawn. Explicit `**Model:**`/`**Effort:**` lines do not apply after a bump. If the ticket already ran at `complex`, stop and report it to the user instead.

6. Once an **implementer subagent** completes, fast-forward the integration branch to its branch yourself (`git fetch . <ticket-branch>:<integration>`; the implementer merged the integration tip first, so this is a fast-forward), then read the ticket there (`git show <integration>:<ticket path>`): it must read as the tracker doc's **Close** operation leaves it. The fetch also refuses while a worktree has the integration branch checked out: remove that worktree when its work is merged, else wait for it, then fetch again. When the fetch refuses as not a fast-forward (the integration branch moved), run the merge yourself in the implementer's worktree (`git merge <integration> -m "Merge <integration> into <ticket-branch>" -m "Ticket: <group> <folder> <NN>"` there, the ticket of that branch, then the fetch again); spawn a **merger subagent** only when that merge conflicts. A ticket whose status or comment line is missing goes back to its implementer by `SendMessage`, not to a new spawn. A ticket the Close rules leave short of `done` stays `claimed` and goes back to step 5. The four merger spawns of the V5 reshape run each answered in 9 to 40 tokens: there was no conflict to resolve.

   **The pending list for the user**: when tickets leave steps for the user (a `ready-for-human` ticket filed mid-run, a Deploy to press), post the list once, each item a complete command or click with its ticket path, and re-post it only when it changes. A ticket blocked by one of them is skipped, not spawned, and named in that list; the run goes on with the rest of the frontier. Never ask the user to rule on a ticket whose own text already answers it (a `wontfix` ticket, an idea file).

7. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency. One ordering the graph may not show: a ticket that adds a lint finding over data another ticket migrates runs after it, or the finding ships inside the migration ticket (tracker-reshape 03, 2026-10-18, made `brain3 lint` red on the real tree for five tickets, each committing with `--no-verify` and losing the hook's protection meanwhile).

8. Once all tickets are complete, call the Skill tool with `code-review` on the integration branch (a docs-only diff is reviewed as the tracker doc's **Weight** says). Fix all issues raised by the code review in a single implementer subagent, the review fixer, spawned with the `reviewFixer` helper entry (not a ticket class); its commits on shipped files carry the trailer of the ticket whose code each fix changes, one ticket per commit (a fix spanning two tickets' code is two commits). Then run `code-review` again; repeat review and fix until a review comes back clean. A review that reports no violation of a documented standard and only baseline smells marked as judgement calls counts as clean: fix those smells in that one fixer round if they are worth it, and do not review a third time for them (the link-questionnaire run of 2026-10-20 spent a second fixer and a third review pair on naming smells alone; the user approved the stop).

9. If a draft PR exists, mark it ready for review; the PR's merge replaces step 10's merge. Otherwise, check every agent ticket is closed through the tracker doc's **Close** or **Won't fix** operation, and have a subagent close any that are not. `ready-for-human` tickets filed mid-run, and the tickets they block, stay open: the landing does not wait for them, the spec's `**Status:** done` does.

10. Land the integration branch yourself, through the **Landing** steps below, with the integration branch as `<feature>`, the folder as `<folder>` and the main checkout's root as `<main>`. Step 8 was the review, already clean, so the merge goes ahead without asking (`wiki/projects/brain/decisions/finalize-when-clean.md`) and the report comes after. When the spec carries `**Bench:** true`, skip this step: the integration branch is never merged into `main`, by you or by anyone you spawn, and the run ends with the branch reported.

    When a ticket deploys from `main` (Coolify builds the GitHub `main` tip), land the integration branch the same way before that ticket starts, without setting the spec's status; the final landing follows the last ticket. Never on a bench run.

11. Clean up every worktree the run created, then delete the ticket branches and the integration branch once `main` holds them (`git branch -d`). On a bench run, keep the integration branch.

12. Call the Skill tool with `close-session`, with `<folder>/spec.md` as the issue (`brain3 close` takes a file, never a folder). It runs analyse itself, so this is one call: the session runs in the user's VS Code, so analyse presents its proposals in chat and waits for the ruling. Then send the report the Landing's step 6 describes, the run's last message.

## Landing

The integration branch reaches `main` here and nowhere else. You run the git yourself (it is merge work, not a code change); a conflict or a failing check goes to a subagent (the merger, the review fixer).

1. **Worktree on the branch**: reuse the one `git worktree list` shows on `[<feature>]`, else `git worktree add <main>-wt/<feature> <feature>` and `pnpm install --offline` there. Call it `<wt>`.
2. **Bring `main` in**: `git merge main` in `<wt>`. A conflict goes to the merger subagent; one it cannot resolve stops the run.
3. **Checks, once**: in `<wt>`, `pnpm check <projects>` naming each folder under `projects/` that `git diff --name-only main...HEAD` touches (each runs with its project group: `docs/agents/implementer-brief.md`, "Test by moment"); bare `pnpm check` when the diff touches a root file the suites share (`package.json`, `pnpm-lock.yaml`, `scripts/`); plus `pnpm --silent brain3 lint` when the diff touches `wiki/` or a tracker folder; a docs-only diff runs lint alone. A failure goes to the review fixer, then the checks again; a second failure stops the run.
4. **Statuses**: when every ticket of the folder is closed (`done`, `wontfix` or `resolved`), set `**Status:** done` in `<folder>/spec.md`; otherwise leave the spec's status and name the open tickets in the report (the user's `ready-for-human` ones, and what they block: once they are done, the next Implement builds the rest and sets the spec done). Then carry the board copies over: `git diff -- <folder>` in `<main>` shows what the main checkout holds uncommitted; status lines there mirror the branch, any other line (a `## Comments` entry, an edit the user made) is copied into the same file in `<wt>`. Commit on `<feature>` with explicit paths.
5. **Merge into `main`**, from `<main>`, which must be on `main`:

   ```bash
   git checkout -- <folder>                       # restore the board copies; the merge brings the committed statuses
                                                  # (on an early landing, only the files of merged tickets: a running
                                                  # ticket's uncommitted claim stays, dev-prod-split 05, 2026-10-22)
   git merge --no-ff <feature> -m "Merge <feature>: <one-line summary of the spec>"   # a merge: the trailer hook lets it through
   git push origin main
   ```

   Other sessions' uncommitted files blocking the merge stop the run: name them to the user and touch nothing of theirs. A conflict means `main` moved since step 2: `git merge --abort` and go back to step 2. When `pnpm-lock.yaml` changed on the branch, `pnpm install --offline` in `<main>` after the merge. When the auto-mode classifier blocks the push, ask the user for a one-line go-ahead.
6. **Report** (after step 12, the run's last message): the merge commit on `main` and the push, the checks and the review outcome, the worktrees and branches removed or left (step 11), the open `ready-for-human` tickets with their steps, the live-check tickets filed, under « Left for you » each patch whose tickets the run closed the last of (its goal met, `ready` offered; a push, a deploy or a flip is such a line, never a ticket), and every `[team]` decision taken in the run with the alternative not taken.
