//
//  SubscriptionRequest.swift
//
//
//  Created by Bunga Mungil on 08/02/24.
//

import Foundation


public struct SubscriptionRequest: Codable {
    
    public let callback: String

    public let topic: String

    public let mode: SubscriptionMode

    public let leaseSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case callback = "hub.callback"
        case topic = "hub.topic"
        case mode = "hub.mode"
        case leaseSeconds = "hub.lease_seconds"
    }
    
}


public enum SubscriptionMode: String, Codable {
    case subscribe
    case unsubscribe
}


extension Subscription {
    
    func createRequest(to mode: SubscriptionMode, leaseSeconds: Int? = nil) -> SubscriptionRequest {
        SubscriptionRequest(
            callback: callback.absoluteString,
            topic: topic.absoluteString,
            mode: mode,
            leaseSeconds: leaseSeconds
        )
    }
    
}


extension SubscriptionRequest {
    
    func urlEncoded() throws -> String {
        var encoded = [
            try urlEncoded(for: .callback, value: callback),
            try urlEncoded(for: .topic, value: topic),
            try urlEncoded(for: .mode, value: mode.rawValue),
        ]
        if let leaseSeconds {
            encoded += [
                try urlEncoded(for: .leaseSeconds, value: "\(leaseSeconds)")
            ]
        }
        return encoded.joined(separator: "&")
    }
    
    fileprivate func urlEncoded(
        for codingKey: CodingKeys,
        value: String
    ) throws -> String {
        return [codingKey.rawValue, try value.urlEncoded(codingPath: [codingKey])]
            .joined(separator: "=")
    }
    
}


// MARK: - Utilities. Credits to Vapor Project

extension String {
    /// Prepares a `String` for inclusion in form-urlencoded data.
    fileprivate func urlEncoded(codingPath: [CodingKey] = []) throws -> String {
        guard let result = self.addingPercentEncoding(
            withAllowedCharacters: Characters.allowedCharacters
        ) else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to add percent encoding to \(self)"
            ))
        }
        return result
    }
}

/// Characters allowed in form-urlencoded data.
private enum Characters {
    static let allowedCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        // these symbols are reserved for url-encoded form
        allowed.remove(charactersIn: "?&=[];+")
        return allowed
    }()
}
