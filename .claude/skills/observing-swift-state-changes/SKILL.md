---
name: observing-swift-state-changes
description: Implements the Observation framework for reactive Swift state management. Use when adding @Observable to model classes, tracking property changes with withObservationTracking, integrating Observable models with SwiftUI or UIKit, or implementing the observer pattern in Swift.
---

# Observing Swift State Changes

Use Apple's Observation framework to implement reactive state management in Swift applications. This skill covers the `@Observable` macro, change tracking, and UIKit integration.

## Core Concepts

### Making Types Observable

Apply the `@Observable` macro to class types to enable automatic change tracking:

```swift
import Observation

@Observable
class Car {
    var name: String = ""
    var needsRepairs: Bool = false

    init(name: String, needsRepairs: Bool = false) {
        self.name = name
        self.needsRepairs = needsRepairs
    }
}
```

The macro:
- Adds conformance to the `Observable` protocol
- Synthesizes an internal `ObservationRegistrar`
- Transforms stored properties to track access and mutations

### Excluding Properties from Observation

Use `@ObservationIgnored` to prevent specific properties from triggering change notifications:

```swift
@Observable
class ViewModel {
    var displayName: String = ""

    @ObservationIgnored
    var internalCache: [String: Any] = [:]
}
```

## Tracking Changes

### Using withObservationTracking

Track property access and respond to changes:

```swift
func render() {
    withObservationTracking {
        for car in cars {
            print(car.name)
        }
    } onChange: {
        print("Schedule renderer.")
    }
}
```

Key behavior:
- Only properties **read** within the `apply` closure are tracked
- The `onChange` closure fires when any tracked property changes
- Tracking is one-shot: re-call `withObservationTracking` to continue observing

### Observations AsyncSequence (iOS 26+)

For continuous observation using Swift Concurrency:

```swift
let observations = Observations { model.count }

for try await count in observations {
    print("Count changed to: \(count)")
}
```

Use `Observations.untilFinished` for controlled iteration:

```swift
let observations = Observations.untilFinished {
    guard model.isActive else { return .finish }
    return .next(model.value)
}
```

## UIKit Integration

### Automatic Observation Tracking

UIKit automatically tracks `@Observable` properties in specific methods. When tracked properties change, UIKit re-invokes these methods.

#### In Views

| Method | Purpose |
|--------|---------|
| `updateProperties()` | Configure text, colors, visibility |
| `layoutSubviews()` | Handle geometry and positioning |
| `updateConstraints()` | Update Auto Layout constraints |
| `draw(_:)` | Custom drawing |

#### In View Controllers

| Method | Purpose |
|--------|---------|
| `updateProperties()` | Configure view properties |
| `viewWillLayoutSubviews()` | Pre-layout updates |
| `viewDidLayoutSubviews()` | Post-layout updates |
| `updateViewConstraints()` | Constraint updates |

### Example: View Controller with Observable Model

```swift
@Observable
class MessageModel {
    var showStatus: Bool = true
    var statusText: String = ""
}

class MessageViewController: UIViewController {
    var model: MessageModel!
    var statusLabel: UILabel!

    override func updateProperties() {
        super.updateProperties()
        statusLabel.alpha = model.showStatus ? 1.0 : 0.0
        statusLabel.text = model.statusText
    }
}
```

UIKit tracks `showStatus` and `statusText` during the first `updateProperties()` call. When either property changes, UIKit automatically calls `updateProperties()` again.

### Example: Collection View Cell Configuration

```swift
@Observable
class ListItemModel {
    var icon: UIImage?
    var title: String = ""
    var subtitle: String = ""
}

// In cell provider:
cell.configurationUpdateHandler = { cell, state in
    var config = UIListContentConfiguration.cell()
    config.image = model.icon
    config.text = model.title
    config.secondaryText = model.subtitle
    cell.contentConfiguration = config
}
```

### Performance: Separating Updates from Layout

Use `updateProperties()` for content changes that don't affect geometry:

```swift
// Good: Only updates badge text, no layout pass
override func updateProperties() {
    super.updateProperties()
    badgeItem.badge = "\(model.count)"
}
```

Reserve `layoutSubviews()` for actual geometry calculations.

### UIKit Update Order

1. Trait collection updates
2. `updateProperties()` runs (if needed)
3. `layoutSubviews()` runs (if needed)
4. Display pass renders
5. Frame presented on screen

### Enabling in iOS 18

Add to Info.plist:

```xml
<key>UIObservationTrackingEnabled</key>
<true/>
```

In iOS 26+, automatic observation tracking is enabled by default.

## SwiftUI Integration

SwiftUI automatically tracks `@Observable` objects without additional property wrappers:

```swift
@Observable
class AppState {
    var username: String = ""
    var isLoggedIn: Bool = false
}

struct ContentView: View {
    var state: AppState

    var body: some View {
        if state.isLoggedIn {
            Text("Welcome, \(state.username)")
        } else {
            LoginView()
        }
    }
}
```

## ObservationRegistrar (Advanced)

The registrar manages observation state. You rarely interact with it directly when using `@Observable`, but it provides:

| Method | Purpose |
|--------|---------|
| `access(_:keyPath:)` | Register property access |
| `willSet(_:keyPath:)` | Notify before mutation |
| `didSet(_:keyPath:)` | Notify after mutation |
| `withMutation(of:keyPath:_:)` | Wrap a mutation |

## Platform Availability

| Feature | Minimum Version |
|---------|-----------------|
| `@Observable`, `withObservationTracking` | iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1 |
| `Observations` AsyncSequence | iOS 26, macOS 26, tvOS 26, watchOS 26, visionOS 26 |
| UIKit automatic tracking | iOS 18+ (opt-in), iOS 26+ (default) |

## Common Patterns

### Nested Observable Objects

Observation tracks the specific properties accessed, not entire object graphs:

```swift
@Observable
class Parent {
    var child: Child = Child()
    var name: String = ""
}

@Observable
class Child {
    var value: Int = 0
}

// Reading parent.child.value tracks:
// - parent.child (access to child property)
// - child.value (access to value property)
```

### Thread Safety

`ObservationRegistrar` is thread-safe. However, ensure your observable types handle concurrent access appropriately if accessed from multiple threads.
