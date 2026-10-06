# Claude Code setup

The rules, skills, hooks and agents I use with Claude Code every day, with everything specific to my machines and clients taken out. It is a working setup, not a framework. Take the parts you like.

## What is in here

| Folder | Contents |
|---|---|
| `rules/` | 16 rule files: core principles, git, testing, security, performance and preferred stacks, plus one each for TypeScript, React, React Native, Go, Python, Docker, databases, APIs, CI/CD and accessibility |
| `skills/` | 42 skills, each a `SKILL.md` that is loaded on demand: project bootstrap, commits and pull requests, debugging, audits, planning and documentation |
| `hooks/` | 45 hook scripts for Claude Code events, plus shared helpers. `hooks/README.md` lists which event each one belongs to |
| `agents/` | Six specialist agents: API, code review, database, front end, infrastructure and security |
| `commands/` | Four quick prompts: explain, quick-fix, compare and benchmark |
| `prompts/` | Six longer checklists used by the `prompt` skill |
| `adapters/` | Short notes that let the same skills run under Claude Code and Codex |

## Where to start

- `rules/core.md` is the one I would read first. It covers stopping to ask when something is unclear, keeping changes surgical, and turning vague tasks into goals that can be checked.
- `rules/testing.md`, `rules/security.md` and `rules/git.md` are short and apply to any stack.
- `skills/commit` and `skills/ship` cover the path from a working tree to a reviewed pull request.
- `skills/debug`, `skills/review-pr` and `skills/refactor` are the ones I reach for most.
- `skills/reskin` applies a brand direction from reference images to a Tailwind and shadcn/ui app.
- `hooks/commit-guard.sh` enforces conventional commit messages, `hooks/build-test-gate.sh` runs the build and tests before a commit, and `hooks/commit-size.sh` warns about large commits.

## Install

The skills refer to the rules and adapters through `~/.config/agent-config`, so link the clone there.

```bash
git clone https://github.com/DailyDisco/claude-code-setup ~/agent-config
ln -s ~/agent-config ~/.config/agent-config

# Claude Code
ln -s ~/agent-config/skills ~/.claude/skills
ln -s ~/agent-config/rules ~/.claude/rules
cp -r ~/agent-config/agents/. ~/.claude/agents/
cp -r ~/agent-config/commands/. ~/.claude/commands/
cp -r ~/agent-config/prompts ~/.claude/prompts
cp -r ~/agent-config/hooks ~/.claude/hooks
```

If you already have files in those folders, copy individual skills or rules across instead of linking the whole folder.

Hooks do nothing until they are registered in `~/.claude/settings.json`. `hooks/README.md` shows the event for each one. My own `settings.json` is not included because it holds machine-specific permissions.

## Things you will want to change

- `rules/stacks.md` is my own list of preferred libraries. Replace it with yours.
- The hooks assume `git`, `jq` and the usual Node, Go and Python tooling are installed. Read a hook before you register it.
- `skills/github-pr`, `skills/jira-sync` and `skills/dbhub-setup` need their MCP servers connected.
- The agents name a model in their front matter. Adjust it to what you have access to.

## License

MIT. See [LICENSE](LICENSE).
