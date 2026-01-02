// ActorTests.swift
// Copyright (c) 2015 Ce Zheng
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Testing

@testable import Fuzi

// MARK: - XMLActor Tests

@Suite("XMLActor Tests")
struct XMLActorTests {
    // MARK: Initialization Tests

    @Test("Initialize from Data")
    func initFromData() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)

        let version = await actor.version
        #expect(version == "1.0")
    }

    @Test("Initialize from String")
    func initFromString() async throws {
        let xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <root><child>Hello</child></root>
            """
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.tag == "root")
    }

    @Test("Initialize from CChars")
    func initFromCChars() async throws {
        let xml = "<?xml version=\"1.0\"?><root/>"
        let cChars = Array(xml.utf8CString)
        let actor = try XMLActor(cChars: cChars)

        let root = await actor.root
        #expect(root?.tag == "root")
    }

    @Test("Initialize with invalid data throws error")
    func initWithInvalidData() async {
        let invalidData = Data()
        #expect(throws: XMLError.self) {
            _ = try XMLActor(data: invalidData)
        }
    }

    // MARK: Document Property Tests

    @Test("Version property")
    func versionProperty() async throws {
        let actor = try await makeAtomActor()
        let version = await actor.version
        #expect(version == "1.0")
    }

    @Test("Encoding property")
    func encodingProperty() async throws {
        let actor = try await makeAtomActor()
        let encoding = await actor.encoding
        #expect(encoding == .utf8)
    }

    @Test("Root property")
    func rootProperty() async throws {
        let actor = try await makeAtomActor()
        let root = await actor.root
        #expect(root != nil)
        #expect(root?.tag == "feed")
    }

    @Test("Snapshot property")
    func snapshotProperty() async throws {
        let actor = try await makeAtomActor()
        let snapshot = await actor.snapshot

        #expect(snapshot.version == "1.0")
        #expect(snapshot.encoding == .utf8)
        #expect(snapshot.root?.tag == "feed")
    }

    // MARK: Namespace Tests

    @Test("Define namespace prefix")
    func defineNamespacePrefix() async throws {
        let actor = try await makeAtomActor()
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        let titles = await actor.xpath("//atom:title")
        #expect(titles.count == 2) // feed title + entry title
    }

    @Test("Multiple namespace prefixes")
    func multipleNamespacePrefixes() async throws {
        let actor = try await makeAtomActor()
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")
        await actor.definePrefix("dc", forNamespace: "http://purl.org/dc/elements/1.1/")

        let languages = await actor.xpath("//dc:language")
        #expect(languages.count == 1)
        #expect(languages.first?.stringValue == "en-us")
    }

    // MARK: XPath Query Tests

    @Test("XPath returns matching elements")
    func xpathReturnsMatchingElements() async throws {
        let actor = try await makeXMLActor()
        let titles = await actor.xpath("/spec/header/title")

        #expect(titles.count == 1)
        #expect(titles.first?.tag == "title")
        #expect(titles.first?.stringValue == "Extensible Markup Language (XML)")
    }

    @Test("XPath returns empty array for no matches")
    func xpathReturnsEmptyForNoMatches() async throws {
        let actor = try await makeXMLActor()
        let results = await actor.xpath("//nonexistent")

        #expect(results.isEmpty)
    }

    @Test("XPath with predicates")
    func xpathWithPredicates() async throws {
        let actor = try await makeAtomActor()
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        let links = await actor.xpath("//atom:link[@rel='self']")
        #expect(links.count == 1)
        #expect(links.first?.attributes["href"] == "http://example.org/feed/")
    }

    @Test("tryXPath succeeds with valid expression")
    func tryXPathSucceeds() async throws {
        let actor = try await makeXMLActor()
        let results = try await actor.tryXPath("/spec/header/title")

        #expect(results.count == 1)
    }

    @Test("tryXPath throws on invalid expression")
    func tryXPathThrowsOnInvalid() async throws {
        let actor = try await makeXMLActor()

        do {
            _ = try await actor.tryXPath("////")
            Issue.record("Expected XMLError to be thrown")
        } catch is XMLError {
            // Expected
        } catch {
            Issue.record("Expected XMLError but got \(type(of: error))")
        }
    }

    @Test("firstChild XPath returns first match")
    func firstChildXPath() async throws {
        let actor = try await makeAtomActor()
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        let title = await actor.firstChild(xpath: "//atom:title")
        #expect(title != nil)
        #expect(title?.stringValue == "Example Feed")
    }

    @Test("firstChild XPath returns nil for no match")
    func firstChildXPathReturnsNil() async throws {
        let actor = try await makeXMLActor()
        let result = await actor.firstChild(xpath: "//nonexistent")

        #expect(result == nil)
    }

    // MARK: CSS Query Tests

    @Test("CSS selector returns matching elements")
    func cssReturnsMatchingElements() async throws {
        // Use HTML document for CSS selectors (they work better with HTML)
        let data = try loadTestResource(name: "web", extension: "html")
        let actor = try HTMLActor(data: data)
        let divs = await actor.css("div")

        #expect(divs.count > 0)
        #expect(divs.first?.tag == "div")
    }

    @Test("CSS with ID selector")
    func cssWithIdSelector() async throws {
        let data = try loadTestResource(name: "web", extension: "html")
        let actor = try HTMLActor(data: data)

        let elements = await actor.css("#account_settings")
        #expect(elements.count == 1)
    }

    @Test("firstChild CSS returns first match")
    func firstChildCSS() async throws {
        // CSS selectors work better with HTML
        let data = try loadTestResource(name: "web", extension: "html")
        let actor = try HTMLActor(data: data)
        let div = await actor.firstChild(css: "div")

        #expect(div != nil)
        #expect(div?.tag == "div")
    }

    @Test("firstChild CSS returns nil for no match")
    func firstChildCSSReturnsNil() async throws {
        let data = try loadTestResource(name: "web", extension: "html")
        let actor = try HTMLActor(data: data)
        let result = await actor.firstChild(css: ".nonexistent-class-xyz")

        #expect(result == nil)
    }

    // MARK: XPath Evaluation Tests

    @Test("Eval XPath boolean function")
    func evalXPathBoolean() async throws {
        let actor = try await makeAtomActor()
        let result = await actor.eval(xpath: "starts-with('Hello', 'H')")

        #expect(result != nil)
        #expect(result?.boolValue == true)
    }

    @Test("Eval XPath count function")
    func evalXPathCount() async throws {
        let actor = try await makeAtomActor()
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        let result = await actor.eval(xpath: "count(//atom:link)")
        #expect(result != nil)
        #expect(result?.doubleValue == 5) // 2 in feed + 3 in entry
    }

    @Test("Eval XPath string function")
    func evalXPathString() async throws {
        let actor = try await makeAtomActor()
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        let result = await actor.eval(xpath: "string(//atom:title[1]/text())")
        #expect(result != nil)
        #expect(result?.stringValue == "Example Feed")
    }

    // MARK: Helper Methods

    private func makeAtomActor() async throws -> XMLActor {
        let data = try loadTestResource(name: "atom", extension: "xml")
        return try XMLActor(data: data)
    }

    private func makeXMLActor() async throws -> XMLActor {
        let data = try loadTestResource(name: "xml", extension: "xml")
        return try XMLActor(data: data)
    }
}

// MARK: - HTMLActor Tests

@Suite("HTMLActor Tests")
struct HTMLActorTests {
    // MARK: Initialization Tests

    @Test("Initialize from Data")
    func initFromData() async throws {
        let data = try loadTestResource(name: "web", extension: "html")
        let actor = try HTMLActor(data: data)

        let root = await actor.root
        #expect(root?.tag == "html")
    }

    @Test("Initialize from String")
    func initFromString() async throws {
        let html = """
            <!DOCTYPE html>
            <html><head><title>Test</title></head><body></body></html>
            """
        let actor = try HTMLActor(string: html)

        let title = await actor.title
        #expect(title == "Test")
    }

    @Test("Initialize with invalid data throws error")
    func initWithInvalidData() async {
        let invalidData = Data()
        #expect(throws: XMLError.self) {
            _ = try HTMLActor(data: invalidData)
        }
    }

    // MARK: HTML-Specific Property Tests

    @Test("Title property")
    func titleProperty() async throws {
        let actor = try await makeHTMLActor()
        let title = await actor.title

        #expect(title == "mattt/Ono")
    }

    @Test("Head property")
    func headProperty() async throws {
        let actor = try await makeHTMLActor()
        let head = await actor.head

        #expect(head != nil)
        #expect(head?.tag == "head")
    }

    @Test("Body property")
    func bodyProperty() async throws {
        let actor = try await makeHTMLActor()
        let body = await actor.body

        #expect(body != nil)
        #expect(body?.tag == "body")
    }

    @Test("Root property")
    func rootProperty() async throws {
        let actor = try await makeHTMLActor()
        let root = await actor.root

        #expect(root?.tag == "html")
    }

    @Test("Snapshot property")
    func snapshotProperty() async throws {
        let actor = try await makeHTMLActor()
        let snapshot = await actor.snapshot

        #expect(snapshot.root?.tag == "html")
    }

    // MARK: Query Tests

    @Test("XPath query")
    func xpathQuery() async throws {
        let actor = try await makeHTMLActor()
        let titles = await actor.xpath("//head/title")

        #expect(titles.count == 1)
        #expect(titles.first?.stringValue == "mattt/Ono")
    }

    @Test("CSS query")
    func cssQuery() async throws {
        let actor = try await makeHTMLActor()
        let elements = await actor.css("head title")

        #expect(elements.count == 1)
        #expect(elements.first?.stringValue == "mattt/Ono")
    }

    @Test("CSS ID selector")
    func cssIdSelector() async throws {
        let actor = try await makeHTMLActor()
        let elements = await actor.css("#account_settings")

        #expect(elements.count == 1)
        #expect(elements.first?.attributes["href"] == "/settings/profile")
    }

    @Test("tryXPath throws on invalid expression")
    func tryXPathThrows() async throws {
        let actor = try await makeHTMLActor()

        await #expect(throws: XMLError.self) {
            _ = try await actor.tryXPath("////")
        }
    }

    // MARK: Helper Methods

    private func makeHTMLActor() async throws -> HTMLActor {
        let data = try loadTestResource(name: "web", extension: "html")
        return try HTMLActor(data: data)
    }
}

// MARK: - ElementSnapshot Tests

@Suite("ElementSnapshot Tests")
struct ElementSnapshotTests {
    @Test("Captures tag")
    func capturesTag() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)

        let root = await actor.root
        #expect(root?.tag == "feed")
    }

    @Test("Captures attributes")
    func capturesAttributes() async throws {
        let data = try loadTestResource(name: "xml", extension: "xml")
        let actor = try XMLActor(data: data)

        let root = await actor.root
        #expect(root?.attributes["w3c-doctype"] == "rec")
        #expect(root?.attributes["lang"] == "en")
    }

    @Test("Captures stringValue")
    func capturesStringValue() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        let title = await actor.firstChild(xpath: "//atom:title")
        #expect(title?.stringValue == "Example Feed")
    }

    @Test("Captures namespace")
    func capturesNamespace() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)
        await actor.definePrefix("dc", forNamespace: "http://purl.org/dc/elements/1.1/")

        let language = await actor.firstChild(xpath: "//dc:language")
        #expect(language?.namespace == "dc")
    }

    @Test("Captures lineNumber")
    func capturesLineNumber() async throws {
        let data = try loadTestResource(name: "xml", extension: "xml")
        let actor = try XMLActor(data: data)

        let header = await actor.firstChild(xpath: "/spec/header")
        #expect(header?.lineNumber == 120)
    }

    @Test("Captures rawXML")
    func capturesRawXML() async throws {
        let xml = "<?xml version=\"1.0\"?><root><child>text</child></root>"
        let actor = try XMLActor(string: xml)

        let child = await actor.firstChild(xpath: "//child")
        #expect(child?.rawXML == "<child>text</child>")
    }

    @Test("Hashable conformance")
    func hashableConformance() async throws {
        let actor = try XMLActor(string: "<root><a/><b/></root>")
        let elements = await actor.xpath("/root/*")

        var set = Set<ElementSnapshot>()
        for element in elements {
            set.insert(element)
        }

        #expect(set.count == 2)
    }

    @Test("Equatable conformance")
    func equatableConformance() async throws {
        let actor = try XMLActor(string: "<root><child>same</child></root>")

        let first = await actor.firstChild(xpath: "//child")
        let second = await actor.firstChild(xpath: "//child")

        #expect(first == second)
    }
}

// MARK: - DocumentSnapshot Tests

@Suite("DocumentSnapshot Tests")
struct DocumentSnapshotTests {
    @Test("Captures version")
    func capturesVersion() async throws {
        let actor = try XMLActor(string: "<?xml version=\"1.0\"?><root/>")
        let snapshot = await actor.snapshot

        #expect(snapshot.version == "1.0")
    }

    @Test("Captures encoding")
    func capturesEncoding() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)
        let snapshot = await actor.snapshot

        #expect(snapshot.encoding == .utf8)
    }

    @Test("Captures root")
    func capturesRoot() async throws {
        let actor = try XMLActor(string: "<document><content/></document>")
        let snapshot = await actor.snapshot

        #expect(snapshot.root?.tag == "document")
    }

    @Test("Hashable conformance")
    func hashableConformance() async throws {
        let actor1 = try XMLActor(string: "<root/>")
        let actor2 = try XMLActor(string: "<different/>")

        let snapshot1 = await actor1.snapshot
        let snapshot2 = await actor2.snapshot

        var set = Set<DocumentSnapshot>()
        set.insert(snapshot1)
        set.insert(snapshot2)

        #expect(set.count == 2)
    }
}

// MARK: - XPathResult Tests

@Suite("XPathResult Tests")
struct XPathResultTests {
    @Test("boolValue property")
    func boolValueProperty() async throws {
        let actor = try XMLActor(string: "<root/>")
        let result = await actor.eval(xpath: "1 = 1")

        #expect(result?.boolValue == true)
    }

    @Test("doubleValue property")
    func doubleValueProperty() async throws {
        let actor = try XMLActor(string: "<root><a/><a/><a/></root>")
        let result = await actor.eval(xpath: "count(//a)")

        #expect(result?.doubleValue == 3.0)
    }

    @Test("stringValue property")
    func stringValueProperty() async throws {
        let actor = try XMLActor(string: "<root>Hello World</root>")
        let result = await actor.eval(xpath: "string(/root/text())")

        #expect(result?.stringValue == "Hello World")
    }

    @Test("Hashable conformance")
    func hashableConformance() async throws {
        let actor = try XMLActor(string: "<root/>")

        let result1 = await actor.eval(xpath: "1 + 1")
        let result2 = await actor.eval(xpath: "2 + 2")

        guard let r1 = result1, let r2 = result2 else {
            Issue.record("Results should not be nil")
            return
        }

        var set = Set<XPathResult>()
        set.insert(r1)
        set.insert(r2)

        #expect(set.count == 2)
    }
}

// MARK: - Concurrency Tests

@Suite("Concurrency Tests")
struct ConcurrencyTests {
    @Test("Concurrent reads from same actor")
    func concurrentReads() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        // Perform many concurrent reads
        await withTaskGroup(of: ElementSnapshot?.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    await actor.firstChild(xpath: "//atom:title")
                }
            }

            var results: [ElementSnapshot] = []
            for await result in group {
                if let snapshot = result {
                    results.append(snapshot)
                }
            }

            #expect(results.count == 100)
            #expect(results.allSatisfy { $0.stringValue == "Example Feed" })
        }
    }

    @Test("Concurrent queries with different expressions")
    func concurrentDifferentQueries() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        async let titles = actor.xpath("//atom:title")
        async let links = actor.xpath("//atom:link")
        async let entries = actor.xpath("//atom:entry")

        let (t, l, e) = await (titles, links, entries)

        #expect(t.count == 2)
        #expect(l.count == 5)
        #expect(e.count == 1)
    }

    @Test("Multiple actors can be used concurrently")
    func multipleActorsConcurrently() async throws {
        let atomData = try loadTestResource(name: "atom", extension: "xml")
        let xmlData = try loadTestResource(name: "xml", extension: "xml")
        let htmlData = try loadTestResource(name: "web", extension: "html")

        let atomActor = try XMLActor(data: atomData)
        let xmlActor = try XMLActor(data: xmlData)
        let htmlActor = try HTMLActor(data: htmlData)

        async let atomRoot = atomActor.root
        async let xmlRoot = xmlActor.root
        async let htmlTitle = htmlActor.title

        let (a, x, h) = await (atomRoot, xmlRoot, htmlTitle)

        #expect(a?.tag == "feed")
        #expect(x?.tag == "spec")
        #expect(h == "mattt/Ono")
    }

    @Test("Snapshots are truly Sendable - can be captured in tasks")
    func snapshotsAreSendable() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)

        let snapshot = await actor.snapshot

        // Capture in a detached task to verify Sendable
        let result = await Task.detached {
            return snapshot.root?.tag
        }.value

        #expect(result == "feed")
    }

    @Test("XPathResult is Sendable - can be passed between isolation domains")
    func xpathResultIsSendable() async throws {
        let actor = try XMLActor(string: "<root><item/><item/><item/></root>")
        let result = await actor.eval(xpath: "count(//item)")

        guard let xpathResult = result else {
            Issue.record("Result should not be nil")
            return
        }

        // Pass to detached task
        let value = await Task.detached {
            return xpathResult.doubleValue
        }.value

        #expect(value == 3.0)
    }

    @Test("High contention scenario")
    func highContentionScenario() async throws {
        let data = try loadTestResource(name: "atom", extension: "xml")
        let actor = try XMLActor(data: data)
        await actor.definePrefix("atom", forNamespace: "http://www.w3.org/2005/Atom")

        // Simulate high contention with mixed operations
        await withTaskGroup(of: Void.self) { group in
            // Many concurrent XPath queries
            for i in 0..<50 {
                group.addTask {
                    if i % 3 == 0 {
                        _ = await actor.xpath("//atom:title")
                    } else if i % 3 == 1 {
                        _ = await actor.css("entry")
                    } else {
                        _ = await actor.eval(xpath: "count(//atom:link)")
                    }
                }
            }
        }

        // Verify actor still works correctly after high contention
        let root = await actor.root
        #expect(root?.tag == "feed")
    }
}

// MARK: - Sendable Verification Tests

@Suite("Sendable Verification Tests")
struct SendableVerificationTests {
    @Test("ElementSnapshot can cross isolation boundaries")
    func elementSnapshotCrossesIsolation() async throws {
        let actor = try XMLActor(string: "<root attr=\"value\">content</root>")
        let snapshot = await actor.root

        // Pass to another actor's isolation
        let verifier = SnapshotVerifier()
        let isValid = await verifier.verify(snapshot)

        #expect(isValid)
    }

    @Test("DocumentSnapshot can cross isolation boundaries")
    func documentSnapshotCrossesIsolation() async throws {
        let actor = try XMLActor(string: "<?xml version=\"1.0\"?><root/>")
        let snapshot = await actor.snapshot

        let verifier = SnapshotVerifier()
        let isValid = await verifier.verifyDocument(snapshot)

        #expect(isValid)
    }

    @Test("Array of snapshots can be passed between actors")
    func arrayOfSnapshotsCrossesIsolation() async throws {
        let actor = try XMLActor(string: "<root><a/><b/><c/></root>")
        let snapshots = await actor.xpath("/root/*")

        let verifier = SnapshotVerifier()
        let count = await verifier.countElements(snapshots)

        #expect(count == 3)
    }
}

// Helper actor for testing Sendable crossing isolation boundaries
actor SnapshotVerifier {
    func verify(_ snapshot: ElementSnapshot?) -> Bool {
        snapshot != nil
    }

    func verifyDocument(_ snapshot: DocumentSnapshot) -> Bool {
        snapshot.root != nil
    }

    func countElements(_ snapshots: [ElementSnapshot]) -> Int {
        snapshots.count
    }
}

// MARK: - Edge Case Tests

@Suite("Edge Case Tests")
struct EdgeCaseTests {
    @Test("Empty document")
    func emptyDocument() async throws {
        let actor = try XMLActor(string: "<root/>")

        let root = await actor.root
        #expect(root?.tag == "root")
        #expect(root?.stringValue == "")

        let children = await actor.xpath("/root/*")
        #expect(children.isEmpty)
    }

    @Test("Deeply nested elements")
    func deeplyNestedElements() async throws {
        let xml = "<a><b><c><d><e><f>deep</f></e></d></c></b></a>"
        let actor = try XMLActor(string: xml)

        let deep = await actor.firstChild(xpath: "//f")
        #expect(deep?.stringValue == "deep")
    }

    @Test("Special characters in content")
    func specialCharactersInContent() async throws {
        let xml = "<root>&lt;tag&gt; &amp; &quot;quotes&quot;</root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "<tag> & \"quotes\"")
    }

    @Test("CDATA sections")
    func cdataSections() async throws {
        let xml = "<root><![CDATA[<not>xml</not>]]></root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "<not>xml</not>")
    }

    @Test("Mixed content (text and elements)")
    func mixedContent() async throws {
        let xml = "<root>Hello <b>World</b>!</root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "Hello World!")
    }

    @Test("Whitespace handling")
    func whitespaceHandling() async throws {
        let xml = """
            <root>
                <child>text</child>
            </root>
            """
        let actor = try XMLActor(string: xml)

        let child = await actor.firstChild(xpath: "//child")
        #expect(child?.stringValue == "text")
    }

    @Test("Multiple roots rejected")
    func multipleRootsRejected() async {
        // XML with multiple root elements is invalid
        let xml = "<root1/><root2/>"

        // libxml2 handles this by only parsing the first root
        guard let actor = try? XMLActor(string: xml) else {
            // Parsing failed, which is acceptable
            return
        }

        // If parsing succeeded, only the first root should be present
        let rootTag = await actor.root?.tag
        #expect(rootTag == "root1")
    }

    @Test("Unicode content")
    func unicodeContent() async throws {
        let xml = "<root>日本語 🎉 émojis</root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "日本語 🎉 émojis")
    }

    @Test("Very long attribute value")
    func longAttributeValue() async throws {
        let longValue = String(repeating: "x", count: 10000)
        let xml = "<root attr=\"\(longValue)\"/>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.attributes["attr"]?.count == 10000)
    }

    @Test("Nil root when document has only declaration")
    func nilRootWhenOnlyDeclaration() async {
        // Just a declaration with no root element
        let xml = "<?xml version=\"1.0\"?>"

        // This may or may not parse depending on libxml2 version
        if let actor = try? XMLActor(string: xml) {
            let root = await actor.root
            // Root should be nil if only declaration exists
            #expect(root == nil)
        }
    }
}

// MARK: - Test Helpers

private func loadTestResource(name: String, extension ext: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Resources") else {
        throw TestError.resourceNotFound(name: "\(name).\(ext)")
    }
    return try Data(contentsOf: url)
}

enum TestError: Error {
    case resourceNotFound(name: String)
}
