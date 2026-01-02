---
name: testing-swift-code
description: Write tests using the Swift Testing framework (@Test, @Suite, #expect). Use when creating unit tests, parameterized tests, or migrating from XCTest.
---

# Swift Testing Framework Reference

Comprehensive reference for the new `Testing` framework in Swift 6 / Xcode 16.

## Quick Start

```swift
import Testing

@Suite("Calculator Tests")
struct CalculatorTests {
    @Test("Addition")
    func addition() {
        #expect(2 + 2 == 4)
    }

    @Test(arguments: [1, 2, 3])
    func isPositive(i: Int) {
        #expect(i > 0)
    }
}
```

## Key Concepts

- **@Test**: Marks a function as a test.
- **@Suite**: Groups tests (structure/class).
- **#expect**: Asserts a condition (soft failure).
- **#require**: Asserts a condition (hard failure/throws).
- **Traits**: `.enabled(if:)`, `.timeLimit`, `.tags`, `.serialized`.

## Detailed Reference

See [REFERENCE.md](REFERENCE.md) for:
- **Error Testing**: `throws: MyError.self`.
- **Parameterized Tests**: Combinatorial vs Zipped arguments.
- **Async Testing**: `confirmation`, `await`.
- **XCTest Migration**: Table mapping assertions.
