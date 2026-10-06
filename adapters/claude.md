# Claude adapter

The skills are written with Claude Code tool names, so no tool mapping is needed here.

- Skills are found through Claude's normal skill discovery.
- Skill metadata named requires, triggers and emits is descriptive. Read the rule files a skill lists explicitly; do not assume the metadata loads them.
- When a skill refers to a tool that is not available, report the dependency or use an available equivalent with the same authorization and verification boundaries.
- Keep `settings.json`, hooks, plugins, custom agents, MCP connections and credentials local to each machine.
