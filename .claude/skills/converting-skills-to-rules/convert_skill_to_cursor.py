#!/usr/bin/env python3
"""
Convert Claude Skills to Cursor rules (.mdc files)
"""

import os
import re
import sys
from pathlib import Path


def extract_skill_info(skill_content):
    """Extract frontmatter description and content from SKILL.md file"""
    # Match frontmatter block
    frontmatter_pattern = r'^---\n(.*?)\n---\n(.*)$'
    match = re.match(frontmatter_pattern, skill_content, re.DOTALL)

    if not match:
        # No frontmatter found, use entire content
        return "", skill_content

    frontmatter_text = match.group(1)
    content = match.group(2)

    # Extract description from frontmatter
    description_match = re.search(r'^description:\s*(.+)$', frontmatter_text, re.MULTILINE)
    description = description_match.group(1).strip() if description_match else ""

    return description, content


def convert_skill_to_cursor(skill_dir, output_file=None):
    """Convert a skill directory to a Cursor rule .mdc file"""
    skill_path = Path(skill_dir)

    if not skill_path.exists():
        print(f"Error: Skill directory '{skill_dir}' does not exist")
        return False

    if not skill_path.is_dir():
        print(f"Error: '{skill_dir}' is not a directory")
        return False

    # Read SKILL.md
    skill_md_path = skill_path / "SKILL.md"
    if not skill_md_path.exists():
        print(f"Error: SKILL.md not found in '{skill_dir}'")
        return False

    with open(skill_md_path, 'r', encoding='utf-8') as f:
        skill_content = f.read()

    # Extract description and content
    description, content = extract_skill_info(skill_content)

    if not description:
        print(f"Warning: No description found in {skill_md_path}")

    # Determine output file path
    if output_file is None:
        output_file = f"{skill_path.name}.mdc"

    output_path = Path(output_file)

    # Create cursor rule content
    cursor_content = f"""---
description: {description}
alwaysApply: false
---

{content.strip()}
"""

    # Write .mdc file
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(cursor_content)

    print(f"✓ Converted {skill_path.name} -> {output_path}")
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: convert_skill_to_cursor.py <skill-directory> [output-file]")
        print("\nExamples:")
        print("  convert_skill_to_cursor.py swift-6.2-arc-reference")
        print("  convert_skill_to_cursor.py swift-6.2-arc-reference cursor-rules/swift-6.2-arc-reference.mdc")
        sys.exit(1)

    skill_dir = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    success = convert_skill_to_cursor(skill_dir, output_file)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
