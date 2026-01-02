---
name: configuring-ios-content
description: Implement iOS UIContentConfiguration and UIHostingConfiguration for modern UIKit architecture. Use when working with cells, custom views, or replacing legacy view configuration code.
---

# iOS UIContentConfiguration Skill

## Background

UIContentConfiguration (iOS 14+) and UIHostingConfiguration (iOS 16+) replace legacy UIKit view configuration with a declarative, state-driven architecture. This skill provides the patterns for implementing this architecture correctly.

## Rules

1.  **Prefer Composition**: ALWAYS use `UIContentConfiguration` over subclassing `UITableViewCell` or `UICollectionViewCell` for standard layouts.
2.  **Use Value Types**: Define configurations as `struct`s conforming to `UIContentConfiguration` and `Hashable`.
3.  **Separate View Logic**: Content views MUST handle `setup` once in `init` and `update` in a dedicated `apply(configuration:)` method.
4.  **Handle State**: Use `updated(for state:)` to return modified configurations based on `UICellConfigurationState` (selected, highlighted, etc.).
5.  **SwiftUI Integration**: For iOS 16+, prefer `UIHostingConfiguration` to embed SwiftUI views directly in cells.
6.  **Performance**: NEVER cache configuration objects; create them fresh. They are lightweight value types.
7.  **Diffable Data Sources**: Use `Item.ID` as the diffable item identifier, NOT the configuration struct itself.
8.  **Memory Safety**: ALWAYS use `[weak self]` in closures stored within configurations to prevent retain cycles.

## Common Patterns

### Modern Cell Registration (iOS 14+)

```swift
let registration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
    var content = cell.defaultContentConfiguration()
    content.text = item.title
    content.secondaryText = item.subtitle
    content.image = item.icon
    cell.contentConfiguration = content
}
```

### SwiftUI in UIKit Cells (iOS 16+)

```swift
cell.contentConfiguration = UIHostingConfiguration {
    HStack {
        Image(systemName: "star")
        VStack(alignment: .leading) {
            Text(item.title).font(.headline)
            Text(item.subtitle).foregroundStyle(.secondary)
        }
    }
}
```

### Custom Configuration Boilerplate

Use this pattern when creating a fully custom configuration:

```swift
struct CustomConfig: UIContentConfiguration, Hashable {
    var title: String?
    
    func makeContentView() -> UIView & UIContentView {
        return CustomContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> CustomConfig {
        var updated = self
        // Apply state logic here (e.g., change color on selection)
        return updated
    }
}
```

## Critical Pitfalls

-   **Legacy Mixing**: DO NOT mix `cell.textLabel` with `cell.contentConfiguration`. They are mutually exclusive.
-   **State Loops**: NEVER call `setNeedsUpdateConfiguration()` inside `layoutSubviews()`.
-   **Stale IndexPaths**: In action closures, query `tableView.indexPath(for: cell)` instead of capturing `indexPath` from the registration closure.

## Reference

For detailed implementation of custom views, standalone usage, and advanced state handling, see [REFERENCE.md](REFERENCE.md).
