---
name: implementing-app-intents
description: Implements App Intents for Shortcuts, Siri, Apple Intelligence, Spotlight, widgets, and controls on Apple platforms. Use when creating app intents, app entities, App Shortcuts, assistant schema conformance, entity queries, or integrating with system experiences like Focus, Action button, or visual intelligence.
---

# Implementing App Intents for Apple Platforms

Use the App Intents framework to expose app actions and content to system experiences including Shortcuts, Siri, Apple Intelligence, Spotlight, widgets, controls, and Live Activities.

## When to Use This Skill

- Creating actions for Shortcuts app
- Integrating with Siri and Apple Intelligence
- Building App Shortcuts with voice phrases
- Making content searchable in Spotlight
- Configuring widgets or controls
- Responding to Focus changes or Action button

## Core Concepts

### App Intents

An app intent represents a discrete action. Adopt the `AppIntent` protocol:

```swift
import AppIntents

struct OpenLandmarkIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Landmark"

    @Parameter(title: "Landmark", requestValueDialog: "Which landmark?")
    var target: LandmarkEntity

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
```

**Key protocols:**
- `AppIntent` - Base protocol for all intents
- `OpenIntent` - Opens content (requires `target` parameter)
- `DeleteIntent` - Deletes content
- `AudioPlaybackIntent` / `AudioRecordingIntent` - Audio operations
- `CameraCaptureIntent` - Camera capture
- `ForegroundContinuableIntent` - Can continue in foreground
- `ProgressReportingIntent` - Reports progress

### App Entities

Entities represent your app's data to the system:

```swift
struct LandmarkEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Landmark", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) landmarks"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(continent)",
            image: .init(data: thumbnailData)
        )
    }

    static let defaultQuery = LandmarkEntityQuery()

    var id: UUID
    var name: String
    var continent: String
}
```

**Entity identity:** Use `String`, `Int`, or `UUID` for the `id` property.

### Entity Queries

Queries let the system find entities:

```swift
struct LandmarkEntityQuery: EntityStringQuery {
    @Dependency var dataManager: DataManager

    func entities(for identifiers: [LandmarkEntity.ID]) async throws -> [LandmarkEntity] {
        dataManager.landmarks(with: identifiers).map { LandmarkEntity(landmark: $0) }
    }

    func entities(matching string: String) async throws -> [LandmarkEntity] {
        dataManager.landmarks { $0.name.localizedCaseInsensitiveContains(string) }
            .map { LandmarkEntity(landmark: $0) }
    }

    func suggestedEntities() async throws -> [LandmarkEntity] {
        dataManager.favoriteLandmarks.map { LandmarkEntity(landmark: $0) }
    }
}
```

**Query protocols:**
- `EntityQuery` - Identifier-based lookup
- `EntityStringQuery` - Adds string search
- `EnumerableEntityQuery` - All entities enumerable (enables Find intent)
- `EntityPropertyQuery` - Property-based filtering (enables Find intent)

### App Enums

For fixed value sets:

```swift
enum ActivityStyle: String, AppEnum {
    case biking, hiking, jogging

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Activity")
    }

    static var caseDisplayRepresentations: [ActivityStyle: DisplayRepresentation] = [
        .biking: DisplayRepresentation(title: "Biking", image: .init(named: "biking")),
        .hiking: DisplayRepresentation(title: "Hiking", image: .init(named: "hiking")),
        .jogging: DisplayRepresentation(title: "Jogging", image: .init(named: "jogging"))
    ]
}
```

## App Shortcuts

Make intents available without configuration:

```swift
struct MyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindClosestLandmarkIntent(),
            phrases: [
                "Find closest landmark in \(.applicationName)",
                "What's nearby in \(.applicationName)"
            ],
            shortTitle: "Find Closest",
            systemImageName: "location.circle"
        )
    }
}
```

**Parameterized phrases** skip clarification:
```swift
AppShortcut(
    intent: StartMeditationIntent(),
    phrases: [
        "Start \(\.$meditationType) meditation in \(.applicationName)"
    ],
    shortTitle: "Start Meditation",
    systemImageName: "brain.head.profile"
)
```

## Siri and Apple Intelligence Integration

Use assistant schemas for enhanced Siri understanding:

```swift
@AppIntent(schema: .photos.openAsset)
struct OpenAssetIntent: OpenIntent {
    var target: AssetEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        navigation.openAsset(target)
        return .result()
    }
}

@AppEntity(schema: .photos.asset)
struct AssetEntity: IndexedEntity {
    static let defaultQuery = AssetQuery()

    let id: String

    @Property(title: "Title")
    var title: String?

    var creationDate: Date?
    var assetType: AssetType?
    var isFavorite: Bool
}

@AppEnum(schema: .photos.assetType)
enum AssetType: String, AppEnum {
    case photo, video

    static let caseDisplayRepresentations: [AssetType: DisplayRepresentation] = [
        .photo: "Photo",
        .video: "Video"
    ]
}
```

**Available domains:** `.photos`, `.books`, `.browser`, `.camera`, `.reader`, `.files`, `.journal`, `.mail`, `.presentation`, `.spreadsheet`, `.whiteboard`, `.wordProcessor`, `.system`

**Schema constraints:**
- No required parameters beyond schema expectations
- Optional parameters only in Shortcuts app
- App entities cannot have additional required properties
- Maximum 10 app enums with schema conformance

**Avoiding breaking changes:** Set `isAssistantOnly = true` for new intents:
```swift
@AppIntent(schema: .photos.createAssets)
struct CreateAssetsIntent: AppIntent {
    static let isAssistantOnly: Bool = true
    // ...
}
```

## Spotlight Integration

Make entities searchable:

```swift
struct LandmarkEntity: IndexedEntity {
    @ComputedProperty(indexingKey: \.displayName)
    var name: String { landmark.name }

    @ComputedProperty(indexingKey: \.contentDescription)
    var description: String { landmark.description }

    @ComputedProperty(customIndexingKey: CSCustomAttributeKey(keyName: "continent")!)
    var continent: String { landmark.continent }
}
```

**Donate to index:**
```swift
import CoreSpotlight

func donateLandmarks() async throws {
    let entities = await modelData.landmarkEntities
    try await CSSearchableIndex.default().indexAppEntities(entities)
}
```

**Require an OpenIntent** for tappable Spotlight results.

## Interactive Snippets

Display UI overlays from intents:

```swift
struct ClosestLandmarkIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Closest Landmark"

    func perform() async throws -> some ReturnsValue<LandmarkEntity> & ShowsSnippetIntent & ProvidesDialog {
        let landmark = await findClosestLandmark()

        return .result(
            value: landmark,
            dialog: IntentDialog(
                full: "The closest landmark is \(landmark.name).",
                supporting: "\(landmark.name) is in \(landmark.continent)."
            ),
            snippetIntent: LandmarkSnippetIntent(landmark: landmark)
        )
    }
}

struct LandmarkSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Landmark Snippet"

    @Parameter var landmark: LandmarkEntity

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        return .result(view: LandmarkSnippetView(landmark: landmark))
    }
}
```

**Reload snippets:** Call `YourSnippetIntent.reload()` to update visible snippet.

**Request confirmation with snippet:**
```swift
try await requestConfirmation(
    actionName: .search,
    snippetIntent: ConfirmationSnippetIntent(data: data)
)
```

## Dependencies

Inject shared state:

```swift
struct MyIntent: AppIntent {
    @Dependency var dataManager: DataManager

    func perform() async throws -> some IntentResult {
        let items = dataManager.items
        // ...
    }
}

// In app initialization:
AppDependencyManager.shared.add(dependency: DataManager.shared)
```

## Intent Donations

Donate for prediction and suggestions:

```swift
// Donate
try await IntentDonationManager.shared.donate(intent: myIntent)

// Delete donations
try await IntentDonationManager.shared.delete(
    matching: IntentDonationMatchingPredicate(type: MyIntent.self)
)
```

## Deprecating Intents

Give users time to update shortcuts:

```swift
struct OldIntent: DeprecatedAppIntent {
    static let intentDeprecation = IntentDeprecation(
        recommendedIntents: [NewIntent.self],
        message: "Use New Intent instead"
    )
    // ...
}
```

## Detailed Reference

For extended examples including:
- Complete entity query implementations
- All assistant schema domains
- Visual intelligence integration
- Transferable entity representations
- User activity annotations

See [REFERENCE.md](REFERENCE.md).
