---
name: health
description: Audit and clean up ~/.claude configuration. Check disk usage, find stale files, validate hook configuration, and clean ephemeral data.
allowed-tools: Bash(du:*), Bash(find:*), Bash(wc:*), Bash(ls:*), Bash(rm:*), Bash(mv:*), Bash(head:*), Bash(tail:*), Read, Glob, Grep, AskUserQuestion
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Configuration Health Check

Audit and maintain your ~/.claude configuration directory.

## Commands

### `/health` - Full Health Report

Run a comprehensive health check:

1. **Disk Usage** - Total size and breakdown by category
2. **Stale Files** - Old backups, unused configs
3. **Hook Validation** - Check hooks match settings.json
4. **Skill Inventory** - List all skills with status
5. **Ephemeral Data** - Size of plans/, session-env/, shell-snapshots/

### `/health --storage` - Storage Report Only

Quick disk usage breakdown:

```bash
du -sh ~/.claude/
du -sh ~/.claude/*/
du -sh ~/.claude/hooks/
du -sh ~/.config/agent-config/skills/
```

### `/health --cleanup` - Interactive Cleanup

Safely clean ephemeral data with user confirmation:

1. **Project Memory** (biggest space saver)
   - projects/ directories not accessed in 30+ days
   - Preview: `find ~/.claude/projects -name "memory.json" -mtime +30`
   - Ask before bulk deletion

2. **Debug Logs**
   - debug/*.txt files (often 100s of files)
   - Keep last 50, delete the rest
   - Command: `ls -t ~/.claude/debug/*.txt | tail -n +51 | xargs rm -f`

3. **Session Data**
   - plans/ older than 30 days
   - session-env/ older than 7 days
   - shell-snapshots/ older than 7 days

4. **Metrics Rotation**
   - Rotate hook-metrics.jsonl (keep last 30 days)
   - Rotate skill-metrics.jsonl (keep last 30 days)
   - Archive old metrics to metrics/archive/

5. **Cache & State**
   - cache/ older than 7 days
   - state/aggregator/ older than 1 day
   - workflows/archive/ older than 90 days

### `/health --validate` - Configuration Validation

Check for issues:

- Hooks in settings.json that don't exist as files
- Hook files that aren't wired in settings.json
- Skills with invalid SKILL.md format
- Broken symlinks
- Duplicate skills/commands

## Health Thresholds

| Category | Warning | Critical |
|----------|---------|----------|
| Total ~/.claude size | 500MB | 1GB |
| projects/ size | 500MB | 1GB |
| debug/ file count | 100 | 500 |
| plans/ count | 100 | 500 |
| session-env/ count | 500 | 1000 |
| hook-metrics.jsonl | 5MB | 20MB |
| Individual skill size | 50KB | 100KB |

## Output Format

### Storage Report

```markdown
## ~/.claude Storage Report

**Total Size:** 245MB

| Category | Size | Files |
|----------|------|-------|
| skills/ | 120KB | 36 |
| hooks/ | 85KB | 29 |
| rules/ | 45KB | 19 |
| plans/ | 50MB | 291 |
| session-env/ | 100MB | 1466 |
| metrics/ | 15MB | - |

### Recommendations
- [ ] Clean plans/ older than 30 days (save ~40MB)
- [ ] Rotate hook-metrics.jsonl (save ~10MB)
```

### Validation Report

```markdown
## Hook Validation

### Wired but Missing (ERROR)
- None

### Exists but Not Wired (INFO)
- test-coverage.sh (in hooks/settings.json only)
- hook-debug.sh (manual utility)

### Skills Check
- Total: 36 skills
- Valid: 36
- Invalid: 0
```

## Hard Rules

1. **NEVER** delete without user confirmation
2. **ALWAYS** show what will be deleted before doing it
3. **ALWAYS** check file ages before cleanup
4. Preserve user-created content (skills, hooks, rules)
5. Only clean ephemeral/generated data

## Cleanup Safety

Before deleting anything:

```markdown
## Cleanup Preview

Will delete:
- 150 plan files older than 30 days
- 800 session-env directories older than 7 days
- 5000 lines from hook-metrics.jsonl

Estimated savings: ~120MB

Proceed? [y/N]
```

## Metrics Rotation

When rotating hook-metrics.jsonl:

```bash
# Keep last 30 days
tail -n 10000 ~/.claude/hook-metrics.jsonl > ~/.claude/hook-metrics.jsonl.new
mv ~/.claude/hook-metrics.jsonl ~/.claude/metrics/archive/hook-metrics-$(date +%Y%m%d).jsonl
mv ~/.claude/hook-metrics.jsonl.new ~/.claude/hook-metrics.jsonl
```

## Example Usage

```
User: /health

Claude: Running health check...

## ~/.claude Health Report

### Storage: 245MB (OK)
- skills/: 120KB (36 skills)
- hooks/: 85KB (29 hooks)
- plans/: 50MB (291 files) ⚠️ Consider cleanup
- session-env/: 100MB (1466 dirs) ⚠️ Consider cleanup

### Hooks: All Valid ✓
- 24 hooks wired in settings.json
- 2 utility scripts (not event-driven)

### Recommendations
1. Run `/health --cleanup` to save ~120MB
2. Consider archiving old plans

Run `/health --cleanup` to clean ephemeral data.
```
