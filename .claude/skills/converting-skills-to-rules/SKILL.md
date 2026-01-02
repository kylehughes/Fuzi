---
name: converting-skills-to-rules
description: Convert Claude Skills to Cursor rules. Compiles a skill directory into a single .mdc file with proper frontmatter. Use when you need to export skills for use in Cursor IDE.
---

# Skill to Cursor Rule Converter

This skill provides a script to convert Claude Skills (SKILL.md format) back to Cursor rules (.mdc format).

## Usage

Run the conversion script from the repository root:

```bash
python3 skills/converting-skills-to-rules/convert_skill_to_cursor.py <skill-directory> [output-file]
```

### Arguments

- `skill-directory`: Path to the skill directory containing SKILL.md
- `output-file` (optional): Output .mdc file path. If not provided, creates a file in the current directory with the skill name.

### Examples

```bash
# Convert a skill to .mdc in current directory
python3 skills/converting-skills-to-rules/convert_skill_to_cursor.py skills/my-skill

# Specify output location
python3 skills/converting-skills-to-rules/convert_skill_to_cursor.py skills/my-skill cursor-rules/my-skill.mdc

# Convert multiple skills
for skill in skills/*/; do
  name=$(basename "$skill")
  python3 skills/converting-skills-to-rules/convert_skill_to_cursor.py "$skill" "cursor-rules/$name.mdc"
done
```

## What It Does

The script:
1. Reads the SKILL.md file from the specified directory
2. Extracts the description from the skill's frontmatter
3. Compiles all content (excluding the skill frontmatter) into a single .mdc file
4. Adds proper Cursor rule frontmatter with `description` and `alwaysApply: false`

## Output Format

The generated .mdc file will have this structure:

```markdown
---
description: <extracted from skill>
alwaysApply: false
---

<rest of skill content>
```
