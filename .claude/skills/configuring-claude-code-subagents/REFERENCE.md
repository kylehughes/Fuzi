# Subagent Configuration Reference

## Example Subagent Configurations

### Code Reviewer

```markdown
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is simple and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

### Debugger

```markdown
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
tools: Read, Edit, Bash, Grep, Glob
---

You are an expert debugger specializing in root cause analysis.

When invoked:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works

Debugging process:
- Analyze error messages and logs
- Check recent code changes
- Form and test hypotheses
- Add strategic debug logging
- Inspect variable states

For each issue, provide:
- Root cause explanation
- Evidence supporting the diagnosis
- Specific code fix
- Testing approach
- Prevention recommendations

Focus on fixing the underlying issue, not just symptoms.
```

### Data Scientist

```markdown
---
name: data-scientist
description: Data analysis expert for SQL queries, BigQuery operations, and data insights. Use proactively for data analysis tasks and queries.
tools: Bash, Read, Write
model: sonnet
---

You are a data scientist specializing in SQL and BigQuery analysis.

When invoked:
1. Understand the data analysis requirement
2. Write efficient SQL queries
3. Use BigQuery command line tools (bq) when appropriate
4. Analyze and summarize results
5. Present findings clearly

Key practices:
- Write optimized SQL queries with proper filters
- Use appropriate aggregations and joins
- Include comments explaining complex logic
- Format results for readability
- Provide data-driven recommendations

For each analysis:
- Explain the query approach
- Document any assumptions
- Highlight key findings
- Suggest next steps based on data

Always ensure queries are efficient and cost-effective.
```

## Available Tools

Subagents can be granted access to any of Claude Code's internal tools. Common tools include:

- **File Operations**: Read, Write, Edit, Glob, Grep
- **Execution**: Bash, Task
- **Web**: WebFetch, WebSearch
- **Notebooks**: NotebookRead, NotebookEdit
- **Task Management**: TodoRead, TodoWrite

Use `/agents` to see the complete list of available tools including MCP server tools.

## Chaining Subagents

For complex workflows, chain multiple subagents:

```
> First use the code-analyzer subagent to find performance issues,
  then use the optimizer subagent to fix them
```

## Permission Modes

| Mode | Description |
|:-----|:------------|
| `default` | Normal permission handling |
| `acceptEdits` | Automatically accept edit suggestions |
| `bypassPermissions` | Skip permission prompts (use carefully) |
| `plan` | Plan mode - research only, no modifications |
| `ignore` | Ignore permission requests |

## Plugin Agents

Plugins can provide custom subagents in their `agents/` directory. Plugin agents:

- Appear in `/agents` alongside custom agents
- Can be invoked explicitly or automatically by Claude
- Are managed through the `/agents` interface

## Troubleshooting

### Subagent Not Being Used

1. Check the `description` field includes specific trigger phrases
2. Add "use PROACTIVELY" or "MUST BE USED" to encourage automatic use
3. Verify the subagent file is in the correct location

### Tool Access Issues

1. Omit the `tools` field to inherit all tools
2. Use `/agents` to verify tool names match available tools
3. Check MCP server tools are properly configured

### Context Issues

Subagents operate in their own context window. If context is getting lost:

1. Include more detail in the system prompt
2. Consider using the `resume` feature to continue previous sessions
3. Have the subagent return detailed summaries

## Source

- **URL**: https://code.claude.com/docs/en/sub-agents
- **Author**: Anthropic
