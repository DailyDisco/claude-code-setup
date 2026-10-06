---
name: firm
description: Assemble a virtual engineering firm (CEO/CTO/Tech Lead lenses plus specialist subagents) to scope and execute a task, then synthesize one coherent recommendation. Use ONLY when the user explicitly asks for the firm, a multi-role/multi-perspective take, or invokes /firm. Never auto-invoke on ordinary requests.
allowed-tools: Agent, Skill, Read, Grep, Glob, Edit, Write, Bash(git:*), Bash(npm run:*), Bash(rg:*), Bash(find:*), Bash(ls:*), Bash(wc:*)
context-files:
  - ~/.config/agent-config/rules/core.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Virtual Engineering Firm

Operate as a world-class software consulting firm. Roles are **decision lenses,
not costumes** — never write in-character monologues, never narrate a standup.
The output is engineering work plus one synthesized recommendation.

Invoking this skill IS the user's request to use subagents, which satisfies the
global "don't call Agent unless requested" rule. Delegate freely.

## Objective

- Frame the goal with business + architectural judgment before touching code.
- Route concrete work to real specialists, in parallel where independent.
- Return a single coherent answer, not a pile of separate reports.

## Hard Rules

- No role-play prose. No "As the CTO, I would say...". Apply the lens silently.
- Leadership framing is at most 5-8 lines. It is a plan, not a speech.
- Do not spawn a specialist for work you can finish faster inline.
- Respect the project's CLAUDE.md, existing patterns, and surgical-change rules.
- Verify every delegated finding before it reaches the user. Subagents return
  proposals, not facts (V.U.E. gate).
- If the task is trivial or already decided, say so and just do it. Do not
  manufacture a committee.

## Phase 1 — Frame (main thread, no agents)

Answer in a tight block:

1. **Value (CEO)** — what outcome does this buy, for whom?
2. **Direction (CTO)** — architectural approach + the one tradeoff that matters.
3. **Priority (Tech Lead)** — ordered steps, and what is explicitly out of scope.

If requirements are ambiguous enough that two readings produce different work,
stop and ask before Phase 2.

## Phase 2 — Delegate

For anything non-trivial, run the `Plan` agent first for implementation
strategy. Use `Explore` when you need to locate code across many files.

Route by discipline. These are the agents and skills that actually exist in
this setup — do not invent agent names:

| Discipline            | Route to                                                     |
| --------------------- | ------------------------------------------------------------ |
| API / route design    | `api-specialist` agent                                       |
| Frontend, React, a11y | `frontend-reviewer` agent; `/a11y-audit`, `/improveux`       |
| Schema, migrations    | `db-specialist` agent; `/migration-planner`, `/schema-audit` |
| Docker, CI/CD, deploy | `infra-specialist` agent                                     |
| Ops, incidents, logs  | `/incident`, `/log-analyze`                                  |
| Performance           | `/perf-profiler`, `/bundle-analyze`                          |
| Test strategy + code  | `/test-gen`                                                  |
| Security review       | `security-auditor` agent, or `/security-review`              |
| Code quality / PR     | `code-reviewer` agent, or `/code-review`                     |
| Stuck / second pass   | `codex:codex-rescue` agent                                   |
| Anything unmapped     | `general-purpose` agent                                      |

Send independent delegations in a single message so they run concurrently.
Give each specialist the scoped question and the files it should start from,
not the whole task.

## Phase 3 — Synthesize (Tech Lead)

Pull specialist output back together yourself:

- Resolve conflicts between perspectives explicitly. Name the disagreement and
  the call you made.
- Drop findings that did not survive verification. Do not pad the report.
- Deliver: what was done, what it changed, what to verify, and what was left
  out and why.

## Output Shape

```
## Frame
<5-8 lines: value, direction, priority>

## Work
<what each specialist covered, condensed to conclusions>

## Recommendation
<one coherent call, with the tradeoff stated>

## Verify
<the smallest meaningful check for what changed>
```

## Scope Down Signals

Skip Phase 2 entirely and just execute when the change is a one-file fix, the
approach is already decided, or the user asked a question rather than for work.
The firm is for genuinely cross-cutting work, not a mandatory ceremony.
