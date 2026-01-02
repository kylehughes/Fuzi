---
name: ordering-swift-symbols
description: Applies deterministic lexicographic ordering to Swift symbols when writing or editing Swift code. Use when creating new Swift types (class/struct/enum/extension) or refactoring existing ones to maintain consistent symbol ordering throughout the codebase.
---

# Swift Lexicographic Symbol Ordering

Maintain deterministic, lexicographic ordering of symbols in Swift code wherever re-ordering is semantics-preserving. Apply this ordering convention when writing new Swift files or editing existing ones to ensure consistent code organization across the codebase.

## When to Apply

Apply lexicographic ordering when:
- Writing new Swift types (classes, structs, enums, extensions)
- Refactoring or reorganizing existing Swift code
- Reviewing code to ensure consistent organization
- Adding new members to existing types

**Critical:** Only reorder when it's safe to do so. Never reorder if it would break compilation, change runtime behavior, or violate required ordering (e.g., `super.init()` must remain in its required position).

**Exception – Function and Initializer Parameters:** Parameter lists are the one place where semantic ordering takes precedence. Common patterns like putting `id` first, grouping related parameters together, or following API conventions are often clearer than strict alphabetization. Apply lexicographic ordering to parameters only when no obvious semantic ordering exists—when the choice feels arbitrary, alphabetization provides a consistent fallback.

## Ordering Rules

### 1. Within Type Declarations (class / struct / enum)

Order members in this sequence:

1. **typealiases** – alphabetical by name

2. **stored properties**
   - Group order: static let → static var → instance let → instance var
   - Within each group: public → internal → fileprivate → private
   - Within each access level: alphabetical by identifier
   - Importantly: NOT LAZY PROPERTIES.

3. **initializers** (`init` and `deinit`)
   - Order by access level first: public → internal → fileprivate → private
   - Within each access level: alphabetical (e.g., `init()` before `init(coder:)`)

4. **implementation details**
   - **Lazy properties** come before computed properties.
   - **Computed properties** come before methods
     - Group: static before instance
     - Access level: public → internal → fileprivate → private
     - Alphabetical within each access level
   - **Methods / functions**
     - Group: static before instance
     - Access level: public → internal → fileprivate → private
     - Alphabetical within each access level

### 2. File-Level Extensions

Order extensions at file scope:

1. **Protocol conformance extensions** – alphabetical by protocol name
   - Each extension internally follows the type-level ordering rules above

2. **Extensions with nested types** – alphabetical by the inner type name

### 3. Function and Initializer Parameters

**Prefer semantic ordering.** Unlike other symbols, parameter order directly affects readability and API ergonomics. Consider:

- **Identity first**: `id`, `identifier`, or primary keys often belong at the start
- **Required before optional**: Parameters without defaults before those with defaults
- **Logical grouping**: Related parameters adjacent (e.g., `width, height` or `startDate, endDate`)
- **Convention alignment**: Match patterns from Apple frameworks or the existing codebase

**Fall back to lexicographic ordering** only when:
- No semantic relationship is apparent
- Parameters feel interchangeable or arbitrary
- You're unsure which order is clearer

When in doubt about parameter order, ask rather than reflexively alphabetizing.

### 4. Inside Function/Initializer Bodies

When statements are independent (no data or side-effect dependencies):
- Sort constant/variable declarations (`let`/`var`) lexicographically
- Sort array/dictionary literal elements (e.g., in `NSLayoutConstraint.activate([...])`)
  - Sort first by variable/receiver name
  - Then by called method/selector

**Never reorder** when there are dependencies that would change behavior.

### 5. General Notes

- Use standard ASCII/Unicode code-point ordering for "alphabetical"
- Correctness takes precedence: preserve original order if reordering would break the code
- When uncertain about safety, ask for confirmation rather than risking incorrect reordering

## Examples

For detailed examples of correct ordering patterns, see [REFERENCE.md](REFERENCE.md).

## Application Strategy

When writing or editing Swift code:

1. **Start with the structure** - Place members in the correct category order (typealiases → properties → initializers → computed properties → methods)

2. **Apply access level ordering** - Within each category, group by access level (public → internal → fileprivate → private)

3. **Sort alphabetically** - Within each access level group, sort members alphabetically by name

4. **Verify safety** - Before reordering, confirm that the change won't affect behavior or break dependencies

5. **When unsure** - Ask for confirmation rather than making potentially unsafe changes
