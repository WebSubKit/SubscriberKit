//
//  SubscriberDelegate.swift
//
//
//  Created by Bunga Mungil on 08/02/24.
//

import Foundation


public protocol SubscriberDelegate {
    
    func subscription(_ subscription: Subscription, received content: Data) async throws
    
    func subscription(_ subscription: Subscription, verified: SubscriptionVerification) async throws
    
    func subscription(_ subscription: Subscription, denied: SubscriptionDenial) async throws

}
