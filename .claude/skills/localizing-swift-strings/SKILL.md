---
name: localizing-swift-strings
description: Extracts hardcoded string literals into localized String extensions using String(localized:bundle:comment:). Use when writing SwiftUI/UIKit code with user-facing strings, refactoring hardcoded text to support localization, or implementing string catalogs in Swift packages. (project)
---

# Localizing Swift Strings

Extract hardcoded string literals from SwiftUI and UIKit code into properly localized `String` extensions.

## What to Localize

**ONLY localize strings displayed to end users.**

### Localize
- UI labels, button titles, navigation titles
- User-facing messages, prompts, placeholders
- Error messages shown to users
- Accessibility labels and hints
- Tooltips and help text

### Do NOT Localize
- Log messages (`.log(...)`, `print(...)`, `dump(...)`)
- Assertions (`assert(...)`, `assertionFailure(...)`)
- Fatal errors (`fatalError(...)`, `preconditionFailure(...)`)
- Developer-facing error messages
- Debug strings and internal diagnostics
- Code comments
- Test strings and `#Preview` blocks

## Process

1. **Identify hardcoded strings** that should be localized (UI text, labels, messages)

2. **Create static properties/functions** in a `fileprivate extension String`:
   - Place after extensions on the file's primary type, sorted lexicographically
   - Use `String(localized:bundle:comment:)` initializer
   - Set `bundle: .module` (required for package modules)
   - Write descriptive but terse comments explaining context
   - Name using camelCase with clear semantic meaning
   - Sort: properties first (lexicographically), then functions (lexicographically)
   - One empty line between each property/function
   - No documentation comments on properties/functions

3. **Replace call sites** with implicit member syntax (e.g., `.taskSaveError`)

4. **Build the package** to auto-generate `Localizable.xcstrings` entries:

   e.g.
   
   ```bash
   xcodebuild -scheme PackageName build
   ```
   
   … or a custom build command, like through `make` or `swift build`.

5. **Configure plurality** (if applicable) by editing `Localizable.xcstrings` directly

## Formatting Rules

- Line wrap at 120 characters
- Keep comments on one line when possible
- Use proper grammar (incomplete sentences allowed for terseness)
- Maintain lexicographic ordering within the extension

## Examples

### Simple Strings

**Before:**
```swift
label.text = "Unable to save"
textField.placeholder = "Enter task name…"
```

**After:**
```swift
label.text = .taskSaveError
textField.placeholder = .taskNamePlaceholder

// At appropriate place in the file:
fileprivate extension String {
    static let taskNamePlaceholder = String(
        localized: "Enter task name…",
        bundle: .module,
        comment: "Placeholder text for the task name text field."
    )

    static let taskSaveError = String(
        localized: "Unable to save",
        bundle: .module,
        comment: "Error displayed when a task fails to save."
    )
}
```

### Strings with Parameters

**Before:**
```swift
label.text = "\(count) tasks remaining"
titleLabel.text = "Assigned to \(userName)"
```

**After:**
```swift
label.text = .tasksRemaining(count: count)
titleLabel.text = .assignedTo(userName: userName)

fileprivate extension String {
    static func assignedTo(userName: String) -> String {
        String(
            localized: "Assigned to \(userName)",
            bundle: .module,
            comment: "Label showing who a task is assigned to."
        )
    }

    static func tasksRemaining(count: Int) -> String {
        String(
            localized: "\(count) tasks remaining",
            bundle: .module,
            comment: "Label showing the number of incomplete tasks."
        )
    }
}
```

### Plural Variations

For strings with counts, use the **singular variant** in code, then configure plurality in the string catalog.

**Step 1: Add localized string with singular variant**
```swift
label.text = .itemCount(count: count)

fileprivate extension String {
    static func itemCount(count: Int) -> String {
        String(
            localized: "\(count) item",
            bundle: .module,
            comment: "Label showing the number of items in a list."
        )
    }
}
```

**Step 2: Build to generate catalog entry**

**Step 3: Add plural variations to Localizable.xcstrings**
```json
"%lld item" : {
  "comment" : "Label showing the number of items in a list.",
  "localizations" : {
    "en" : {
      "variations" : {
        "plural" : {
          "one" : {
            "stringUnit" : {
              "state" : "translated",
              "value" : "%lld item"
            }
          },
          "other" : {
            "stringUnit" : {
              "state" : "translated",
              "value" : "%lld items"
            }
          }
        }
      }
    }
  }
}
```

## Rules

- ALWAYS use `bundle: .module` for package modules
- ALWAYS use implicit member syntax at call sites when type context allows
- ALWAYS place the `fileprivate extension String` after extensions on the file's primary type
- NEVER add documentation comments to the static properties/functions
- NEVER localize strings in test files or `#Preview` blocks
- NEVER localize logs, assertions, fatal errors, or developer diagnostics

## Legacy Pattern

When refactoring older code using `NSLocalizedString`, convert to the modern `String(localized:)` pattern:

**Before (legacy):**
```swift
let text = NSLocalizedString("Unable to save", bundle: .module, comment: "...")
```

**After (modern):**
```swift
let text: String = .taskSaveError
```
