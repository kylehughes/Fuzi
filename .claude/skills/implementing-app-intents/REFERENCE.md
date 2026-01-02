# App Intents Reference

Extended examples and detailed patterns for App Intents implementation.

## Complete Entity Query Example

Full implementation with all query protocols:

```swift
struct TrailEntityQuery: EntityStringQuery, EnumerableEntityQuery {
    typealias Entity = TrailEntity

    @Dependency var trailManager: TrailDataManager

    // Required: identifier lookup
    func entities(for identifiers: [TrailEntity.ID]) async throws -> [TrailEntity] {
        trailManager.trails(with: identifiers).map { TrailEntity(trail: $0) }
    }

    // EntityStringQuery: text search
    func entities(matching string: String) async throws -> [TrailEntity] {
        trailManager.trails { trail in
            trail.name.localizedCaseInsensitiveContains(string)
        }.map { TrailEntity(trail: $0) }
    }

    // EnumerableEntityQuery: all entities (enables Find intent)
    func allEntities() async throws -> [TrailEntity] {
        trailManager.allTrails.map { TrailEntity(trail: $0) }
    }

    // Optional: suggested entities for quick selection
    func suggestedEntities() async throws -> [TrailEntity] {
        trailManager.trails(with: trailManager.favoritesCollection.members)
            .map { TrailEntity(trail: $0) }
    }
}
```

## Property Query for Find Intent

Enable filtering by entity properties:

```swift
struct TrailEntityQuery: EntityPropertyQuery {
    typealias Entity = TrailEntity

    static var properties = QueryProperties {
        Property(\TrailEntity.$name) {
            EqualToComparator { $0 }
            ContainsComparator { $0 }
        }
        Property(\TrailEntity.$difficulty) {
            EqualToComparator { $0 }
        }
        Property(\TrailEntity.$length) {
            LessThanComparator { $0 }
            GreaterThanComparator { $0 }
        }
    }

    static var sortingOptions = SortingOptions {
        SortableBy(\TrailEntity.$name)
        SortableBy(\TrailEntity.$length)
    }

    func entities(
        matching comparators: [QueryComparator<TrailEntity>],
        mode: ComparatorMode,
        sortedBy: [Sort<TrailEntity>],
        limit: Int?
    ) async throws -> [TrailEntity] {
        // Apply comparators to filter entities
        var results = trailManager.allTrails.map { TrailEntity(trail: $0) }

        for comparator in comparators {
            results = results.filter { comparator.evaluate($0) }
        }

        // Apply sorting
        for sort in sortedBy.reversed() {
            results.sort { sort.compare($0, $1) }
        }

        if let limit = limit {
            results = Array(results.prefix(limit))
        }

        return results
    }
}
```

## Assistant Schema Domains

### Photos Domain

```swift
@AppIntent(schema: .photos.openAsset)
struct OpenAssetIntent: OpenIntent { var target: AssetEntity }

@AppIntent(schema: .photos.createAssets)
struct CreateAssetsIntent: AppIntent {
    var files: [IntentFile]
    func perform() async throws -> some ReturnsValue<[AssetEntity]> { ... }
}

@AppIntent(schema: .photos.search)
struct SearchPhotosIntent: AppIntent {
    var criteria: PhotoSearchCriteria
    func perform() async throws -> some ReturnsValue<[AssetEntity]> { ... }
}

@AppEntity(schema: .photos.asset)
struct AssetEntity: IndexedEntity {
    let id: String
    @Property var title: String?
    var creationDate: Date?
    var location: CLPlacemark?
    var assetType: AssetType?
    var isFavorite: Bool
    var isHidden: Bool
    var hasSuggestedEdits: Bool
}

@AppEntity(schema: .photos.album)
struct AlbumEntity: AppEntity {
    let id: String
    var name: String
}

@AppEnum(schema: .photos.assetType)
enum AssetType: String, AppEnum {
    case photo, video
}
```

### Books Domain

```swift
@AppIntent(schema: .books.openBook)
struct OpenBookIntent: OpenIntent { var target: BookEntity }

@AppEntity(schema: .books.book)
struct BookEntity: AppEntity {
    let id: UUID
    var title: String?
    var seriesTitle: String?
    var author: String?
    var genre: String?
    var purchaseDate: Date?
    var contentType: BookContentType?
    var url: URL?
}

@AppEnum(schema: .books.contentType)
enum BookContentType: String, AppEnum {
    case book, pdf
}
```

### Browser Domain

```swift
@AppIntent(schema: .browser.createTab)
struct CreateTabIntent: AppIntent {
    var url: URL?
    var isPrivate: Bool
    func perform() async throws -> some ReturnsValue<TabEntity> { ... }
}

@AppEntity(schema: .browser.tab)
struct TabEntity: AppEntity {
    let id: UUID
    var url: URL?
    var name: String
    var isPrivate: Bool
}

@AppEnum(schema: .browser.clearHistoryTimeFrame)
enum ClearHistoryTimeFrame: String, AppEnum {
    case today, lastFourHours, todayAndYesterday, allTime
}
```

### Camera Domain

```swift
@AppIntent(schema: .camera.startCapture)
struct StartCaptureIntent: AppIntent {
    var captureMode: CaptureMode
    var timerDuration: CaptureDuration?
    var device: CaptureDevice?
}

@AppEnum(schema: .camera.captureMode)
enum CaptureMode: String, AppEnum {
    case photo, video, portrait
}
```

### Document Reader Domain

```swift
@AppIntent(schema: .reader.rotatePages)
struct RotatePagesIntent: AppIntent {
    var pages: [ReaderPageEntity]
    var isClockwise: Bool
    func perform() async throws -> some ReturnsValue<[ReaderPageEntity]> { ... }
}

@AppEntity(schema: .reader.document)
struct ReaderDocumentEntity: AppEntity {
    let id: UUID
    var title: String
    var kind: ReaderDocumentKind
    var width: Int?
    var height: Int?
}

@AppEnum(schema: .reader.documentKind)
enum ReaderDocumentKind: String, AppEnum {
    case image, pdf
}
```

### Files Domain

```swift
@AppIntent(schema: .files.openFile)
struct OpenFileIntent: OpenIntent { var target: FileEntity }

@AppEntity(schema: .files.file)
struct FilesEntity: FileEntity {
    static var supportedContentTypes = [UTType.image]
    var id: FileEntityIdentifier
    var creationDate: Date?
    var fileModificationDate: Date?
}
```

### Journal Domain

```swift
@AppIntent(schema: .journal.createEntry)
struct CreateJournalEntryIntent: AppIntent {
    var message: AttributedString
    var title: String?
    var entryDate: Date?
    var location: CLPlacemark?
    @Parameter(default: []) var mediaItems: [IntentFile]
    func perform() async throws -> some ReturnsValue<JournalEntryEntity> { ... }
}

@AppEntity(schema: .journal.entry)
struct JournalEntryEntity: AppEntity {
    let id: UUID
    var title: String?
    var message: AttributedString?
    var mediaItems: [IntentFile]
    var entryDate: Date?
    var location: CLPlacemark?
}
```

### Mail Domain

```swift
@AppIntent(schema: .mail.sendDraft)
struct SendDraftIntent: AppIntent {
    var target: MailDraftEntity
    var sendLaterDate: Date?
}

@AppEntity(schema: .mail.draft)
struct MailDraftEntity: AppEntity {
    let id: UUID
    var to: [IntentPerson]
    var cc: [IntentPerson]
    var bcc: [IntentPerson]
    var subject: String?
    var body: AttributedString?
    var attachments: [IntentFile]
    var account: MailAccountEntity
}
```

### Presentation Domain

```swift
@AppIntent(schema: .presentation.open)
struct OpenPresentationIntent: OpenIntent { var target: PresentationEntity }

@AppIntent(schema: .presentation.createSlide)
struct CreateSlideIntent: AppIntent { ... }

@AppEntity(schema: .presentation.document)
struct PresentationEntity: AppEntity {
    let id: UUID
    var name: String
}
```

### Spreadsheet Domain

```swift
@AppIntent(schema: .spreadsheet.open)
struct OpenSpreadsheetIntent: OpenIntent { var target: SpreadsheetDocumentEntity }

@AppEntity(schema: .spreadsheet.document)
struct SpreadsheetDocumentEntity: AppEntity {
    let id: UUID
    var name: String
}
```

### Whiteboard Domain

```swift
@AppIntent(schema: .whiteboard.createBoard)
struct CreateWhiteboardIntent: AppIntent {
    var title: String?
    func perform() async throws -> some ReturnsValue<WhiteboardBoardEntity> { ... }
}

@AppEntity(schema: .whiteboard.board)
struct WhiteboardBoardEntity: AppEntity {
    let id: UUID
    var title: String
    var creationDate: Date
    var lastModificationDate: Date
}

@AppEnum(schema: .whiteboard.color)
enum WhiteboardColor: String, AppEnum {
    case white, black, grey, green, red, blue
}
```

### Word Processor Domain

```swift
@AppIntent(schema: .wordProcessor.open)
struct OpenDocumentIntent: OpenIntent { var target: WordProcessorDocumentEntity }

@AppEntity(schema: .wordProcessor.document)
struct WordProcessorDocumentEntity: AppEntity {
    let id: UUID
    var name: String
    var creationDate: Date?
    var modificationDate: Date?
}
```

### System Domain (In-App Search)

```swift
@AppIntent(schema: .system.search)
struct SearchIntent: ShowInAppSearchResultsIntent {
    static var searchScopes: [StringSearchScope] = [.general]
    var criteria: StringSearchCriteria

    func perform() async throws -> some IntentResult {
        let searchString = criteria.term
        // Navigate to search results
        return .result()
    }
}
```

## Visual Intelligence Integration

Support visual search with `IntentValueQuery`:

```swift
@UnionValue
enum VisualSearchResult {
    case landmark(LandmarkEntity)
    case collection(CollectionEntity)
}

struct LandmarkIntentValueQuery: IntentValueQuery {
    @Dependency var modelData: ModelData

    func values(for input: SemanticContentDescriptor) async throws -> [VisualSearchResult] {
        guard let pixelBuffer = input.pixelBuffer else { return [] }

        let landmarks = try await modelData.search(matching: pixelBuffer)
        return landmarks
    }
}

extension ModelData {
    func search(matching pixels: CVReadOnlyPixelBuffer) throws -> [VisualSearchResult] {
        // Match pixel buffer to your app's content
        return landmarkEntities.map { .landmark($0) }
    }
}
```

## Transferable Entity for Siri Context

Enable Siri to understand entity content:

```swift
extension LandmarkEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { @MainActor landmark in
            let url = URL.documentsDirectory.appending(path: "\(landmark.name).pdf")

            let renderer = ImageRenderer(content: VStack {
                Image(landmark.imageName).resizable().aspectRatio(contentMode: .fit)
                Text(landmark.name)
                Text("Continent: \(landmark.continent)")
                Text(landmark.description)
            }.frame(width: 600))

            renderer.render { size, renderer in
                var box = CGRect(origin: .zero, size: size)
                guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
                pdf.beginPDFPage(nil)
                renderer(pdf)
                pdf.endPDFPage()
                pdf.closePDF()
            }

            return .init(url)
        }

        DataRepresentation(exportedContentType: .image) {
            try $0.imageRepresentationData
        }

        DataRepresentation(exportedContentType: .plainText) {
            """
            Landmark: \($0.name)
            Description: \($0.description)
            """.data(using: .utf8)!
        }
    }
}
```

## User Activity Annotation

Make onscreen content available to Siri:

```swift
Text(landmark.name)
    .font(.title)
    .userActivity("com.myapp.ViewingLandmark") {
        $0.title = "Viewing \(landmark.name)"
        $0.appEntityIdentifier = EntityIdentifier(
            for: try! modelData.landmarkEntity(id: landmark.id)
        )
    }
```

## Spotlight with CoreSpotlight Association

For apps already using CoreSpotlight:

```swift
func updateSpotlightIndex() async {
    let searchableItems = trails.map { trail in
        let item = CSSearchableItem(
            uniqueIdentifier: String(trail.id),
            domainIdentifier: nil,
            attributeSet: trail.searchableAttributes
        )

        let weight = favoritesCollection.members.contains(trail.id) ? 10 : 1
        let entity = TrailEntity(trail: trail)

        // Associate before adding to index
        item.associateAppEntity(entity, priority: weight)
        return item
    }

    try await CSSearchableIndex.default().indexSearchableItems(searchableItems)
}
```

## Interactive Snippet Workflow

Chain snippets for multi-step interactions:

```swift
struct FindTicketsIntent: AppIntent {
    @Parameter var landmark: LandmarkEntity

    func perform() async throws -> some IntentResult & ShowsSnippetIntent {
        let searchRequest = await searchEngine.createRequest(landmarkEntity: landmark)

        // First snippet: confirmation with ticket count
        try await requestConfirmation(
            actionName: .search,
            snippetIntent: TicketRequestSnippetIntent(searchRequest: searchRequest)
        )

        // Perform search after confirmation
        try await searchEngine.performRequest(request: searchRequest) {
            // Reload snippet during search
            TicketResultSnippetIntent.reload()
        }

        // Final snippet: show results
        return .result(
            snippetIntent: TicketResultSnippetIntent(searchRequest: searchRequest)
        )
    }
}
```

## Entity Property Macros

### @Property vs @ComputedProperty

```swift
struct LandmarkEntity: IndexedEntity {
    // Stored property
    @Property(title: "Name")
    var name: String

    // Computed property with Spotlight indexing
    @ComputedProperty(indexingKey: \.contentDescription)
    var description: String { landmark.description }

    // Custom indexing key
    @ComputedProperty(customIndexingKey: CSCustomAttributeKey(keyName: "com.myapp.continent")!)
    var continent: String { landmark.continent }

    // Deferred property (async getter)
    @DeferredProperty
    var crowdStatus: Int {
        get async throws {
            await modelData.getCrowdStatus(self)
        }
    }
}
```

## SiriTipView and ShortcutsLink

Promote App Shortcuts in your UI:

```swift
// Show Siri tip
SiriTipView(intent: FindClosestLandmarkIntent())

// Link to shortcuts
ShortcutsLink()

// UIKit equivalent
let tipView = SiriTipUIView(intent: FindClosestLandmarkIntent())
```

## Focus Integration

Respond to Focus changes by implementing relevant intents and using the Focus framework to adjust app behavior based on active Focus modes.

## Action Button Support

App Shortcuts automatically work with the Action button. Users can assign any App Shortcut to trigger from the Action button in Settings.
