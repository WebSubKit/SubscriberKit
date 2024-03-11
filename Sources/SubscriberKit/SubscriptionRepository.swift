//
//  SubscriptionRepository.swift
//
//
//  Created by Bunga Mungil on 08/02/24.
//

import Foundation


public protocol SubscriptionRepository {
    
    func store(callback: URL, topic: URL, hubs: [URL], leaseSeconds: Int?) async throws -> Subscription
    
    func mark(_ subscription: Subscription, as mark: SubscriptionMark) async throws
    
    func subscription(for callback: URL) async throws -> Subscription
    
    func subscriptions(for topic: URL) async throws -> [Subscription]
    
}
