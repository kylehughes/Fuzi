---
name: configuring-claude-code-subagents
description: Creates and configures custom Claude Code subagents for task-specific workflows. This skill applies when designing subagent configurations, defining subagent file structure, setting up tool permissions, or troubleshooting subagent behavior in Claude Code.
---

# Configuring Claude Code Subagents

Subagents are specialized AI assistants that Claude Code can delegate tasks to. Each subagent operates in its own context window with a custom system prompt and specific tool access.

## When to Use Subagents

- **Context preservation**: Keep the main conversation focused on high-level objectives
- **Specialized expertise**: Fine-tune detailed instructions for specific domains
- **Reusability**: Share consistent workflows across projects and teams
- **Flexible permissions**: Limit powerful tools to specific subagent types

## Quick Start

1. Run `/agents` to open the subagent management interface
2. Select "Create New Agent" and choose project-level or user-level
3. Define the subagent (generate with Claude, then customize)
4. Use automatically when appropriate, or invoke explicitly:
   ```
   > Use the code-reviewer subagent to check my recent changes
   ```

## File Locations

| Type | Location | Scope |
|:-----|:---------|:------|
| **Project subagents** | `.claude/agents/` | Current project only |
| **User subagents** | `~/.claude/agents/` | All projects |

Project-level subagents take precedence when names conflict.

## File Format

Each subagent is a Markdown file with YAML frontmatter:

```markdown
---
name: your-sub-agent-name
description: Description of when this subagent should be invoked
tools: Read, Grep, Glob, Bash  # Optional - inherits all if omitted
model: sonnet  # Optional: sonnet, opus, haiku, or inherit
permissionMode: default  # Optional: default, acceptEdits, bypassPermissions, plan, ignore
skills: skill1, skill2  # Optional - auto-load these skills
---

Your subagent's system prompt goes here. This should clearly define
the subagent's role, capabilities, and approach to solving problems.
```

### Required Fields

| Field | Description |
|:------|:------------|
| `name` | Unique identifier: lowercase letters and hyphens only |
| `description` | Natural language description of purpose. Include "use PROACTIVELY" for automatic delegation |

### Optional Fields

| Field | Description |
|:------|:------------|
| `tools` | Comma-separated list. If omitted, inherits all tools from main thread |
| `model` | Model alias (`sonnet`, `opus`, `haiku`) or `inherit`. Default: `sonnet` |
| `permissionMode` | Controls permission handling for the subagent |
| `skills` | Skills to auto-load when subagent starts |

## Built-in Subagents

### Explore Subagent

Fast, read-only agent for codebase navigation:

- **Model**: Haiku (low latency)
- **Tools**: Glob, Grep, Read, limited Bash (ls, git status, find, cat, head, tail)
- **Thoroughness levels**: quick, medium, very thorough

### General-Purpose Subagent

Capable agent for complex, multi-step tasks:

- **Model**: Sonnet
- **Tools**: All tools
- **Mode**: Can read and write files, execute commands

### Plan Subagent

Research agent used during plan mode:

- **Model**: Sonnet
- **Tools**: Read, Glob, Grep, Bash
- **Purpose**: Gathers codebase context before presenting a plan

## CLI Configuration

Define subagents dynamically without files:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer. Focus on code quality and security.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

## Best Practices

1. **Generate first**: Use Claude to generate initial subagent, then customize
2. **Single responsibility**: Each subagent should have one clear purpose
3. **Detailed prompts**: Include specific instructions, examples, and constraints
4. **Limit tools**: Only grant tools necessary for the subagent's purpose
5. **Version control**: Check project subagents into source control

## Resumable Subagents

Continue previous conversations using `agentId`:

```
> Resume agent abc123 and continue analyzing the codebase
```

Agent transcripts are stored in the project directory as `agent-{agentId}.jsonl`.

## Example Configurations

For complete example subagent configurations (code-reviewer, debugger, data-scientist), see [REFERENCE.md](REFERENCE.md).
