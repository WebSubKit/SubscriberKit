//
//  SubscriptionValidation.swift
//
//
//  Created by Bunga Mungil on 09/02/24.
//


public enum SubscriptionValidation {
    
    case denied(denied: SubscriptionDenial)

    case verifying(verifying: SubscriptionVerification)
    
}


extension SubscriptionValidation: Codable {
    
    public init(from decoder: Decoder) throws {
        if let verifying = try? decoder.singleValueContainer().decode(SubscriptionVerification.self) {
            self = .verifying(verifying: verifying)
            return
        }
        if let denied = try? decoder.singleValueContainer().decode(SubscriptionDenial.self) {
            self = .denied(denied: denied)
            return
        }
        throw SubscriberError.validationFailedToIdentifiedBy(decoder)
    }
    
}


public struct SubscriptionDenial: Codable {
    
    public let mode: SubscriptionDenialMode

    public let topic: String

    public let reason: String?

    enum CodingKeys: String, CodingKey {
        case mode = "hub.mode"
        case topic = "hub.topic"
        case reason = "hub.reason"
    }
    
}


public enum SubscriptionDenialMode: String, Codable {
    case denied
}


public struct SubscriptionVerification: Codable {
    
    public let mode: SubscriptionVerificationMode

    public let topic: String

    public let challenge: String

    public let leaseSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case mode = "hub.mode"
        case topic = "hub.topic"
        case challenge = "hub.challenge"
        case leaseSeconds = "hub.lease_seconds"
    }
    
}


public enum SubscriptionVerificationMode: String, Codable {
    case subscribe
    case unsubscribe
}
