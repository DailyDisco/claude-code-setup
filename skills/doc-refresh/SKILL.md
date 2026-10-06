---
name: doc-refresh
description: Verify a repo's (or multi-repo workspace's) documentation against reality, refresh READMEs/CLAUDE.md, create .claude/ agent-guidance folders, and optionally ship the result (commit/PR/merge). Use when user says docs are stale or out of date, wants documentation brought up to date, wants CLAUDE.md or .claude folders created, or asks to "document everything" in a repo or workspace.
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Documentation Refresh & Ship

Bring a repo's — or a whole workspace's — documentation into line with verified
current reality, create agent-guidance (`.claude/CLAUDE.md`) where missing, and
optionally ship the changes. The core discipline: **docs describe what you
verified, not what you remember or what the old docs claimed.** Every claim
traces to code, CI config, git history, or a live read-only query. If you can't
verify it, omit it or mark it explicitly as unverified.

Scale to the target: a single repo is one pass done inline; a multi-repo
workspace gets one parallel subagent per repo/doc surface (Phase 1).

## Phase 0 — Survey and sync (never skip)

1. **Inventory the doc surfaces.** For each repo: README.md, CLAUDE.md /
   AGENTS.md, `.claude/`, docs/ folders, `.env.example`, wiki-style files.
   Note which exist, their last-commit date vs. the code's recent activity.
2. **Check every checkout's freshness BEFORE documenting it.**
   `git fetch origin && git rev-list --count HEAD..origin/<default-branch>`.
   A stale clone produces confidently wrong docs (a 144-commits-behind tree
   has burned this before). If behind:
   - Back up any uncommitted work first: `git diff <file> > scratchpad/patch`
     plus full file copies. Never rely on memory of what was dirty.
   - Restore dirty tracked files to HEAD content (`git show HEAD:<f> > <f>` —
     a plain file write, no discard command), then `git merge --ff-only
origin/<branch>`. `--ff-only` refuses rather than clobbers; if it
     refuses, stop and reconcile manually.
   - Re-apply saved patches with `git apply --3way` (note: it may stage the
     result and leave conflict entries in the index; resolve, then `git add`
     to clear the unmerged state).
3. **Map ownership and blast radius per repo** before anything else:
   - Who owns it (yours vs. client/third-party)?
   - Does pushing/merging the default branch trigger deploys or publishes?
   - Any "treat as read-only" repos (vendored forks, upstream mirrors)?
     This map decides where `.claude/` files go (tracked vs. local-only) and
     how Phase 3 ships.

## Phase 1 — Parallel verified doc passes

For a workspace, launch one subagent per repo/surface (all in one message so
they run concurrently; use the strongest model available for these). Each
agent's brief must include:

- The repo's context and blast-radius facts you already know (deploy triggers,
  known gotchas, migration status) — stated as claims **to verify, not trust**.
- Explicit tasks: read the repo thoroughly; update README surgically; create
  `.claude/CLAUDE.md`; report staleness found but NOT fixed.
- Hard rules: no git commits/pushes; no AI attribution in file contents; never
  read `.env*` files (`.env.example` excepted); never write real secret
  values; only verified facts — omit rather than guess; `timeout 60` on slow
  git commands; avoid bare `git status` in huge working trees (use
  `git diff --stat HEAD`, `git ls-files`).
- Report format: files created/changed with 1–2 sentences each, plus a
  "stale/contradictory, found but not fixed" list. That second list is often
  the most valuable output — surface it to the user.

Agents doing verification may use read-only live queries (`aws ... describe/
list/get`, `gh api`, `gh run list`) when docs make claims about live systems.
Encode what they _find_, not what the old docs or scripts _intended_ ("adopt,
don't recreate" applies to prose too — a doc that says X was applied when the
live system shows otherwise gets corrected to "written, not yet applied").

## Phase 2 — Writing rules

**README.md** — for humans arriving at the repo. What it is, what it actually
provisions/serves today, how to run/test it safely, deploy model with its real
status (including "this lane has never run green" if true), inventories of
loose operational files, known drift. Edit surgically: keep accurate content
and the existing voice; every changed line traces to a verified staleness.

**.claude/CLAUDE.md** — for agents working in the repo. Contents, in order of
importance:

1. What the repo is, in two sentences, including what is NOT available
   locally (private upstream modules, unreachable orgs).
2. **Safety rails, numbered, most dangerous first** — the commands that must
   never run (`terraform apply`, `dbt clean`, direct pushes to auto-deploying
   branches), load-bearing resources (Elastic IPs, pinned tags), and
   in-flight migrations that make some work throwaway.
3. Key-file map (table), conventions (commit style, PR-first, no AI
   attribution), and safe local commands.

**Placement rule:** in repos you own, `CLAUDE.md` at root, tracked. In
client/third-party repos, put it at `.claude/CLAUDE.md` and add `.claude/` to
`.git/info/exclude` (NOT `.gitignore` — exclude is local-only and invisible in
`git status`), so agent tooling never enters client-visible history. Check the
line isn't already present before appending.

**Read-only repos** (vendored forks): create only `.claude/CLAUDE.md` (+ the
exclude line). Touch nothing tracked.

## Phase 3 — Shipping (only on explicit request)

Do NOT commit/push/merge unless the user asked. When they do:

- **Per-repo danger check first**: what does merging the default branch
  trigger? Deploys, package publishes, tarball uploads? Say so in the PR body
  and confirm the triggered run goes green after merge (`gh run watch`).
- PR-first everywhere; merge style matches the repo's history. Conventional
  commits with why-focused bodies, one concern per commit
  (`git commit -F <msgfile> -- <paths>` scopes cleanly even with other things
  staged). No AI attribution in commits, PR text, or branch names.
- **Subagents often get permission-blocked on git writes** (merge, push) and
  on being _instructed_ to merge. Split the work: agents verify and author
  files + commit messages + PR bodies; the main session executes git/gh. Tell
  agents: "if a command is denied, do not work around it — report it."
- Use `--body-file` / `-F <file>` for anything multi-line. **Never heredocs**
  — this environment's shell wrapper hangs on them.
- After merging: fast-forward local branches, delete merged branches local +
  remote. A branch that refuses `-d` may be a pre-rebase copy — diff its
  unique commits against the merged result before any `-D`; if the unique
  content targets code that no longer exists, it's safe; otherwise leave it
  and report.

**Dead-code removal** (if the doc pass surfaced orphans) is gated on all of:

1. Repo-wide grep for each basename — only self-references, docs, and
   comments may remain.
2. Former callers confirmed absent from origin/<default>.
3. The live/surviving code paths explicitly read end-to-end to confirm they
   don't reference the candidates.
4. CI workflows confirmed to glob directories generically, not name the files.
5. External consumers checked (sibling repos, migration tooling).
   Anything failing a gate is kept and documented instead. State in the PR what
   deletion does NOT do (e.g., already-deployed copies persist when deploy
   doesn't prune).

## Phase 4 — Report

End with: a per-repo table (what changed, PR, CI state), the
"found-but-not-fixed" list, what was deliberately left alone and why, and
follow-ups that need a human (credentials, rotations, unmerged reverts,
pending confirmations). Report failures plainly — "merged but the plan lane
still can't run" beats implying it's validated.

## Environment gotchas (learned the hard way)

- Formatter hooks run after Edit/Write and will mangle merge-conflict markers
  into blockquotes. Never leave conflict markers in a file across an edit —
  resolve by reconstructing the file from a saved copy in one Write.
- `git apply --3way` can stage results and leave unmerged index entries;
  `git add <file>` clears them after you fix content.
- Long compound Bash commands and heredocs can hang; prefer several small
  commands, python one-liner files, or the Write/Edit tools for file content.
- If a `.env*` deny rule blocks even `.env.example` comment fixes, hand the
  exact replacement text to the user instead of bypassing.
