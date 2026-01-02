# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fuzi is a fast, lightweight XML/HTML parser for Swift, wrapping libxml2. It's a Swift port of Mattt Thompson's Ono library with modern Swift conventions.

## Build Commands

```bash
swift build           # Build the library
swift test            # Run test suite
```

## Architecture

The library wraps libxml2 C pointers in Swift classes:

- **Document.swift**: `XMLDocument` and `HTMLDocument` - entry points for parsing XML/HTML from String or Data
- **Node.swift**: `XMLNode` base class wrapping `xmlNodePtr` - provides content access, navigation, line numbers
- **Element.swift**: `XMLElement` extends `XMLNode` with tag names, attributes, children, and copy/remove operations
- **Queryable.swift**: `Queryable` protocol for XPath and CSS selector queries; includes CSS-to-XPath conversion
- **NodeSet.swift**: Collection types (`NodeSet`, `XPathNodeSet`) for query results
- **Error.swift**: `XMLError` enum for parsing and XPath failures
- **Helpers.swift**: C interop utilities including `^-^` operator for `UnsafePointer` to String conversion

**Key patterns:**
- Lazy properties for expensive computations (encoding, attributes, children)
- `LinkedCNodes` custom iterator for efficient C pointer traversal
- Platform-specific code via `#if` directives (especially macOS memory handling for node unlinking)

## Testing

Tests use XCTest with resource files in `Tests/Resources/`. Load test data via:

```swift
Bundle(for: type(of: self)).url(forResource: "filename", withExtension: "xml")
```

## libxml2 Integration

The library links against system libxml2. Memory management is critical:
- Documents own their `xmlDocPtr` and free it in `deinit`
- Nodes reference but don't own the document pointer
- `removeSafely()` handles platform-specific unlinking behavior
- `copy()` creates independent element copies with proper memory ownership
