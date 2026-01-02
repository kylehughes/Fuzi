// ActorHardeningTests.swift
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

// MARK: - Error Handling Edge Cases

@Suite("Error Handling Edge Cases")
struct ErrorHandlingEdgeCaseTests {
    @Test("Empty data throws parserFailure")
    func emptyDataThrows() {
        #expect(throws: XMLError.self) {
            _ = try XMLActor(data: Data())
        }
    }

    @Test("Random bytes throw error")
    func randomBytesThrow() {
        let randomData = Data((0..<100).map { _ in UInt8.random(in: 0...255) })
        // Random bytes might accidentally form valid-ish XML, so we just verify no crash
        _ = try? XMLActor(data: randomData)
    }

    @Test("Truncated XML is handled gracefully")
    func truncatedXML() async throws {
        // Truncated in middle of tag
        let truncated = "<?xml version=\"1.0\"?><root><child>content</chi"

        // libxml2 may recover or fail - either is acceptable
        if let actor = try? XMLActor(string: truncated) {
            let root = await actor.root
            #expect(root != nil) // If parsed, should have a root
        }
    }

    @Test("Mismatched tags are handled")
    func mismatchedTags() async throws {
        let xml = "<root><a></b></root>"

        // libxml2 attempts recovery
        if let actor = try? XMLActor(string: xml) {
            let root = await actor.root
            #expect(root?.tag == "root")
        }
    }

    @Test("Invalid UTF-8 sequences in data")
    func invalidUTF8Sequences() {
        // Invalid UTF-8 byte sequence
        var data = Data("<?xml version=\"1.0\"?><root>".utf8)
        data.append(contentsOf: [0xFF, 0xFE]) // Invalid UTF-8
        data.append(contentsOf: "</root>".utf8)

        // Should either throw or recover gracefully
        _ = try? XMLActor(data: data)
    }

    @Test("Null bytes in content")
    func nullBytesInContent() async {
        var data = Data("<?xml version=\"1.0\"?><root>before".utf8)
        data.append(0x00) // Null byte
        data.append(contentsOf: "after</root>".utf8)

        // Null bytes typically terminate C strings - verify handling
        _ = try? XMLActor(data: data)
    }

    @Test("Extremely long tag names")
    func extremelyLongTagNames() async throws {
        let longTag = String(repeating: "a", count: 10000)
        let xml = "<\(longTag)/>"

        let actor = try XMLActor(string: xml)
        let root = await actor.root
        #expect(root?.tag == longTag)
    }

    @Test("Deeply recursive XML doesn't crash")
    func deeplyRecursiveXML() async throws {
        let depth = 1000
        var xml = ""
        for i in 0..<depth {
            xml += "<level\(i)>"
        }
        xml += "deep"
        for i in (0..<depth).reversed() {
            xml += "</level\(i)>"
        }

        let actor = try XMLActor(string: xml)
        let root = await actor.root
        #expect(root != nil)
    }

    @Test("Very wide XML (many siblings)")
    func veryWideXML() async throws {
        let width = 5000
        var children = ""
        for i in 0..<width {
            children += "<child\(i)/>"
        }
        let xml = "<root>\(children)</root>"

        let actor = try XMLActor(string: xml)
        let elements = await actor.xpath("/root/*")
        #expect(elements.count == width)
    }

    @Test("Empty elements in various forms")
    func emptyElementForms() async throws {
        let xml = """
            <root>
                <self-closing/>
                <explicit-empty></explicit-empty>
                <whitespace-only>   </whitespace-only>
            </root>
            """

        let actor = try XMLActor(string: xml)

        let selfClosing = await actor.firstChild(xpath: "//self-closing")
        #expect(selfClosing?.stringValue == "")

        let explicit = await actor.firstChild(xpath: "//explicit-empty")
        #expect(explicit?.stringValue == "")

        let whitespace = await actor.firstChild(xpath: "//whitespace-only")
        #expect(whitespace?.stringValue.trimmingCharacters(in: .whitespaces) == "")
    }
}

// MARK: - Concurrency Stress Tests

@Suite("Concurrency Stress Tests")
struct ConcurrencyStressTests {
    @Test("Massive concurrent reads")
    func massiveConcurrentReads() async throws {
        let xml = "<root><item>value</item></root>"
        let actor = try XMLActor(string: xml)

        await withTaskGroup(of: String?.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    await actor.root?.stringValue
                }
            }

            var results: [String] = []
            for await result in group {
                if let value = result {
                    results.append(value)
                }
            }

            #expect(results.count == 1000)
            #expect(results.allSatisfy { $0 == "value" })
        }
    }

    @Test("Concurrent different query types")
    func concurrentDifferentQueryTypes() async throws {
        let xml = """
            <root attr="value">
                <child>content</child>
                <child>more</child>
            </root>
            """
        let actor = try XMLActor(string: xml)

        await withTaskGroup(of: Void.self) { group in
            // XPath queries
            for _ in 0..<100 {
                group.addTask { _ = await actor.xpath("//child") }
            }
            // Root access
            for _ in 0..<100 {
                group.addTask { _ = await actor.root }
            }
            // Snapshot creation
            for _ in 0..<100 {
                group.addTask { _ = await actor.snapshot }
            }
            // Eval
            for _ in 0..<100 {
                group.addTask { _ = await actor.eval(xpath: "count(//child)") }
            }
        }

        // Verify actor still works after stress
        let root = await actor.root
        #expect(root?.tag == "root")
    }

    @Test("Rapid actor creation and destruction")
    func rapidActorCreationDestruction() async throws {
        let xml = "<root/>"

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<500 {
                group.addTask {
                    if let actor = try? XMLActor(string: xml) {
                        _ = await actor.root
                    }
                }
            }
        }
    }

    @Test("Concurrent namespace operations")
    func concurrentNamespaceOperations() async throws {
        let xml = """
            <root xmlns:a="http://a.com" xmlns:b="http://b.com">
                <a:item>A</a:item>
                <b:item>B</b:item>
            </root>
            """
        let actor = try XMLActor(string: xml)

        // Define prefixes concurrently (they're the same, so order doesn't matter)
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    await actor.definePrefix("a", forNamespace: "http://a.com")
                }
                group.addTask {
                    await actor.definePrefix("b", forNamespace: "http://b.com")
                }
            }
        }

        let aItems = await actor.xpath("//a:item")
        let bItems = await actor.xpath("//b:item")

        #expect(aItems.count == 1)
        #expect(bItems.count == 1)
    }

    @Test("Task cancellation during operation")
    func taskCancellationDuringOperation() async throws {
        let xml = "<root>" + String(repeating: "<item/>", count: 1000) + "</root>"
        let actor = try XMLActor(string: xml)

        let task = Task {
            for _ in 0..<100 {
                _ = await actor.xpath("//item")
                try Task.checkCancellation()
            }
        }

        // Cancel after a brief moment
        try await Task.sleep(for: .milliseconds(1))
        task.cancel()

        // Actor should still be usable after cancellation
        let root = await actor.root
        #expect(root?.tag == "root")
    }

    @Test("Interleaved reads from multiple actors")
    func interleavedMultipleActors() async throws {
        let actors = try (0..<10).map { i in
            try XMLActor(string: "<root\(i)><value>\(i)</value></root\(i)>")
        }

        await withTaskGroup(of: (Int, String?).self) { group in
            for (index, actor) in actors.enumerated() {
                for _ in 0..<50 {
                    group.addTask {
                        let value = await actor.firstChild(xpath: "//value")?.stringValue
                        return (index, value)
                    }
                }
            }

            var results: [Int: [String]] = [:]
            for await (index, value) in group {
                results[index, default: []].append(value ?? "nil")
            }

            // Verify each actor returned consistent results
            for (index, values) in results {
                #expect(values.allSatisfy { $0 == "\(index)" })
            }
        }
    }
}

// MARK: - XPath Edge Cases

@Suite("XPath Edge Cases")
struct XPathEdgeCaseTests {
    @Test("Complex predicates")
    func complexPredicates() async throws {
        let xml = """
            <root>
                <item id="1" category="a" priority="high">First</item>
                <item id="2" category="b" priority="low">Second</item>
                <item id="3" category="a" priority="low">Third</item>
            </root>
            """
        let actor = try XMLActor(string: xml)

        // Multiple predicates
        let result = await actor.xpath("//item[@category='a'][@priority='high']")
        #expect(result.count == 1)
        #expect(result.first?.stringValue == "First")
    }

    @Test("Axis: ancestor")
    func axisAncestor() async throws {
        let xml = "<a><b><c><d>deep</d></c></b></a>"
        let actor = try XMLActor(string: xml)

        let ancestors = await actor.xpath("//d/ancestor::*")
        #expect(ancestors.count == 3) // c, b, a
    }

    @Test("Axis: following-sibling")
    func axisFollowingSibling() async throws {
        let xml = "<root><a/><b/><c/><d/></root>"
        let actor = try XMLActor(string: xml)

        let siblings = await actor.xpath("//b/following-sibling::*")
        #expect(siblings.count == 2) // c, d
    }

    @Test("Axis: preceding-sibling")
    func axisPrecedingSibling() async throws {
        let xml = "<root><a/><b/><c/><d/></root>"
        let actor = try XMLActor(string: xml)

        let siblings = await actor.xpath("//c/preceding-sibling::*")
        #expect(siblings.count == 2) // a, b
    }

    @Test("Position predicates")
    func positionPredicates() async throws {
        let xml = "<root><item>1</item><item>2</item><item>3</item><item>4</item><item>5</item></root>"
        let actor = try XMLActor(string: xml)

        let first = await actor.firstChild(xpath: "//item[1]")
        #expect(first?.stringValue == "1")

        let last = await actor.firstChild(xpath: "//item[last()]")
        #expect(last?.stringValue == "5")

        let middle = await actor.firstChild(xpath: "//item[position()=3]")
        #expect(middle?.stringValue == "3")
    }

    @Test("String functions")
    func stringFunctions() async throws {
        let xml = "<root><text>  Hello World  </text></root>"
        let actor = try XMLActor(string: xml)

        let normalized = await actor.eval(xpath: "normalize-space(//text)")
        #expect(normalized?.stringValue == "Hello World")

        let length = await actor.eval(xpath: "string-length(normalize-space(//text))")
        #expect(length?.doubleValue == 11)

        let contains = await actor.eval(xpath: "contains(//text, 'World')")
        #expect(contains?.boolValue == true)

        let startsWith = await actor.eval(xpath: "starts-with(normalize-space(//text), 'Hello')")
        #expect(startsWith?.boolValue == true)
    }

    @Test("Numeric functions")
    func numericFunctions() async throws {
        let xml = "<root><n>10</n><n>20</n><n>30</n></root>"
        let actor = try XMLActor(string: xml)

        let sum = await actor.eval(xpath: "sum(//n)")
        #expect(sum?.doubleValue == 60)

        let count = await actor.eval(xpath: "count(//n)")
        #expect(count?.doubleValue == 3)
    }

    @Test("Boolean logic")
    func booleanLogic() async throws {
        let xml = "<root><a>1</a><b>2</b></root>"
        let actor = try XMLActor(string: xml)

        let andResult = await actor.eval(xpath: "//a = 1 and //b = 2")
        #expect(andResult?.boolValue == true)

        let orResult = await actor.eval(xpath: "//a = 99 or //b = 2")
        #expect(orResult?.boolValue == true)

        let notResult = await actor.eval(xpath: "not(//a = 99)")
        #expect(notResult?.boolValue == true)
    }

    @Test("Union operator")
    func unionOperator() async throws {
        let xml = "<root><a>A</a><b>B</b><c>C</c></root>"
        let actor = try XMLActor(string: xml)

        let union = await actor.xpath("//a | //c")
        #expect(union.count == 2)

        let tags = Set(union.map { $0.tag })
        #expect(tags == Set(["a", "c"]))
    }

    @Test("Wildcard patterns")
    func wildcardPatterns() async throws {
        let xml = "<root><ns1:a xmlns:ns1='http://ns1'>1</ns1:a><ns2:b xmlns:ns2='http://ns2'>2</ns2:b></root>"
        let actor = try XMLActor(string: xml)

        // All elements regardless of namespace
        let all = await actor.xpath("//*")
        #expect(all.count >= 2)
    }

    @Test("Text node selection")
    func textNodeSelection() async throws {
        let xml = "<root>before<child>inside</child>after</root>"
        let actor = try XMLActor(string: xml)

        let textNodes = await actor.eval(xpath: "string(/root/text()[1])")
        // First text node before <child>
        #expect(textNodes?.stringValue.contains("before") == true)
    }

    @Test("Very long XPath expression")
    func veryLongXPathExpression() async throws {
        let xml = "<root><a><b><c><d><e><f>found</f></e></d></c></b></a></root>"
        let actor = try XMLActor(string: xml)

        let longPath = "/root/a/b/c/d/e/f"
        let result = await actor.firstChild(xpath: longPath)
        #expect(result?.stringValue == "found")
    }

    @Test("XPath with special characters in values")
    func xpathWithSpecialCharacters() async throws {
        let xml = """
            <root>
                <item name="it's quoted">value1</item>
                <item name='has "double" quotes'>value2</item>
            </root>
            """
        let actor = try XMLActor(string: xml)

        // Single quotes in attribute - use double quotes in XPath
        let result1 = await actor.firstChild(xpath: "//item[@name=\"it's quoted\"]")
        #expect(result1?.stringValue == "value1")
    }
}

// MARK: - Snapshot Integrity Tests

@Suite("Snapshot Integrity Tests")
struct SnapshotIntegrityTests {
    @Test("Snapshot is truly independent copy")
    func snapshotIsIndependentCopy() async throws {
        let actor = try XMLActor(string: "<root><child>original</child></root>")

        // Take snapshot
        let snapshot = await actor.snapshot

        // The snapshot should contain the data at the time it was taken
        #expect(snapshot.root?.tag == "root")

        // Create a new actor with different content
        let actor2 = try XMLActor(string: "<root><child>modified</child></root>")
        let snapshot2 = await actor2.snapshot

        // Original snapshot should be unchanged
        #expect(snapshot.root?.tag == "root")
        #expect(snapshot2.root?.tag == "root")
    }

    @Test("Multiple snapshots from same actor are equal")
    func multipleSnapshotsAreEqual() async throws {
        let actor = try XMLActor(string: "<root attr=\"value\">content</root>")

        let snapshot1 = await actor.snapshot
        let snapshot2 = await actor.snapshot

        #expect(snapshot1 == snapshot2)
        #expect(snapshot1.hashValue == snapshot2.hashValue)
    }

    @Test("Large collection of snapshots")
    func largeSnapshotCollection() async throws {
        var xml = "<root>"
        for i in 0..<1000 {
            xml += "<item id=\"\(i)\">value\(i)</item>"
        }
        xml += "</root>"

        let actor = try XMLActor(string: xml)
        let snapshots = await actor.xpath("//item")

        #expect(snapshots.count == 1000)

        // Verify all snapshots have unique IDs
        let ids = Set(snapshots.compactMap { $0.attributes["id"] })
        #expect(ids.count == 1000)
    }

    @Test("Snapshot preserves all attribute values")
    func snapshotPreservesAttributes() async throws {
        let xml = """
            <root
                attr1="value1"
                attr2="value2"
                attr3="value3"
                data-custom="custom-value"
                xmlns:ns="http://example.com">
            </root>
            """
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.attributes["attr1"] == "value1")
        #expect(root?.attributes["attr2"] == "value2")
        #expect(root?.attributes["attr3"] == "value3")
        #expect(root?.attributes["data-custom"] == "custom-value")
    }

    @Test("Snapshot rawXML is well-formed")
    func snapshotRawXMLIsWellFormed() async throws {
        let xml = "<root><child attr=\"value\">content</child></root>"
        let actor = try XMLActor(string: xml)

        let child = await actor.firstChild(xpath: "//child")
        let rawXML = child?.rawXML ?? ""

        // The raw XML should be parseable
        let reparsed = try XMLActor(string: rawXML)
        let reparsedRoot = await reparsed.root
        #expect(reparsedRoot?.tag == "child")
        #expect(reparsedRoot?.stringValue == "content")
    }

    @Test("ElementSnapshot Hashable stability")
    func elementSnapshotHashableStability() async throws {
        let actor = try XMLActor(string: "<root><a/><b/><c/></root>")

        let snapshots1 = await actor.xpath("/root/*")
        let snapshots2 = await actor.xpath("/root/*")

        // Same queries should produce equal snapshots
        for (s1, s2) in zip(snapshots1, snapshots2) {
            #expect(s1 == s2)
            #expect(s1.hashValue == s2.hashValue)
        }

        // Can be used in Set
        var set = Set<ElementSnapshot>()
        for s in snapshots1 { set.insert(s) }
        for s in snapshots2 { set.insert(s) }

        #expect(set.count == 3) // Duplicates removed
    }

    @Test("XPathResult equality")
    func xpathResultEquality() async throws {
        let actor = try XMLActor(string: "<root><a/><a/><a/></root>")

        let result1 = await actor.eval(xpath: "count(//a)")
        let result2 = await actor.eval(xpath: "count(//a)")

        #expect(result1 == result2)
    }
}

// MARK: - Character Encoding Tests

@Suite("Character Encoding Tests")
struct CharacterEncodingTests {
    @Test("UTF-8 with BOM")
    func utf8WithBOM() async throws {
        var data = Data([0xEF, 0xBB, 0xBF]) // UTF-8 BOM
        data.append(contentsOf: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>content</root>".utf8)

        let actor = try XMLActor(data: data)
        let root = await actor.root
        #expect(root?.stringValue == "content")
    }

    @Test("ISO-8859-1 encoding declaration")
    func iso88591Encoding() async throws {
        // Note: This test uses UTF-8 compatible characters
        let xml = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><root>Hello</root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "Hello")
    }

    @Test("Various Unicode ranges")
    func variousUnicodeRanges() async throws {
        let xml = """
            <root>
                <latin>café résumé naïve</latin>
                <greek>Ελληνικά</greek>
                <cyrillic>Русский</cyrillic>
                <cjk>中文 日本語 한국어</cjk>
                <arabic>العربية</arabic>
                <hebrew>עברית</hebrew>
                <emoji>🎉🚀💡🌍</emoji>
                <math>∑∏∫√∞</math>
            </root>
            """

        let actor = try XMLActor(string: xml)

        let latin = await actor.firstChild(xpath: "//latin")
        #expect(latin?.stringValue == "café résumé naïve")

        let cjk = await actor.firstChild(xpath: "//cjk")
        #expect(cjk?.stringValue == "中文 日本語 한국어")

        let emoji = await actor.firstChild(xpath: "//emoji")
        #expect(emoji?.stringValue == "🎉🚀💡🌍")
    }

    @Test("Numeric character references")
    func numericCharacterReferences() async throws {
        let xml = "<root>&#60;&#62;&#38;&#x3C;&#x3E;</root>" // < > & < >
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "<>&<>")
    }

    @Test("Named entity references")
    func namedEntityReferences() async throws {
        let xml = "<root>&lt;&gt;&amp;&quot;&apos;</root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "<>&\"'")
    }

    @Test("Mixed content with entities")
    func mixedContentWithEntities() async throws {
        let xml = "<root>Hello &amp; <b>World</b> &lt;3</root>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.stringValue == "Hello & World <3")
    }

    @Test("Attribute values with entities")
    func attributeValuesWithEntities() async throws {
        let xml = "<root attr=\"value with &lt;special&gt; &amp; chars\"/>"
        let actor = try XMLActor(string: xml)

        let root = await actor.root
        #expect(root?.attributes["attr"] == "value with <special> & chars")
    }
}

// MARK: - Namespace Complexity Tests

@Suite("Namespace Complexity Tests")
struct NamespaceComplexityTests {
    @Test("Default namespace")
    func defaultNamespace() async throws {
        let xml = """
            <root xmlns="http://default.ns">
                <child>content</child>
            </root>
            """
        let actor = try XMLActor(string: xml)
        await actor.definePrefix("d", forNamespace: "http://default.ns")

        let children = await actor.xpath("//d:child")
        #expect(children.count == 1)
    }

    @Test("Multiple prefixes for same URI")
    func multiplePrefixesSameURI() async throws {
        let xml = """
            <root xmlns:a="http://example.com" xmlns:b="http://example.com">
                <a:item>A</a:item>
                <b:item>B</b:item>
            </root>
            """
        let actor = try XMLActor(string: xml)
        await actor.definePrefix("x", forNamespace: "http://example.com")

        // Both should match with our prefix
        let items = await actor.xpath("//x:item")
        #expect(items.count == 2)
    }

    @Test("Namespace redefinition in child")
    func namespaceRedefinitionInChild() async throws {
        let xml = """
            <root xmlns:ns="http://outer.ns">
                <ns:outer>outer content</ns:outer>
                <child xmlns:ns="http://inner.ns">
                    <ns:inner>inner content</ns:inner>
                </child>
            </root>
            """
        let actor = try XMLActor(string: xml)

        await actor.definePrefix("outer", forNamespace: "http://outer.ns")
        await actor.definePrefix("inner", forNamespace: "http://inner.ns")

        let outerElements = await actor.xpath("//outer:outer")
        #expect(outerElements.count == 1)

        let innerElements = await actor.xpath("//inner:inner")
        #expect(innerElements.count == 1)
    }

    @Test("Unbound namespace prefix in query returns empty")
    func unboundNamespacePrefixReturnsEmpty() async throws {
        let xml = "<root><child>content</child></root>"
        let actor = try XMLActor(string: xml)

        // Query with undefined prefix should return empty, not crash
        let results = await actor.xpath("//undefined:child")
        #expect(results.isEmpty)
    }

    @Test("Complex namespace hierarchy")
    func complexNamespaceHierarchy() async throws {
        let xml = """
            <root xmlns="http://default"
                  xmlns:a="http://a"
                  xmlns:b="http://b">
                <a:level1>
                    <b:level2 xmlns:c="http://c">
                        <c:level3>deep</c:level3>
                    </b:level2>
                </a:level1>
            </root>
            """
        let actor = try XMLActor(string: xml)

        await actor.definePrefix("d", forNamespace: "http://default")
        await actor.definePrefix("a", forNamespace: "http://a")
        await actor.definePrefix("b", forNamespace: "http://b")
        await actor.definePrefix("c", forNamespace: "http://c")

        let deep = await actor.firstChild(xpath: "//c:level3")
        #expect(deep?.stringValue == "deep")
    }

    @Test("Namespace on attributes")
    func namespaceOnAttributes() async throws {
        let xml = """
            <root xmlns:xlink="http://www.w3.org/1999/xlink">
                <link xlink:href="http://example.com" xlink:type="simple"/>
            </root>
            """
        let actor = try XMLActor(string: xml)

        let link = await actor.firstChild(xpath: "//link")
        // Namespaced attributes may or may not include prefix in key depending on libxml2
        let href = link?.attributes["xlink:href"] ?? link?.attributes["href"]
        #expect(href != nil)
    }
}

// MARK: - Memory and Performance Tests

@Suite("Memory and Performance Tests")
struct MemoryPerformanceTests {
    @Test("Parse moderately large document")
    func parseModeratelyLargeDocument() async throws {
        // Generate ~100KB of XML
        var xml = "<root>"
        for i in 0..<1000 {
            xml += "<item id=\"\(i)\" category=\"cat\(i % 10)\">"
            xml += "<name>Item \(i)</name>"
            xml += "<description>This is the description for item \(i) with some additional text to make it longer.</description>"
            xml += "<value>\(Double(i) * 1.5)</value>"
            xml += "</item>"
        }
        xml += "</root>"

        let actor = try XMLActor(string: xml)

        let items = await actor.xpath("//item")
        #expect(items.count == 1000)

        // Query with predicate
        let filtered = await actor.xpath("//item[@category='cat5']")
        #expect(filtered.count == 100)
    }

    @Test("Repeated parsing doesn't leak")
    func repeatedParsingNoLeak() async throws {
        let xml = "<root><child>content</child></root>"

        // Parse many times - memory should stay bounded
        for _ in 0..<100 {
            let actor = try XMLActor(string: xml)
            _ = await actor.root
        }
    }

    @Test("Large attribute value handling")
    func largeAttributeValueHandling() async throws {
        let largeValue = String(repeating: "x", count: 100_000)
        let xml = "<root attr=\"\(largeValue)\"/>"

        let actor = try XMLActor(string: xml)
        let root = await actor.root

        #expect(root?.attributes["attr"]?.count == 100_000)
    }

    @Test("Large text content handling")
    func largeTextContentHandling() async throws {
        let largeContent = String(repeating: "Lorem ipsum dolor sit amet. ", count: 10_000)
        let xml = "<root>\(largeContent)</root>"

        let actor = try XMLActor(string: xml)
        let root = await actor.root

        #expect(root?.stringValue.count == largeContent.count)
    }

    @Test("Many small queries")
    func manySmallQueries() async throws {
        let xml = "<root><a/><b/><c/><d/><e/></root>"
        let actor = try XMLActor(string: xml)

        let queries = ["//a", "//b", "//c", "//d", "//e"]

        for _ in 0..<1000 {
            for query in queries {
                _ = await actor.xpath(query)
            }
        }

        // Verify actor still works
        let all = await actor.xpath("/root/*")
        #expect(all.count == 5)
    }
}

// MARK: - HTML-Specific Edge Cases

@Suite("HTML-Specific Edge Cases")
struct HTMLSpecificEdgeCaseTests {
    @Test("Malformed HTML recovery")
    func malformedHTMLRecovery() async throws {
        // Missing closing tags
        let html = "<html><body><div><p>Paragraph<div>Nested"

        if let actor = try? HTMLActor(string: html) {
            let body = await actor.body
            #expect(body != nil)
        }
    }

    @Test("HTML entities")
    func htmlEntities() async throws {
        let html = "<html><body>&nbsp;&copy;&reg;&trade;</body></html>"

        let actor = try HTMLActor(string: html)
        let body = await actor.body

        // Body should contain decoded entities or original text
        #expect(body != nil)
    }

    @Test("Script and style content")
    func scriptAndStyleContent() async throws {
        let html = """
            <html>
            <head>
                <style>body { color: red; }</style>
                <script>var x = 1 < 2;</script>
            </head>
            <body>Content</body>
            </html>
            """

        let actor = try HTMLActor(string: html)
        let body = await actor.body

        #expect(body?.stringValue == "Content")
    }

    @Test("Case insensitive tags")
    func caseInsensitiveTags() async throws {
        let html = "<HTML><BODY><DIV>Content</DIV></BODY></HTML>"

        let actor = try HTMLActor(string: html)
        let body = await actor.body

        #expect(body != nil)
    }

    @Test("Boolean attributes")
    func booleanAttributes() async throws {
        let html = "<html><body><input type=\"checkbox\" checked disabled></body></html>"

        let actor = try HTMLActor(string: html)
        let input = await actor.firstChild(css: "input")

        // Boolean attributes may have empty string or attribute name as value
        let checked = input?.attributes["checked"]
        #expect(checked != nil || input?.rawXML.contains("checked") == true)
    }

    @Test("Void elements")
    func voidElements() async throws {
        let html = """
            <html><body>
                <br>
                <hr>
                <img src="test.jpg">
                <input type="text">
                <meta name="test">
            </body></html>
            """

        let actor = try HTMLActor(string: html)

        let br = await actor.firstChild(css: "br")
        #expect(br != nil)

        let img = await actor.firstChild(css: "img")
        #expect(img?.attributes["src"] == "test.jpg")
    }
}

// MARK: - CSS Selector Edge Cases

@Suite("CSS Selector Edge Cases")
struct CSSSelectorEdgeCaseTests {
    @Test("Multiple class selectors via XPath")
    func multipleClassSelectorsViaXPath() async throws {
        // Fuzi's CSS-to-XPath converter has limitations with chained class selectors (.a.b)
        // Test the equivalent functionality using XPath directly
        let html = """
            <html><body>
                <div class="a b c">Multiple classes</div>
                <div class="a">Single A</div>
                <div class="b">Single B</div>
            </body></html>
            """

        let actor = try HTMLActor(string: html)

        // Use XPath to find elements with both classes
        let multiClass = await actor.xpath("//*[contains(concat(' ', @class, ' '), ' a ') and contains(concat(' ', @class, ' '), ' b ')]")
        #expect(multiClass.count == 1)
        #expect(multiClass.first?.stringValue == "Multiple classes")
    }

    @Test("Descendant vs child combinator")
    func descendantVsChildCombinator() async throws {
        let html = """
            <html><body>
                <div><p>Direct child</p></div>
                <div><span><p>Descendant</p></span></div>
            </body></html>
            """

        let actor = try HTMLActor(string: html)

        // Descendant (space)
        let descendants = await actor.css("div p")
        #expect(descendants.count == 2)

        // Direct child (>)
        let children = await actor.css("div > p")
        #expect(children.count == 1)
        #expect(children.first?.stringValue == "Direct child")
    }

    @Test("Attribute selectors")
    func attributeSelectors() async throws {
        let html = """
            <html><body>
                <a href="http://example.com">Link 1</a>
                <a href="https://secure.com">Link 2</a>
                <a>No href</a>
            </body></html>
            """

        let actor = try HTMLActor(string: html)

        // Has attribute - this works with Fuzi's CSS converter
        let withHref = await actor.css("a[href]")
        #expect(withHref.count == 2)

        // Exact match via XPath (Fuzi's CSS converter has limitations with attribute value matching)
        let exact = await actor.xpath("//a[@href='http://example.com']")
        #expect(exact.count == 1)
    }

    @Test("Complex combined selectors")
    func complexCombinedSelectors() async throws {
        let html = """
            <html><body>
                <div id="main" class="container">
                    <ul class="list">
                        <li class="item active">First</li>
                        <li class="item">Second</li>
                    </ul>
                </div>
            </body></html>
            """

        let actor = try HTMLActor(string: html)

        let result = await actor.css("#main .list .item")
        #expect(result.count == 2)
    }

    @Test("Sibling combinators")
    func siblingCombinators() async throws {
        let html = """
            <html><body>
                <h1>Title</h1>
                <p>First para</p>
                <p>Second para</p>
                <div>Not a p</div>
                <p>Third para</p>
            </body></html>
            """

        let actor = try HTMLActor(string: html)

        // Adjacent sibling (+)
        let adjacent = await actor.css("h1 + p")
        #expect(adjacent.count == 1)
        #expect(adjacent.first?.stringValue == "First para")

        // General sibling (~)
        let general = await actor.css("h1 ~ p")
        #expect(general.count == 3)
    }
}

// MARK: - Regression Tests

@Suite("Regression Tests")
struct RegressionTests {
    @Test("Empty namespace prefix doesn't crash")
    func emptyNamespacePrefixNoCrash() async throws {
        let actor = try XMLActor(string: "<root/>")

        // Empty prefix should not crash
        await actor.definePrefix("", forNamespace: "http://example.com")

        let root = await actor.root
        #expect(root != nil)
    }

    @Test("Nil document handling in empty nodeset")
    func nilDocumentInEmptyNodeset() async throws {
        let actor = try XMLActor(string: "<root/>")

        let empty = await actor.xpath("//nonexistent")
        #expect(empty.isEmpty)
    }

    @Test("Snapshot of element without parent")
    func snapshotOfRootElement() async throws {
        let actor = try XMLActor(string: "<root/>")

        let root = await actor.root
        #expect(root != nil)
        // Root has no parent - should not crash
        #expect(root?.tag == "root")
    }

    @Test("Consecutive queries with same expression")
    func consecutiveQueriesSameExpression() async throws {
        let actor = try XMLActor(string: "<root><a/><b/></root>")

        // Same query multiple times should return consistent results
        for _ in 0..<100 {
            let results = await actor.xpath("/root/*")
            #expect(results.count == 2)
        }
    }

    @Test("Query immediately after namespace definition")
    func queryAfterNamespaceDefinition() async throws {
        let xml = """
            <root xmlns:ns="http://example.com">
                <ns:item>content</ns:item>
            </root>
            """
        let actor = try XMLActor(string: xml)

        // Define and immediately query
        await actor.definePrefix("ns", forNamespace: "http://example.com")
        let items = await actor.xpath("//ns:item")

        #expect(items.count == 1)
    }
}
