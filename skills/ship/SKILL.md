---
name: ship
description: Full PR workflow — analyze changes, group into logical commits or PRs, create branches, commit, push, and open PRs. Use when user wants to ship their changes, create a PR, or asks "how do I PR this".
allowed-tools: Bash(git:*), Bash(gh:*), Read
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Ship — Full PR Workflow

You are the shipping assistant. Take all uncommitted changes, analyze them, decide whether they belong in one PR or several, present a plan, and (after approval) execute it end-to-end: branches, commits, push, and PR creation.

There is one entrypoint: `/ship`. You decide the shape internally based on the diff.

---

## Phase 1: Analyze

Run these in parallel:

- `git status` (never use `-uall`)
- `git diff --stat`
- `git diff`
- `git log --oneline -10` (for commit message style and PR number reference)
- `git branch --show-current` and `git rev-parse --abbrev-ref @{u} 2>/dev/null` (to know where to branch from)
- `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` → capture as `$DEFAULT_BRANCH` (fall back to `main` if empty, then `master`)
- `gh pr view --json number,url,headRefName,state 2>/dev/null` (does the current branch already have an open PR?)
- If already on a non-default branch: `git diff origin/$DEFAULT_BRANCH...HEAD` to see committed-but-unpushed work

**Pre-flight checks** (do these once before planning):

- `gh auth status` — fail early if not authenticated; ask user to run `gh auth login`
- Check for `.github/PULL_REQUEST_TEMPLATE.md` — if present, use the repo's template instead of this skill's default

Identify **skipped files** — files that should NOT be committed:

- `.claude/settings.json` (local editor config)
- Personal notes, scratch files, email drafts
- `.env` files or anything with secrets

List skipped files explicitly in the plan.

---

## Phase 2: Decide single-PR vs multi-PR

**Single PR** when:

- All changes serve one purpose / are part of one feature or fix
- Changes are tightly coupled (a service + its types + its component + its tests)
- A reviewer would naturally read them together

**Multiple PRs** when:

- Changes span 2+ unrelated concerns (e.g., a feature + an infra fix + a chore)
- One change is risky/large and shouldn't block a small unrelated improvement
- Different reviewers would be needed
- A subset can ship independently and benefits from earlier merge (CI fixes, dev tooling)

**Stacked PRs** (a specialization of multi-PR) when:

- PR2 depends on code introduced in PR1 (shared utility, schema migration consumed by feature, etc.)
- Each layer is independently reviewable but can't merge in isolation
- Stacked PRs use `gh pr create --base <previous-branch>` and require a one-at-a-time execution flow (see Phase 4)

When in doubt: prefer **multi-PR** for unrelated concerns, **single-PR** for related ones. Don't over-split — 1 file per PR is almost always wrong; one PR per feature is usually right.

---

## Phase 3: Plan

### Single-PR plan

1. **Branch name** — `<type>/<short-slug>` (3–6 words kebab-case). Verify name is free locally (`git show-ref --verify --quiet refs/heads/<name>`) and on remote (`git ls-remote --heads origin <name>`). If taken, append `-2` or ask.
2. **Commits** — ordered logically, each with message and file list (aim for 2–5 commits)
3. **PR title** — under 70 chars, conventional commit style
4. **PR body** — using the template in "PR Description Format" below
5. **Linked issues** — scan commit messages and diff for `#NNN` references; ask user if any open issue should be closed by this PR (will append `Closes #N` to body)
6. **Draft?** — ask if this should open as a draft (WIP, awaiting more work)
7. **Skipped files** — listed with reason

### Multi-PR plan

1. **PR order** — dependency-aware. Ship in this priority:
   1. CI / infrastructure (Makefile, Docker, GitHub Actions) — no code dependencies
   2. Shared utilities / libraries — other PRs may depend on these
   3. Features — new functionality
   4. Bug fixes — corrections to existing behavior
   5. Docs / chore — lowest priority, no functional impact
2. **Stacked?** — flag PRs that depend on earlier ones in the chain. Document the base branch for each.
3. **Per-PR details** — each PR gets: branch name, commits + file lists, PR title, PR body, test plan, base branch, draft flag
4. **Overlapping files** — if two PRs modify the same file, surface this and ask the user whether to combine the PRs or hand-split with `git add -p` (the stash-shuffle flow can't split overlapping changes cleanly)
5. **Skipped files** — listed once with reason

**Present the full plan and WAIT for user approval before executing.** The user may say "actually combine PR 2 and 3" or "split commit 1" — adjust before executing.

### Approval presentation format

Do **not** summarize, abbreviate, or use placeholders. Show every artifact in its final form so the user can approve, copy, or correct it verbatim. Render in this exact order:

```text
## Plan: <single-PR | N PRs | N stacked PRs>

### Working tree summary
- Modified: <N files>
- Added: <N files>
- Deleted: <N files>
- Skipped: <list with reason — one per line>

### PR 1 of N: <PR title>
- Branch: <type/slug>  (base: <default-branch | parent-branch-for-stacked>)
- Draft: <yes | no>
- Closes: <#123, #456 | none>
- Files in this PR (N):
    <full path 1>     <+added / -removed>
    <full path 2>     <+added / -removed>
    ...

#### Commits (N)

##### Commit 1: <full subject line>
Files staged:
  <path 1>
  <path 2>

Full message:
---
<full commit message including body, exactly as it will be written>
---

##### Commit 2: ...
(repeat for every commit)

#### Pull request body (rendered exactly as it will be submitted)
---
<full PR body — markdown, with all bullets, tables, test plan checkboxes, Closes lines, etc. No HTML comments, no placeholders.>
---

### PR 2 of N: ...
(repeat the entire block for every PR)

### Execution order
1. <step>
2. <step>
...

### Hook awareness
- Will run: commit-guard, commit-size, breaking-change, auto-format
- `--no-verify`: <no | yes — reason>

---
Reply `approve` to execute, or tell me what to change.
```

Rules for the presentation:

- **Full commit messages** — subject + body, no `...`, no "see above"
- **Full PR body** — rendered markdown, with `Closes #N` lines appended if applicable, HTML comments stripped
- **Every file path** — no glob summaries like "12 files under src/"; list each path
- **Per-file diff stats** — show `+added/-removed` next to each path so the user can spot suspiciously large changes
- **Skipped files** — explicit list with the reason each is skipped
- **Branch base** — state whether the branch will be cut from `$DEFAULT_BRANCH` or a parent branch (for stacked PRs)
- **No collapsed sections, no "etc."** — if it's going to be executed, it's in the presentation

For very large diffs (>50 files in a single PR), still list every file but you may omit the `+added/-removed` column to keep the output readable, and flag the size to the user.

---

## Phase 4: Execute

### Pre-flight (once)

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}

# If WT has changes, stash them so we can update default branch cleanly
git stash push -u -m "ship: pre-update" 2>/dev/null
git checkout "$DEFAULT_BRANCH" && git pull --ff-only
git stash pop 2>/dev/null  # only if we stashed above
```

**Hook awareness**: Your global config runs `commit-guard`, `commit-size`, `breaking-change` (PreToolUse on `git commit`) and `auto-format` (PostToolUse on edits). They will fire automatically during this skill's execution. **Never use `--no-verify` to bypass them unless the user has explicitly said so for this session.** If a hook surfaces a real issue (formatting drift, oversized commit), fix it and recommit rather than skip.

### Single-PR execution

```bash
git checkout -b <branch-name>

# For each planned commit:
git add <specific-files...>
git commit -m "$(cat <<'EOF'
type(scope): summary

- Why bullet 1
- Why bullet 2
EOF
)"

# Push and create PR:
git push -u origin <branch-name>
gh pr create [--draft] [--base "$DEFAULT_BRANCH"] --title "..." --body "$(cat <<'EOF'
<see PR Description Format below>
EOF
)"

# End on default branch:
git checkout "$DEFAULT_BRANCH"
```

### Multi-PR execution (non-stacked, independent PRs)

Stash-based loop keeps the working tree predictable between PRs:

```bash
# Snapshot the entire dirty working tree before the loop
git stash push -u -m "ship: pre-loop"
```

For each PR in order:

```bash
git checkout "$DEFAULT_BRANCH"
git checkout -b <branch-name>
git stash pop                    # restore full working tree

git add <files-for-this-PR>
git commit -m "..."

# Push leftover (untouched by this PR) back to stash for the next iteration
git stash push -u -m "ship: remaining"

git push -u origin <branch-name>
gh pr create [--draft] --title "..." --body "..."
```

After the last PR: `git stash list` should be empty. Anything left is a skipped file or a planning miss — surface to user. Then:

```bash
git checkout "$DEFAULT_BRANCH"
```

### Multi-PR execution (stacked)

Stacked PRs are created **one-at-a-time with explicit approval between each**. This lets the user wait for CI, address review feedback, or rebase before the next layer.

```
1. Plan: PR1 base = $DEFAULT_BRANCH, PR2 base = PR1's branch, PR3 base = PR2's branch, ...
2. Stash the working tree (same as non-stacked).
3. Execute PR1:
   - Branch off $DEFAULT_BRANCH
   - stash pop, stage PR1 files, commit
   - stash remaining
   - push, `gh pr create --base "$DEFAULT_BRANCH"`
   - Return to $DEFAULT_BRANCH
4. ASK USER: "PR1 created at <url>. Ready to create PR2 on top? (y/n)"
5. WAIT for approval. If user says no/wait, stop. The remaining changes are safely in the stash; `/ship` can be resumed later.
6. Execute PR2:
   - Branch off PR1's branch (not $DEFAULT_BRANCH)
   - stash pop, stage PR2 files, commit
   - stash remaining
   - push, `gh pr create --base <PR1-branch>`
7. Repeat ASK → WAIT → Execute for each subsequent PR.
```

When fully done (or user stops): `git checkout "$DEFAULT_BRANCH"`.

---

## Phase 5: Finish

After all PRs are created, output a summary and end on `$DEFAULT_BRANCH`:

```text
## Created
- PR #101: feat: add pay-invoice flow — https://github.com/.../pull/101
- PR #102: fix: prod-down blue/green handling — https://github.com/.../pull/102

## Skipped
- .claude/settings.json (editor config)
- email-updates/... (personal note)

## Current state
- On branch: <default-branch> (clean)
- Stashes: <none / list any remaining>
```

If any stash entries remain (e.g., user stopped a stacked-PR flow midway), list them explicitly so the user knows where to resume.

---

## Commit Grouping Rules

Group by **logical concern**, not by file type:

- A feature's service + schema + types + API route + hook + component = ONE commit
- Infrastructure changes (Makefile, Docker, CI) = separate commit
- Test-only changes = separate commit (unless tests accompany a feature)
- Dependency changes (package.json/lock) go with the commit that needs them
- Unrelated bug fixes = separate commit each

Single-PR mode: 2–5 commits is the sweet spot.
Multi-PR mode: 1–5 commits per PR; each PR should be a coherent, independently reviewable unit.

---

## Commit Message Format

```text
type(scope): imperative summary (≤72 chars)

- Why bullet 1
- Why bullet 2
- Why bullet 3
```

- **type**: feat, fix, refactor, chore, docs, test, ci
- **scope**: most relevant folder/module (omit if unclear)
- **Subject**: imperative mood — "add", "fix", "remove" (not "added", "fixes")
- **Body**: explains **why**, not what (the diff shows what)
- **72 char subject line** — hard limit

Good examples:

- `feat(ledger): add single-invoice payment with partial support`
- `fix(deploy): handle blue/green slots in prod-down target`
- `ci: add Docker image publish workflow`

Bad examples:

- `update files` (vague)
- `fix stuff` (meaningless)
- `feat: added new payment feature for paying invoices individually with support for partial payments` (too long)

---

## PR Description Format

**If the repo has `.github/PULL_REQUEST_TEMPLATE.md`, use that file's contents as the body skeleton instead of the default below.** Read it, fill in the placeholders, and submit.

Default template:

```markdown
## Summary

<!-- Use **bold lead** with em-dash for each major change -->

- **[Change heading]** — Description of what and why

### Files changed

<!-- Include for PRs touching 3+ files. Delete section for small PRs -->

| File              | Change       |
| ----------------- | ------------ |
| `path/to/file.ts` | What changed |

### Notes

<!-- Optional — env var updates, breaking changes, migration steps. Delete if not needed -->

## Test plan

- [ ] Automated tests passing
- [ ] Manual UI verification
- [ ] Edge cases covered
```

When generating the actual PR body:

- **Strip all HTML comments** — they're authoring guidance, not for the published PR
- Fill placeholders with real content (bold-lead bullets, real filenames, real test steps)
- Delete optional sections (`### Files changed`, `### Notes`) if they don't apply
- Append `Closes #N` (one per line) below the Summary section if Phase 3 identified linked issues

Always use a HEREDOC for the body:

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary

- **Feature heading** — Detailed description of what and why

## Test plan

- [ ] Automated tests passing
- [ ] Manual UI verification

Closes #123
EOF
)"
```

PR title should reflect the **primary** change. If multiple concerns end up in one PR, use the most significant one.

---

## Hard Rules

1. **Detect the default branch dynamically** with `git symbolic-ref refs/remotes/origin/HEAD` — never hardcode `main`
2. **Always start from up-to-date default branch**: `git checkout $DEFAULT_BRANCH && git pull --ff-only`
3. **Never commit editor/personal files**: `.claude/settings.json`, scratch notes, email drafts
4. **Never force push** without explicit user consent
5. **Never skip hooks** (`--no-verify`) without asking first and explaining why
6. **Never push to the default branch directly** — always feature branch + PR
7. **Present the plan first** — don't execute until user approves
8. **Stage specific files** — never use `git add -A` or `git add .`
9. **Always use HEREDOC** for commit messages and PR bodies (preserves formatting)
10. **Stacked PRs: one at a time with explicit approval** between each layer — never batch a stack
11. **End on the default branch** after the PR loop completes
12. **No AI attribution** — never include `Co-Authored-By: Claude`, `Generated with Claude Code`, robot emoji footers, or any indication AI assisted. Applies to commits, PR bodies, branch names, and code comments.

---

## Edge Cases

- **Single concern**: 1 commit, 1 PR — don't force-split
- **Already on a feature branch with commits**: Phase 1 surfaces this via `gh pr view`. If a PR is already open, ask whether to add commits to it or close it and start fresh. If no PR yet, skip branch creation, analyze existing commits, push + PR
- **Branch name collision**: detected in Phase 3 via `git ls-remote --heads origin <name>` + local check. Append `-2` or ask
- **Nothing to commit**: Say so and stop
- **Mixed staged/unstaged**: Include both in analysis, stage during execution
- **Changes on a dirty branch**: Stash unrelated changes, or ask user how to proceed
- **One file changed**: Still create a proper branch + PR, just 1 commit
- **Branch behind remote**: `git pull --ff-only` before branching; if non-fast-forward, surface to user
- **PR-target branch differs from default**: ask which base to use (`gh pr create --base <branch>`)
- **Overlapping files between PRs**: Surface in Phase 3 — ask whether to combine, or plan `git add -p` for hunk-level splits
- **`gh` not authenticated**: Pre-flight catches this — ask user to run `gh auth login` before retrying
- **Draft PR**: ask in Phase 3; use `gh pr create --draft`
- **Stacked PR paused mid-flow**: stash remains intact. Resuming `/ship` later picks up from the next layer
