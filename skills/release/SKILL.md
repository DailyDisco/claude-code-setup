---
name: release
description: Prepare a release with changelog generation, version bump, and release notes
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(npm version:*), Bash(gh:*), Glob, Grep
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Release Preparation

> **Safety Note**: This skill prepares releases for review. Never push tags or publish packages automatically without explicit user confirmation.

Prepare a new release with proper versioning, changelog, and release notes.

## Process

### 1. Determine Version Bump

Analyze commits since last release to determine version bump:

| Commit Type | Version Bump |
|-------------|--------------|
| `feat:` | Minor (1.x.0) |
| `fix:` | Patch (1.0.x) |
| `BREAKING CHANGE:` | Major (x.0.0) |

Ask user to confirm version if unclear.

### 2. Generate Changelog

Collect commits since last tag:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Group by type:
- **Features**: `feat:` commits
- **Bug Fixes**: `fix:` commits
- **Breaking Changes**: commits with `BREAKING CHANGE:`
- **Other**: `docs:`, `refactor:`, `chore:`

### 3. Update CHANGELOG.md

```markdown
## [1.2.0] - 2025-01-01

### Added
- Feature description (#123)

### Fixed
- Bug fix description (#124)

### Changed
- Change description (#125)

### Breaking Changes
- Breaking change with migration guide
```

### 4. Bump Version

For npm projects:
```bash
npm version [major|minor|patch] --no-git-tag-version
```

For other projects, update version in appropriate file.

### 5. Create Release Commit

```bash
git add -A
git commit -m "chore: release v1.2.0"
git tag -a v1.2.0 -m "Release v1.2.0"
```

### 6. Generate Release Notes

Create GitHub release (if using gh CLI):

```bash
gh release create v1.2.0 --title "v1.2.0" --notes-file RELEASE_NOTES.md
```

## Output

- Updated `CHANGELOG.md`
- Version bump in package.json/pyproject.toml/etc.
- Release commit and tag (ready to push)
- Release notes summary
