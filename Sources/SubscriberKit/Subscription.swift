//
//  Subscription.swift
//
//
//  Created by Bunga Mungil on 08/02/24.
//

import Foundation


public protocol Subscription {
    
    var callback: URL { get }
    
    var topic: URL { get }
    
    var hubs: [URL] { get }
    
    var isPendingSubscription: Bool { get }
    
    var isPendingUnsubscription: Bool { get }
    
    var isActive: Bool { get }
    
}


public enum SubscriptionMark {
    
    case pendingSubscription(request: SubscriptionRequest)
    
    case pendingUnsubscription(request: SubscriptionRequest)
    
    case subscribed(verify: SubscriptionVerification)
    
    case unsubscribed(verify: SubscriptionVerification)
    
    case denied(denial: SubscriptionDenial)
    
}
