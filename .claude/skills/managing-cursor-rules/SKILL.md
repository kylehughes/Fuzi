---
name: managing-cursor-rules
description: Create and organize Cursor rules that provide persistent AI context. Use when working with .cursor/rules directories, MDC rule files, AGENTS.md, team rules, or when setting up project-specific AI instructions in Cursor.
---

# Managing Cursor Rules

Rules provide system-level instructions to Cursor's Agent. They are persistent context, preferences, or workflows for projects.

## Rule Types Overview

| Type | Location | Scope | Format |
|------|----------|-------|--------|
| Project Rules | `.cursor/rules/*.mdc` | Repository | MDC with metadata |
| User Rules | Cursor Settings → Rules | All projects | Plain text |
| Team Rules | Cursor Dashboard | Organization | Plain text |
| AGENTS.md | Project root or subdirs | Directory tree | Markdown |

## Project Rules

Project rules live in `.cursor/rules/`. Each rule is a version-controlled MDC file.

### MDC Format

MDC (Markdown with Config) combines YAML frontmatter with markdown content:

```mdc
---
description: RPC Service boilerplate
globs:
alwaysApply: false
---

- Use our internal RPC pattern when defining services
- Always use snake_case for service names.

@service-template.ts
```

### Rule Application Types

Control how rules apply via the `alwaysApply` and `globs` properties:

| Type | When Applied |
|------|--------------|
| Always Apply | Every chat session (`alwaysApply: true`) |
| Apply Intelligently | Agent decides based on `description` |
| Apply to Specific Files | When file matches `globs` pattern |
| Apply Manually | Only when @-mentioned |

### Nested Rules

Organize rules throughout your project. Nested rules auto-attach when files in their directory are referenced:

```
project/
  .cursor/rules/        # Project-wide rules
  backend/
    server/
      .cursor/rules/    # Backend-specific rules
  frontend/
    .cursor/rules/      # Frontend-specific rules
```

### Creating Rules

- Use `New Cursor Rule` command, or
- Navigate to `Cursor Settings > Rules`

## AGENTS.md

A simpler alternative using plain markdown. Place in project root or subdirectories.

```markdown
# Project Instructions

## Code Style
- Use TypeScript for all new files
- Prefer functional components in React
- Use snake_case for database columns

## Architecture
- Follow the repository pattern
- Keep business logic in service layers
```

Nested AGENTS.md files combine with parent directories, more specific instructions taking precedence.

## User Rules

Global preferences in **Cursor Settings → Rules**. Apply to Agent (Chat) across all projects.

```
Please reply in a concise style. Avoid unnecessary repetition or filler language.
```

Note: User Rules do NOT apply to Inline Edit (Cmd/Ctrl+K).

## Team Rules

Available on Team and Enterprise plans. Managed from the Cursor dashboard.

- **Plain text format** (no MDC metadata)
- Apply to Agent (Chat) across all repositories
- Can be **enforced** (required) or optional for team members

### Precedence

Rules merge in this order (earlier takes precedence on conflicts):
1. Team Rules
2. Project Rules
3. User Rules

## Best Practices

- Keep rules under 500 lines
- Split large rules into multiple, composable rules
- Provide concrete examples or reference files via `@filename`
- Write clear, actionable guidance (like internal docs)
- Scope rules appropriately using globs or nesting

## Migration

The `.cursorrules` file in project root is deprecated. Migrate to:
- `.cursor/rules/` for structured rules with metadata
- `AGENTS.md` for simple markdown instructions
