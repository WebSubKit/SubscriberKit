//
//  SubscriberError.swift
//
//
//  Created by Bunga Mungil on 21/02/24.
//

import Foundation


public enum SubscriberError: Error {
    
    case failedToCreateURLFrom(String)
    
    case receivingPayloadForInvalid(Subscription)
    
    case verificationNotRequested(SubscriptionVerification)
    
    case validationFailedToIdentifiedBy(Decoder)
    
    case subscriptionNotFoundForCallback(URL)
    
    case failedToPerformDiscoveryMechanism(Data, URLResponse)
    
}
