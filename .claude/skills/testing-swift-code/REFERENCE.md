# Swift Testing Framework Reference

## Expectations and Assertions

### `#expect` vs `#require`

- **`#expect(condition)`**: Records a failure but **continues** the test. Use for non-fatal checks.
- **`#require(condition)`**: Records a failure and **stops** the test (throws). Use for preconditions or optional unwrapping.

```swift
@Test func checking() throws {
    let x: Int? = 42
    let y = try #require(x) // Stops if nil
    #expect(y == 42)        // Continues if false
}
```

### Error Testing

```swift
// Expect specific error
#expect(throws: MyError.self) { try risky() }

// Expect any error
#expect(throws: (any Error).self) { try risky() }

// Expect NO error
#expect(throws: Never.self) { try safe() }
```

## Parameterized Testing

Run the same test logic over multiple inputs.

```swift
@Test(arguments: [1, 2, 3, 4])
func isPositive(i: Int) {
    #expect(i > 0)
}

// Multiple collections (Combinatorial)
@Test(arguments: [1, 2], ["a", "b"])
func combinations(i: Int, s: String) { ... }

// Zipped collections (Pairs)
@Test(arguments: zip([1, 2], ["a", "b"]))
func pairs(i: Int, s: String) { ... }
```

## Traits and Tags

Control test execution.

```swift
@Test(.enabled(if: isSimulator), .tags(.integration))
func simulatorOnly() { ... }

@Suite(.serialized) // Run tests sequentially
struct SerialTests { ... }
```

## Asynchronous Testing

### Basic Async
Just mark the function `async`.

```swift
@Test func load() async throws {
    let data = await fetch()
    #expect(data.count > 0)
}
```

### Confirmations
Test asynchronous callbacks/events.

```swift
@Test func callbacks() async {
    await confirmation("Called 3 times", expectedCount: 3) { confirm in
        stream.onReceive = { confirm() }
        await stream.start()
    }
}
```

## XCTest Migration

| XCTest | Swift Testing |
|--------|---------------|
| `XCTestCase` | `@Suite struct` |
| `func testX()` | `@Test func x()` |
| `XCTAssertEqual` | `#expect(a == b)` |
| `XCTUnwrap` | `try #require` |
| `setUp` | `init` |
| `tearDown` | `deinit` |

