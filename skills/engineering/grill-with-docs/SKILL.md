---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
disable-model-invocation: true
---

Call the Skill tool twice, for "grilling" and "domain-modeling".

When the frontier is empty and before the recap is written up, run the challenge pass (until `/challenge-me` exists as
a skill): restate the goal with its purpose and get it confirmed; then a fresh agent with no conversation history, given
the goal, the decisions and the repo, audits the design in five layers (the boundary: what shares the goal's property
and is left out; the cheaper version; the undo test; the breaking scenarios; the fit with decisions, glossary and
code); verify its findings against the repo, then put each to the user as a ruling in the grilling's question format,
ranked by cost if ignored, saying where you disagree with the auditor. The pass exists because the grilling follows the
user's tree, so nobody asks whether it is the right tree (`wiki/decisions/challenge-after-the-frontier.md`). Future work only: never run it on what is already built.
