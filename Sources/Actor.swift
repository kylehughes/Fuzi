// Actor.swift
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

// MARK: - ElementSnapshot

/// A thread-safe, immutable snapshot of an XML element's data.
///
/// `ElementSnapshot` captures the essential data from an `XMLElement` in a `Sendable` form
/// that can safely cross actor isolation boundaries. Use this when you need to pass element
/// data between isolation domains.
public struct ElementSnapshot: Sendable, Hashable {
    // MARK: Public Instance Properties

    /// All attributes for the element.
    public let attributes: [String: String]

    /// The element's line number in the source document.
    public let lineNumber: Int

    /// The element's namespace prefix, if any.
    public let namespace: String?

    /// The raw XML string of the element.
    public let rawXML: String

    /// A string representation of the element's value.
    public let stringValue: String

    /// The element's tag name.
    public let tag: String?

    // MARK: Internal Initialization

    internal init(element: XMLElement) {
        self.attributes = element.attributes
        self.lineNumber = element.lineNumber
        self.namespace = element.namespace
        self.rawXML = element.rawXML
        self.stringValue = element.stringValue
        self.tag = element.tag
    }
}

// MARK: - DocumentSnapshot

/// A thread-safe, immutable snapshot of an XML document's metadata.
public struct DocumentSnapshot: Sendable, Hashable {
    // MARK: Public Instance Properties

    /// The string encoding for the document.
    public let encoding: String.Encoding

    /// The root element snapshot, if the document has a root.
    public let root: ElementSnapshot?

    /// The XML version string.
    public let version: String?

    // MARK: Internal Initialization

    internal init(document: XMLDocument) {
        self.encoding = document.encoding
        self.root = document.root.map(ElementSnapshot.init)
        self.version = document.version
    }
}

// MARK: - XPathResult

/// A thread-safe result from an XPath function evaluation.
public struct XPathResult: Sendable, Hashable {
    // MARK: Public Instance Properties

    /// Boolean interpretation of the result.
    public let boolValue: Bool

    /// Double interpretation of the result.
    public let doubleValue: Double

    /// String interpretation of the result.
    public let stringValue: String

    // MARK: Internal Initialization

    internal init(result: XPathFunctionResult) {
        self.boolValue = result.boolValue
        self.doubleValue = result.doubleValue
        self.stringValue = result.stringValue
    }
}

// MARK: - XMLActor

/// An actor that provides thread-safe access to XML document parsing and querying.
///
/// `XMLActor` wraps libxml2 operations in an actor to ensure all XML operations are
/// serialized, preventing data races. Use this actor when you need to parse or query
/// XML documents from multiple concurrent contexts.
///
/// ## Example
///
/// ```swift
/// let actor = try XMLActor(data: xmlData)
///
/// // Query from any isolation domain
/// let titles = await actor.xpath("//title")
/// for title in titles {
///     print(title.stringValue)
/// }
/// ```
///
/// ## Thread Safety
///
/// All methods on `XMLActor` are safe to call from any isolation domain. The actor
/// serializes access to the underlying libxml2 document, which is not thread-safe.
public actor XMLActor {
    // MARK: Private Instance Properties

    private let document: XMLDocument

    // MARK: Public Initialization

    /// Creates an actor wrapping an XML document parsed from the given data.
    ///
    /// - Parameter data: The XML data to parse.
    /// - Throws: `XMLError` if parsing fails.
    public init(data: Data) throws {
        self.document = try XMLDocument(data: data)
    }

    /// Creates an actor wrapping an XML document parsed from the given string.
    ///
    /// - Parameters:
    ///   - string: The XML string to parse.
    ///   - encoding: The string encoding. Defaults to UTF-8.
    /// - Throws: `XMLError` if parsing fails.
    public init(string: String, encoding: String.Encoding = .utf8) throws {
        self.document = try XMLDocument(string: string, encoding: encoding)
    }

    /// Creates an actor wrapping an XML document parsed from a C character array.
    ///
    /// - Parameter cChars: The XML data as a C character array.
    /// - Throws: `XMLError` if parsing fails.
    public init(cChars: [CChar]) throws {
        self.document = try XMLDocument(cChars: cChars)
    }

    // MARK: Public Instance Interface - Document Properties

    /// The string encoding for the document.
    public var encoding: String.Encoding {
        document.encoding
    }

    /// A snapshot of the root element, if present.
    public var root: ElementSnapshot? {
        document.root.map(ElementSnapshot.init)
    }

    /// Returns a snapshot of the document's metadata.
    public var snapshot: DocumentSnapshot {
        DocumentSnapshot(document: document)
    }

    /// The XML version string.
    public var version: String? {
        document.version
    }

    // MARK: Public Instance Interface - Namespace Configuration

    /// Defines a prefix for the given namespace in XPath expressions.
    ///
    /// - Parameters:
    ///   - prefix: The prefix name to use in XPath expressions.
    ///   - namespace: The namespace URI declared in the XML document.
    public func definePrefix(_ prefix: String, forNamespace namespace: String) {
        document.definePrefix(prefix, forNamespace: namespace)
    }

    // MARK: Public Instance Interface - XPath Queries

    /// Returns snapshots of all elements matching an XPath expression.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: An array of element snapshots matching the expression.
    public func xpath(_ xpath: String) -> [ElementSnapshot] {
        document.xpath(xpath).map(ElementSnapshot.init)
    }

    /// Returns snapshots of all elements matching an XPath expression.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: An array of element snapshots matching the expression.
    /// - Throws: `XMLError` if the XPath expression is invalid.
    public func tryXPath(_ xpath: String) throws -> [ElementSnapshot] {
        try document.tryXPath(xpath).map(ElementSnapshot.init)
    }

    /// Returns a snapshot of the first element matching an XPath expression.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: A snapshot of the first matching element, or `nil` if none match.
    public func firstChild(xpath: String) -> ElementSnapshot? {
        document.firstChild(xpath: xpath).map(ElementSnapshot.init)
    }

    // MARK: Public Instance Interface - CSS Queries

    /// Returns snapshots of all elements matching a CSS selector.
    ///
    /// - Parameter css: The CSS selector to evaluate.
    /// - Returns: An array of element snapshots matching the selector.
    public func css(_ css: String) -> [ElementSnapshot] {
        document.css(css).map(ElementSnapshot.init)
    }

    /// Returns a snapshot of the first element matching a CSS selector.
    ///
    /// - Parameter css: The CSS selector to evaluate.
    /// - Returns: A snapshot of the first matching element, or `nil` if none match.
    public func firstChild(css: String) -> ElementSnapshot? {
        document.firstChild(css: css).map(ElementSnapshot.init)
    }

    // MARK: Public Instance Interface - XPath Function Evaluation

    /// Evaluates an XPath expression that returns a function result.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: The function result, or `nil` if evaluation fails.
    public func eval(xpath: String) -> XPathResult? {
        document.root?.eval(xpath: xpath).map(XPathResult.init)
    }
}

// MARK: - HTMLActor

/// An actor that provides thread-safe access to HTML document parsing and querying.
///
/// `HTMLActor` is a specialized version of `XMLActor` for HTML documents. It provides
/// convenient access to common HTML elements like head, body, and title.
///
/// ## Example
///
/// ```swift
/// let actor = try HTMLActor(data: htmlData)
///
/// // Access HTML-specific properties
/// if let title = await actor.title {
///     print("Page title: \(title)")
/// }
///
/// // Query using CSS selectors
/// let links = await actor.css("a[href]")
/// ```
public actor HTMLActor {
    // MARK: Private Instance Properties

    private let document: HTMLDocument

    // MARK: Public Initialization

    /// Creates an actor wrapping an HTML document parsed from the given data.
    ///
    /// - Parameter data: The HTML data to parse.
    /// - Throws: `XMLError` if parsing fails.
    public init(data: Data) throws {
        self.document = try HTMLDocument(data: data)
    }

    /// Creates an actor wrapping an HTML document parsed from the given string.
    ///
    /// - Parameters:
    ///   - string: The HTML string to parse.
    ///   - encoding: The string encoding. Defaults to UTF-8.
    /// - Throws: `XMLError` if parsing fails.
    public init(string: String, encoding: String.Encoding = .utf8) throws {
        self.document = try HTMLDocument(string: string, encoding: encoding)
    }

    /// Creates an actor wrapping an HTML document parsed from a C character array.
    ///
    /// - Parameter cChars: The HTML data as a C character array.
    /// - Throws: `XMLError` if parsing fails.
    public init(cChars: [CChar]) throws {
        self.document = try HTMLDocument(cChars: cChars)
    }

    // MARK: Public Instance Interface - Document Properties

    /// A snapshot of the root element, if present.
    public var root: ElementSnapshot? {
        document.root.map(ElementSnapshot.init)
    }

    /// Returns a snapshot of the document's metadata.
    public var snapshot: DocumentSnapshot {
        DocumentSnapshot(document: document)
    }

    // MARK: Public Instance Interface - HTML-Specific Properties

    /// A snapshot of the HTML body element.
    public var body: ElementSnapshot? {
        document.body.map(ElementSnapshot.init)
    }

    /// A snapshot of the HTML head element.
    public var head: ElementSnapshot? {
        document.head.map(ElementSnapshot.init)
    }

    /// The HTML document's title.
    public var title: String? {
        document.title
    }

    // MARK: Public Instance Interface - Namespace Configuration

    /// Defines a prefix for the given namespace in XPath expressions.
    ///
    /// - Parameters:
    ///   - prefix: The prefix name to use in XPath expressions.
    ///   - namespace: The namespace URI declared in the document.
    public func definePrefix(_ prefix: String, forNamespace namespace: String) {
        document.definePrefix(prefix, forNamespace: namespace)
    }

    // MARK: Public Instance Interface - XPath Queries

    /// Returns snapshots of all elements matching an XPath expression.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: An array of element snapshots matching the expression.
    public func xpath(_ xpath: String) -> [ElementSnapshot] {
        document.xpath(xpath).map(ElementSnapshot.init)
    }

    /// Returns snapshots of all elements matching an XPath expression.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: An array of element snapshots matching the expression.
    /// - Throws: `XMLError` if the XPath expression is invalid.
    public func tryXPath(_ xpath: String) throws -> [ElementSnapshot] {
        try document.tryXPath(xpath).map(ElementSnapshot.init)
    }

    /// Returns a snapshot of the first element matching an XPath expression.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: A snapshot of the first matching element, or `nil` if none match.
    public func firstChild(xpath: String) -> ElementSnapshot? {
        document.firstChild(xpath: xpath).map(ElementSnapshot.init)
    }

    // MARK: Public Instance Interface - CSS Queries

    /// Returns snapshots of all elements matching a CSS selector.
    ///
    /// - Parameter css: The CSS selector to evaluate.
    /// - Returns: An array of element snapshots matching the selector.
    public func css(_ css: String) -> [ElementSnapshot] {
        document.css(css).map(ElementSnapshot.init)
    }

    /// Returns a snapshot of the first element matching a CSS selector.
    ///
    /// - Parameter css: The CSS selector to evaluate.
    /// - Returns: A snapshot of the first matching element, or `nil` if none match.
    public func firstChild(css: String) -> ElementSnapshot? {
        document.firstChild(css: css).map(ElementSnapshot.init)
    }

    // MARK: Public Instance Interface - XPath Function Evaluation

    /// Evaluates an XPath expression that returns a function result.
    ///
    /// - Parameter xpath: The XPath expression to evaluate.
    /// - Returns: The function result, or `nil` if evaluation fails.
    public func eval(xpath: String) -> XPathResult? {
        document.root?.eval(xpath: xpath).map(XPathResult.init)
    }
}
