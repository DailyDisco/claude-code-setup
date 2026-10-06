# Codex adapter

Read routed rules explicitly. Use `$skill-name` or /skills; legacy /skill-name
text means load that skill's SKILL.md, not a shell command. Read supplemental
project .claude/CLAUDE.md when applicable. AGENTS.md retains native precedence.

## Tool mapping

- Read/Glob/Grep: available file tools or rg; Bash: available shell tool.
- Edit/Write: available patch or file editor; TodoWrite: native plan tracking.
- AskUserQuestion: the available clarification tool, or a concise question.
- Skill: read the named SKILL.md and applicable requires rule paths explicitly.
- Agent/Task: native delegation only when authorized and available. Do not
  pretend Claude agent names or model aliases are Codex model names.
- mcp__ names: discover the equivalent installed connector. Names and OAuth
  sessions are not portable. Stop dependent work if the connection is missing.
- allowed-tools/requires/triggers/emits are not Codex runtime configuration.

## Workflows needing special handling

- firm: the active assistant coordinates and verifies. Model names in the
  skill identify the original Claude coordinator, not the running model.
  Preserve explicitly requested model/provider choices. Check worker CLI/auth
  and actual model availability before launch. Never import permission-bypass
  flags as defaults. If required workers are absent, report it and seek a
  concrete alternative instead of claiming delegation.
- dbhub-setup: .mcp.json examples are Claude-specific. For Codex, inspect
  `codex mcp --help` and current official configuration guidance, register the
  equivalent server in Codex, and verify discovery. Keep DSNs in the local
  environment; do not assume .env.agent is automatically sourced.
- workflow: Claude's hook state helper is not a Codex persistence backend.
  Record progress in a project-specific Markdown file under
  ~/.local/state/agent-workflows/ and explicitly read it on resume. Never
  overwrite Claude workflow state. The commit skill drafts text only.
- health: audits Claude storage; it does not clean Codex or this repo.
- init-project/doc-refresh: create or update project AGENTS.md for Codex;
  use a small CLAUDE.md adapter when both tools should share project guidance.
- prompt: requires a local ~/.claude/prompts library. Check it exists.

Claude hooks do not run in Codex. Run the project's formatter, lint/type
checks and relevant tests explicitly. Preserve Codex permissions, models,
profiles, planning guidance and MCP/auth settings in its local configuration.
