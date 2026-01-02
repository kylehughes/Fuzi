---
name: adopting-uikit-liquid-glass
description: Guides adoption of iOS 26's Liquid Glass design language in UIKit apps. Use when migrating UIKit apps to iOS 26, implementing custom glass effects with UIGlassEffect, fixing visual issues with navigation bars, tab bars, or toolbars in iOS 26, or when questions arise about the new glass material system.
---

# Adopting UIKit Liquid Glass

iOS 26 introduces Liquid Glass—a translucent, dynamic material system that transforms all standard UIKit components. Apps recompiled with Xcode 26 automatically adopt glass appearance for system components; custom views require explicit API adoption.

## Quick Start

### Automatic Adoption Requirements

1. **Recompile with Xcode 26 SDK**
2. **Remove custom bar backgrounds** that interfere with glass:
   ```swift
   // ❌ Remove these
   navigationBar.barTintColor = .white
   navigationBar.backgroundColor = .systemBackground
   let appearance = UINavigationBarAppearance()
   appearance.configureWithOpaqueBackground()

   // ✅ Let system handle glass
   // (Remove custom appearance configuration entirely)
   ```
3. **Extend scroll views under navigation bars** for proper large title behavior
4. **Set sourceItem on action sheets** (now required on iPhone too)

### Temporary Opt-Out

For gradual migration, preserve iOS 18-era appearance:

```xml
<!-- Info.plist -->
<key>UIDesignRequiresCompatibility</key>
<true/>
```

Apple intends to remove this key in Xcode 27.

## Core Glass APIs

### UIGlassEffect for Custom Views

```swift
let glassEffect = UIGlassEffect()
let effectView = UIVisualEffectView(effect: glassEffect)
view.addSubview(effectView)

// Animate glass appearing (materialize)
UIView.animate {
    effectView.effect = glassEffect
}

// Animate glass disappearing (dematerialize)
UIView.animate {
    effectView.effect = nil  // NEVER animate alpha
}
```

**Critical**: Always animate the `effect` property, never `alpha`. Setting `effect = nil` triggers proper dematerialize animation.

### Configuration Options

```swift
glassEffect.isInteractive = true       // Enables scale/bounce on tap
glassEffect.tintColor = .systemBlue    // Semantic tinting for emphasis

// Style variants
let regular = UIGlassEffect(style: .regular)  // Default, versatile
let clear = UIGlassEffect(style: .clear)      // More transparent, requires dim layer
```

### UIGlassContainerEffect for Grouped Elements

When glass elements need to merge, split, or share uniform appearance:

```swift
let containerEffect = UIGlassContainerEffect()
containerEffect.spacing = 12  // Distance threshold for merging
let containerView = UIVisualEffectView(effect: containerEffect)

let glass1 = UIVisualEffectView(effect: UIGlassEffect())
let glass2 = UIVisualEffectView(effect: UIGlassEffect())
containerView.contentView.addSubview(glass1)
containerView.contentView.addSubview(glass2)

// Elements morph together when within spacing distance
UIView.animate {
    glass1.frame = mergedFrame
    glass2.frame = mergedFrame
}
```

### Corner Configuration

```swift
effectView.cornerConfiguration = .fixed(16)
effectView.cornerConfiguration = .containerRelative()  // Auto-adjusts for nested concentricity
```

## When to Use Glass

### Appropriate (Navigation Layer)

- Tab bars, navigation bars, toolbars
- Floating action buttons
- Popovers and menus
- Custom floating controls

### Avoid (Content Layer)

```swift
// ❌ WRONG: Glass on content creates hierarchy confusion
cell.contentView.glassEffect()
tableView.backgroundColor = UIGlassEffect()

// ✅ CORRECT: Reserve glass for floating controls only
floatingButton.effect = UIGlassEffect()
```

Never apply glass to list rows, collection view cells, cards, or large content areas.

## Component Changes

### UINavigationBar

- Transparent background with button items grouped into glass capsules
- Large titles moved inside scroll view content

```swift
// New properties
navigationItem.title = "Inbox"
navigationItem.subtitle = "49 Unread"
navigationItem.largeSubtitleView = filterButton

// Separate buttons with .fixedSpace(0)
navigationItem.rightBarButtonItems = [
    doneButton,
    .fixedSpace(0),  // Creates visual separator
    flagButton,
    folderButton     // Grouped with flagButton
]
```

### UITabBar

Floats above content; minimizes on scroll by default:

```swift
tabBarController.tabBarMinimizeBehavior = .onScrollDown
// Options: .automatic, .never, .onScrollDown, .onScrollUp
```

Bottom accessory for mini players:

```swift
let accessory = UITabAccessory(contentView: nowPlayingView)
tabBarController.bottomAccessory = accessory
```

### UIToolbar

Floating rounded bars; items grouped by default:

```swift
let flexibleSpace = UIBarButtonItem.flexibleSpace()
flexibleSpace.hidesSharedBackground = false  // Keep grouped despite spacing
```

### Sheets and Popovers

Morphing transitions from source views:

```swift
viewController.preferredTransition = .zoom { _ in barButtonItem }
viewController.popoverPresentationController?.sourceItem = barButtonItem

// Action sheets REQUIRE sourceItem (iPhone and iPad)
alertController.popoverPresentationController?.sourceItem = barButtonItem
```

## Migration Checklist

- [ ] Remove `UIBarAppearance` customizations
- [ ] Remove `backgroundColor` assignments on bars
- [ ] Set `sourceItem` on all action sheets
- [ ] Extend scroll views under navigation bars for large titles
- [ ] Adopt `UISceneDelegate` lifecycle (mandatory in next iOS release)
- [ ] Address Swift 6 concurrency warnings if using strict mode

## Critical: Scene Lifecycle Requirement

Apps without UIScene lifecycle will not launch when built with the SDK following iOS 26:

```
// Console warning in iOS 26:
CLIENT OF UIKIT REQUIRES UPDATE: This process does not adopt UIScene lifecycle.
```

Migrate from `UIApplicationDelegate` to `UISceneDelegate` now.

## Accessibility

Liquid Glass automatically responds to system settings:

| Setting | Effect |
|---------|--------|
| Reduce Transparency | Glass becomes frostier |
| Increase Contrast | Elements become black/white with borders |
| Reduce Motion | Disables elastic properties |

Maintain **minimum 4.5:1 contrast ratio** for text over glass. Use dynamic colors (`secondaryLabel`, etc.) which automatically become vibrant on glass.

## Performance

- Glass uses GPU-accelerated real-time blur
- Efficient for small number of elements; degrades with many layers
- Use `UIGlassContainerEffect` to group elements for efficient rendering
- Test on minimum supported hardware (iPhone 11/A13)

## Further Reference

For detailed API coverage, new Swift 6 concurrency handling, SwiftUI integration, and deprecated APIs, see [REFERENCE.md](REFERENCE.md).
