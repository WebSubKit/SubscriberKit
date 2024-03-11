//
//  PerformDiscoveryMechanism.swift
//
//
//  Created by Bunga Mungil on 09/03/24.
//

import Foundation
import SwiftSoup


// MARK: - Perform discovery mechanism on header

extension HTTPURLResponse {
    
    func performDiscoveryMechanism() throws -> (topic: URL, hubs: [URL]) {
        guard let linkHeader = self.value(forHTTPHeaderField: "Link") else {
            throw DiscoveryMechanismResultError.containsNoLinkOnHeaderFields
        }
        let links = linkHeader.split(separator: ",")
            .map { String($0) }
            .asLinks()
        guard let topic = try? links
            .first(where: { $0.rel == .`self` })?.value
            .convertToURL()
        else {
            throw DiscoveryMechanismResultError.containsNoTopic
        }
        guard let hubs = try? links
            .filter({ $0.rel == .hub })
            .map({ try $0.value.convertToURL() }),
              !hubs.isEmpty
        else {
            throw DiscoveryMechanismResultError.containsNoHub
        }
        return (topic, hubs)
    }
    
}


// MARK: - Utilities to perform discovery mechanism on header

private struct Link {
    
    let value: String
    
    let rel: LinkRelation
    
    init?(from linkHeader: String) {
        let splited = linkHeader.split(separator: ";").map({ String($0) })
        guard var value = splited.first, let last = splited.last else {
            return nil
        }
        guard let rel = LinkRelation(from: last) else {
            return nil
        }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("<") && value.hasSuffix(">") {
            value.removeFirst()
            value.removeLast()
        }
        self.value = value
        self.rel = rel
    }
    
}


private enum LinkRelation {
    case `self`
    case hub
    case other
    
    init?(from rel: String) {
        if rel.contains("self") {
            self = .`self`
            return
        }
        if rel.contains("hub") {
            self = .hub
            return
        }
        self = .other
    }
}


extension Sequence<String> {
    
    fileprivate func asLinks() -> [Link] {
        flatMap { string in
            if let link = Link(from: string) {
                return [link]
            }
            return []
        }
    }
    
}


// MARK: - Perform discovery mechanism on body

extension Data {
    
    func performDiscoveryMechanism() throws -> (topic: URL, hubs: [URL]) {
        guard let string = String(data: self, encoding: .utf8) else {
            throw DiscoveryMechanismResultError.failedToEncodeData
        }
        if let onHTML = try? onHTML(string) {
            return onHTML
        }
        if let onXML = try? onXML(string) {
            return onXML
        }
        throw DiscoveryMechanismResultError.containsNoLinkOnData
    }

    fileprivate func onHTML(_ htmlString: String) throws -> (topic: URL, hubs: [URL]) {
        guard let htmlDocument = try? SwiftSoup.parse(htmlString) else {
            throw DiscoveryMechanismResultError.failedToInitiateHTMLParser
        }
        if let onHTML = try? htmlDocument.head()?.select("link").performDiscoveryMechanism() {
            return onHTML
        }
        throw DiscoveryMechanismResultError.containsNoLinkOnHTMLData
    }

    fileprivate func onXML(_ xmlString: String) throws -> (topic: URL, hubs: [URL]) {
        guard let xmlDocument = try? SwiftSoup.parse(xmlString, "", Parser.xmlParser()) else {
            throw DiscoveryMechanismResultError.failedToInitiateXMLParser
        }
        if let onRSS = try? xmlDocument.select("link").performDiscoveryMechanism() {
            return onRSS
        }
        if let onAtom = try? xmlDocument.select("atom|link").performDiscoveryMechanism() {
            return onAtom
        }
        throw DiscoveryMechanismResultError.containsNoLinkOnXMLData
    }
    
}


extension Sequence<Element> {
    
    fileprivate func performDiscoveryMechanism() throws -> (topic: URL, hubs: [URL]) {
        return try discoveryMechanismResult(
            mayContainsTopic: try first { (try $0.attr("rel") == "self") }?.attr("href"),
            mayContainsHubs: filter { (try $0.attr("rel") == "hub") }.map { try $0.attr("href") }
        )
    }
    
}


// MARK: - Utilities to perform discovery mechanism on body

extension Sequence<String?> {
    
    fileprivate func asURLs() throws -> [URL] { 
        try flatMap { string in
            if let string {
                return [try string.convertToURL()]
            }
            return []
        }
    }
    
}


fileprivate func discoveryMechanismResult(
    mayContainsTopic: String?,
    mayContainsHubs: [String?]?
) throws -> (topic: URL, hubs: [URL]) {
    guard let topic = try? mayContainsTopic?.convertToURL() else {
        throw DiscoveryMechanismResultError.containsNoTopic
    }
    guard let hubs = try? mayContainsHubs?.asURLs(), !hubs.isEmpty else {
        throw DiscoveryMechanismResultError.containsNoHub
    }
    return (topic: topic, hubs: hubs)
}


// MARK: - Error type throwing when performing discovery mechanism

enum DiscoveryMechanismResultError: Error {
    case failedToEncodeData
    case failedToInitiateHTMLParser
    case failedToInitiateXMLParser
    case containsNoLinkOnHTMLData
    case containsNoLinkOnXMLData
    case containsNoLinkOnData
    case containsNoLinkOnHeaderFields
    case containsNoTopic
    case containsNoHub
}
