# Cursor Rules Reference

Extended examples and patterns for managing Cursor rules.

## Example: Frontend Components and API Validation Standards

```mdc
---
description: Standards for frontend components and API validation
globs: ["src/components/**/*.tsx", "src/api/**/*.ts"]
alwaysApply: false
---

## Component Standards
- All components must have TypeScript interfaces for props
- Use React.FC pattern with explicit return types
- Implement error boundaries for data-fetching components

## API Validation
- Validate all incoming request bodies with Zod schemas
- Return consistent error response format
- Log validation failures with request context
```

## Example: Express Service Template

```mdc
---
description: Template for Express service endpoints
globs: ["src/services/**/*.ts"]
alwaysApply: false
---

When creating new Express services:

1. Use the service template pattern in @service-template.ts
2. Include health check endpoint
3. Implement standard middleware stack:
   - Request logging
   - Error handling
   - Authentication (when required)

@templates/service-template.ts
@templates/middleware-stack.ts
```

## Example: React Component Template

```mdc
---
description: Template for React components
globs: ["src/components/**/*.tsx"]
alwaysApply: false
---

New React components should follow this structure:

@templates/component-template.tsx

Key requirements:
- Export named component (not default)
- Props interface above component
- Use memo() for list items
- Include displayName for debugging
```

## Example: Development Workflow Automation

```mdc
---
description: Automating development workflows and documentation generation
alwaysApply: false
---

## PR Creation Workflow
1. Run linter: `npm run lint`
2. Run tests: `npm test`
3. Update CHANGELOG.md with changes
4. Create PR with template from @.github/pull_request_template.md

## Documentation Generation
When adding new features:
1. Update relevant .md files in docs/
2. Add JSDoc comments to public APIs
3. Update README if adding CLI commands
```

## Example: Adding Settings (Cursor-specific)

This example shows how Cursor's own codebase uses rules for internal workflows:

```mdc
---
description: Adding a new setting in Cursor
alwaysApply: false
---

First create a property to toggle in @reactiveStorageTypes.ts.

Add default value in `INIT_APPLICATION_USER_PERSISTENT_STORAGE` in @reactiveStorageService.tsx.

For beta features, add toggle in @settingsBetaTab.tsx, otherwise add in @settingsGeneralTab.tsx.

Toggles can be added as `<SettingsSubSection>`:

\`\`\`tsx
<SettingsSubSection
  label="Your feature name"
  description="Your feature description"
  value={
    vsContext.reactiveStorageService.applicationUserPersistentStorage
      .myNewProperty ?? false
  }
  onChange={(newVal) => {
    vsContext.reactiveStorageService.setApplicationUserPersistentStorage(
      "myNewProperty",
      newVal,
    );
  }}
/>
\`\`\`

To use in the app:

\`\`\`tsx
const flagIsEnabled =
  vsContext.reactiveStorageService.applicationUserPersistentStorage
    .myNewProperty;
\`\`\`
```

## Directory Structure Patterns

### Monorepo with Multiple Apps

```
monorepo/
  .cursor/rules/
    code-style.mdc          # Org-wide style
    security.mdc            # Security guidelines
  apps/
    web/
      .cursor/rules/
        react-patterns.mdc  # React-specific
    api/
      .cursor/rules/
        api-design.mdc      # API-specific
  packages/
    shared/
      .cursor/rules/
        library-exports.mdc # Package conventions
```

### Full-Stack Application

```
project/
  AGENTS.md                 # High-level project context
  .cursor/rules/
    testing.mdc             # Testing conventions
  frontend/
    AGENTS.md               # Frontend architecture
    .cursor/rules/
      components.mdc        # Component patterns
  backend/
    AGENTS.md               # Backend architecture
    .cursor/rules/
      database.mdc          # DB conventions
      api.mdc               # API patterns
```

## Team Rules Configuration

### Enforced Compliance Rules

Team admins can create enforced rules for organizational standards:

**Code Review Standards** (Enforced)
```
All code changes must:
- Include unit tests for new functionality
- Pass linting without warnings
- Have at least one approval before merge
- Include JIRA ticket reference in commit message
```

**Security Guidelines** (Enforced)
```
Never commit:
- API keys, secrets, or credentials
- Personal data in test fixtures
- Hardcoded environment-specific values

Always:
- Use parameterized queries for database access
- Validate and sanitize user input
- Log security-relevant events
```

### Optional Team Preferences

**Code Style Preferences** (Not Enforced)
```
Preferred patterns:
- Functional components over class components
- Named exports over default exports
- Async/await over .then() chains
```

## FAQ

### Why isn't my rule being applied?

- Check that `alwaysApply: true` is set, or
- Verify `globs` pattern matches your files, or
- Ensure `description` is clear enough for intelligent application
- For nested rules, confirm the `.cursor/rules/` directory exists in the right location

### Can rules reference other rules or files?

Yes, use `@filename` syntax to reference files. The referenced file content becomes available to the Agent.

### Do rules impact Cursor Tab or other AI features?

Project Rules primarily affect Agent (Chat). Tab completions use different context.

### Can I create a rule from chat?

Yes, ask Agent to create a rule and it can write to `.cursor/rules/`.
