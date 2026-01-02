# Swift Symbol Ordering Reference

This document provides detailed examples of correct lexicographic ordering patterns for Swift code.

## Type Declaration Example

```swift
// ✅ CORRECT
struct User {
    // 1. typealiases (alphabetical)
    typealias Identifier = UUID

    // 2. stored properties (static let → static var → instance let → instance var)
    static let defaultName = "Guest"
    static var registrationCount = 0

    let id: UUID
    let name: String

    var email: String
    var isActive: Bool

    // 3. initializers (access level, then alphabetical)
    init(id: UUID, name: String, email: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.isActive = isActive
    }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.email = ""
        self.isActive = true
    }

    // 4a. computed properties (before methods)
    var displayName: String {
        name.isEmpty ? Self.defaultName : name
    }

    var isValid: Bool {
        !email.isEmpty && isActive
    }

    // 4b. methods (alphabetical)
    func activate() {
        isActive = true
    }

    func deactivate() {
        isActive = false
    }
}
```

## Access Level Ordering Example

```swift
// ✅ CORRECT
class ViewModel {
    // Stored properties: public → internal → private, alphabetical within each
    public let title: String

    let subtitle: String

    private let apiClient: APIClient

    // Methods: public → internal → private, alphabetical within each
    public func load() { }
    public func refresh() { }

    func handleError(_ error: Error) { }
    func validateInput() { }

    private func fetchData() { }
    private func parseResponse() { }
}
```

## Protocol Conformances Example

```swift
// ✅ CORRECT - Alphabetical by protocol name
extension User: Codable {
    // Codable implementation following internal ordering rules
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

## Function and Initializer Parameters

Parameters are the exception to strict lexicographic ordering. Semantic clarity takes precedence.

```swift
// ✅ CORRECT - Semantic ordering: id first, then core properties, then state
init(id: UUID, name: String, email: String, isActive: Bool) {
    self.id = id
    self.name = name
    self.email = email
    self.isActive = isActive
}

// ✅ CORRECT - Logical grouping: related parameters adjacent
func createRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect

// ✅ CORRECT - Convention alignment: matches UIKit patterns
func animate(withDuration duration: TimeInterval, delay: TimeInterval, options: UIView.AnimationOptions)

// ✅ CORRECT - Required before optional
func fetchUser(id: UUID, includeMetadata: Bool = false, cache: Cache? = nil)
```

```swift
// ⚠️ AVOID - Alphabetizing when semantic order is clearer
init(email: String, id: UUID, isActive: Bool, name: String)  // id buried in the middle

// ⚠️ AVOID - Breaking logical groupings
func createRect(height: CGFloat, width: CGFloat, x: CGFloat, y: CGFloat)  // dimensions scattered
```

```swift
// ✅ CORRECT - Lexicographic fallback when parameters are arbitrary/interchangeable
func configure(enableFeatureA: Bool, enableFeatureB: Bool, enableFeatureC: Bool)

// ✅ CORRECT - Alphabetical when no semantic relationship exists
func process(alpha: Double, beta: Double, gamma: Double)
```

## Function Body - Safe Reordering

```swift
// ✅ CORRECT - Independent statements sorted alphabetically
func setupUI() {
    let backButton = UIButton()
    let headerLabel = UILabel()
    let subtitleLabel = UILabel()

    backButton.setTitle("Back", for: .normal)
    headerLabel.text = "Welcome"
    subtitleLabel.text = "Please sign in"
}
```

## Function Body - Preserve Dependencies

```swift
// ✅ CORRECT - Dependent statements NOT reordered
func processUser() {
    let user = fetchUser()      // Must come first
    let name = user.name        // Depends on user
    let validated = validate(name)  // Depends on name
    updateUI(with: validated)   // Depends on validated
}
```

## Quick Reference Table

| Member Type | Ordering Priority |
|-------------|-------------------|
| typealiases | Alphabetical by name |
| static let properties | Access level → alphabetical |
| static var properties | Access level → alphabetical |
| instance let properties | Access level → alphabetical |
| instance var properties | Access level → alphabetical |
| initializers | Access level → alphabetical |
| lazy properties | Access level → alphabetical |
| static computed properties | Access level → alphabetical |
| instance computed properties | Access level → alphabetical |
| static methods | Access level → alphabetical |
| instance methods | Access level → alphabetical |

**Access Level Order:** public → internal → fileprivate → private
