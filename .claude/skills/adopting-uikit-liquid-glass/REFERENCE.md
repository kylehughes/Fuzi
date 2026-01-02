# Liquid Glass Reference

Extended reference material for iOS 26 Liquid Glass adoption.

## Visual Characteristics

Liquid Glass is built on three core principles:

1. **Hierarchy**: Controls float above content as a distinct layer
2. **Harmony**: UI shapes align concentrically with device hardware
3. **Consistency**: Design adapts fluidly across all Apple platforms

### Size-Based Opacity

Larger glass elements appear more opaque; smaller elements remain clearer. On iOS and iPadOS, the material responds to device motion. Interactive elements scale and bounce on touch with a characteristic "shimmer" effect.

## New UIKit APIs

### updateProperties() Lifecycle Method

Called **before** `layoutSubviews()` with automatic `@Observable` tracking:

```swift
override func updateProperties() {
    super.updateProperties()
    // Automatically tracks @Observable changes
    titleLabel.text = viewModel.title
}

// Trigger manually without forcing layout
view.setNeedsUpdateProperties()
```

### Animation with Automatic Layout Flushing

```swift
UIView.animate(withDuration: 0.3, options: [.flushUpdates]) {
    model.isExpanded = true  // No layoutIfNeeded() needed
}
```

### UIBarButtonItem Badges

```swift
folderButton.badge = .count(5)
folderButton.badge = nil  // Remove
```

### HDR Color Support

```swift
let hdrColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0, exposure: 2.0)
colorPicker.maximumLinearExposure = 4.0
```

### UISlider Enhancements

```swift
// Tick marks
slider.trackConfiguration = UISlider.TrackConfiguration(
    tickMarks: [0, 0.25, 0.5, 0.75, 1.0]
)
slider.allowsTickValuesOnly = true

// Neutral value anchoring
slider.neutralValue = 0.5  // Fill shows difference from neutral
```

### Typed Notification Messages

```swift
NotificationCenter.default.addObserver(
    of: UIScreen.self,
    for: .keyboardWillShow
) { message in
    let duration = message.animationDuration
    let keyboardFrame = message.endFrame
    // No userInfo casting required
}
```

### UIBackgroundExtensionView

Extends content under sidebars with automatic visual effects:

```swift
let extensionView = UIBackgroundExtensionView()
extensionView.contentView = posterImageView
extensionView.automaticallyPlacesContentView = true
view.addSubview(extensionView)
```

### UISplitViewController Improvements

```swift
splitViewController.preferredSecondaryColumnWidth = 320
splitViewController.minimumSecondaryColumnWidth = 280
// Interactive column resizing via drag separators
```

## Navigation Transitions

### Interruptible Pop Gesture

Standard push/pop transitions are now always-interactive and interruptible. The content backswipe gesture works **anywhere in the content area**, not just from the leading edge.

```swift
// For custom gestures that need priority
customGesture.require(toFail: navigationController.interactiveContentPopGestureRecognizer)
```

## Search Integration

### Tab Search

```swift
searchTab.automaticallyActivatesSearch = true
```

### Toolbar Search Placement

```swift
toolbarItems = [
    navigationItem.searchBarPlacementBarButtonItem,
    .flexibleSpace(),
    addButton
]

// iPad: enable trailing edge integration
navigationItem.searchBarPlacementAllowsExternalIntegration = true

// Centered placement
navigationItem.preferredSearchBarPlacement = .integratedCentered
```

## Scroll Edge Effects

For custom containers:

```swift
let interaction = UIScrollEdgeElementContainerInteraction()
interaction.scrollView = contentScrollView
interaction.edge = .bottom
floatingContainerView.addInteraction(interaction)

// Hard edge style (iOS 18-like separation)
scrollView.topEdgeEffect.style = .hard
```

## SwiftUI Integration

### Hosting SwiftUI Glass Views

```swift
let hostingController = UIHostingController(rootView: GlassButtonView())
hostingController.sizingOptions = [.intrinsicContentSize]
navigationItem.titleView = hostingController.view
```

### SwiftUI Glass APIs

```swift
// Basic application
Text("Hello")
    .padding()
    .glassEffect()

// With shape and customization
Button("Action") { }
    .glassEffect(.regular.tint(.blue).interactive(), in: .capsule)

// Container for morphing
GlassEffectContainer(spacing: 20) {
    HStack(spacing: 20) {
        Button("One") { }.glassEffect()
        Button("Two") { }.glassEffect()
    }
}
```

### Cross-Platform Wrapper

```swift
extension View {
    @ViewBuilder
    func applyGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect()
        } else {
            self.background(.ultraThinMaterial, in: .capsule)
        }
    }
}
```

## Swift 6 Concurrency

### MainActor Defaults

New Xcode 26 projects default to `MainActor` isolation. Existing migrated projects default to `nonisolated`. Control via Build Settings → "Default Actor Isolation."

### awakeFromNib Handling

```swift
nonisolated override func awakeFromNib() {
    super.awakeFromNib()
    MainActor.assumeIsolated {
        // UI setup code
    }
}
```

### Approachable Concurrency

Enable via `SWIFT_APPROACHABLE_CONCURRENCY` build setting. Includes `InferIsolatedConformances` and `NonisolatedNonsendingByDefault`.

## Deprecated APIs

| Deprecated | Replacement |
|------------|-------------|
| `UIApplicationDelegate` lifecycle methods | `UISceneDelegate` equivalents |
| `UIWindow` initializers except `init(windowScene:)` | `init(windowScene:)` |
| `UINavigationBarAppearance.doneButtonAppearance` | `prominentButtonAppearance` |
| Storyboard-defined menu bars | Programmatic menu implementation |

## Tinting Best Practices

```swift
glassEffect.tintColor = .systemBlue
```

Tint generates adaptive tones based on background brightness. Use **selectively** for primary actions only—tinting all elements creates visual noise.

### Regular vs Clear Variants

- **Regular** (default): All visual and adaptive effects, works in any context
- **Clear**: Permanently more transparent, requires dimming layer underneath, use only over media-rich content with bold overlaid text
