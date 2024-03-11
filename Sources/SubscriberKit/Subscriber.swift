//
//  Subscriber.swift
//
//
//  Created by Bunga Mungil on 08/02/24.
//

import Foundation


public protocol Subscriber { }


// MARK: - Subscriber + subscribe

extension Subscriber {
    
    public func subscribe(
        topic: URL,
        to callback: URL,
        leaseSeconds: Int?,
        preferredHub: URL?,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    ) async throws {
        if let hub = preferredHub {
            try await request(
                try await storeSubscription(
                    callback: callback,
                    topic: topic,
                    hubs: [hub],
                    leaseSeconds: leaseSeconds,
                    on: repository
                ),
                leaseSeconds: leaseSeconds,
                on: repository,
                delegate: delegate
            )
            return
        }
        let discovered = try await discover(topic,
            delegate: delegate
        )
        try await request(
            try await storeSubscription(
                callback: callback,
                topic: discovered.topic,
                hubs: discovered.hubs,
                leaseSeconds: leaseSeconds,
                on: repository
            ),
            leaseSeconds: leaseSeconds,
            on: repository,
            delegate: delegate
        )
    }
    
    private func discover(
        _ topic: URL,
        delegate: SubscriberDelegate
    ) async throws -> (topic: URL, hubs: [URL]) {
        try await performDiscoveryMechanism(for: topic)
    }
    
    private func storeSubscription(
        callback: URL,
        topic: URL,
        hubs: [URL],
        leaseSeconds: Int?,
        on repository: SubscriptionRepository
    ) async throws -> Subscription {
        try await repository.store(
            callback: callback,
            topic: topic,
            hubs: hubs,
            leaseSeconds: leaseSeconds
        )
    }
    
    private func request(
        _ subscription: Subscription,
        leaseSeconds: Int?,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    ) async throws {
        let request = subscription.createRequest(
            to: .subscribe,
            leaseSeconds: leaseSeconds
        )
        try await repository.mark(subscription,
            as: .pendingSubscription(request: request)
        )
        try await callHTTPRequest(
            to: subscription.hubs,
            request: request
        )
    }
    
}


// MARK: - Subscriber + unsubscribe

extension Subscriber {
    
    public func unsubscribe(
        _ callback: URL,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    )
    async throws {
        let subscription = try await repository.subscription(for: callback)
        let request = subscription.createRequest(to: .unsubscribe)
        try await repository.mark(subscription,
            as: .pendingUnsubscription(request: request)
        )
        try await callHTTPRequest(
            to: subscription.hubs,
            request: request
        )
    }
    
}


// MARK: - Subscriber + verify

extension Subscriber {
    
    public func verify(
        _ validation: SubscriptionValidation,
        from callback: URL,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    ) async throws {
        switch validation {
        case .verifying(let verification):
            try await self.verifying(verification,
                from: callback,
                on: repository,
                delegate: delegate
            )
        case .denied(let denial):
            try await self.denied(denial,
                from: callback,
                on: repository,
                delegate: delegate
            )
        }
    }
    
    func verifying(
        _ verification: SubscriptionVerification,
        from callback: URL,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    ) async throws {
        let subscription = try await repository.subscription(for: callback)
        switch verification.mode {
        case .subscribe:
            guard subscription.isPendingSubscription,
                verification.topic == subscription.topic.absoluteString
            else {
                throw SubscriberError.verificationNotRequested(verification)
            }
            try await repository.mark(subscription,
                as: .subscribed(verify: verification)
            )
            try await delegate.subscription(repository.subscription(for: callback),
                verified: verification
            )
        case .unsubscribe:
            guard subscription.isPendingUnsubscription,
                verification.topic == subscription.topic.absoluteString
            else {
                throw SubscriberError.verificationNotRequested(verification)
            }
            try await repository.mark(subscription,
                as: .unsubscribed(verify: verification)
            )
            try await delegate.subscription(repository.subscription(for: callback),
                verified: verification
            )
        }
    }
    
    func denied(
        _ denial: SubscriptionDenial,
        from callback: URL,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    ) async throws {
        try await repository.mark(
            repository.subscription(for: callback),
            as: .denied(denial: denial)
        )
        try await delegate.subscription(
            repository.subscription(for: callback),
            denied: denial
        )
    }
    
}


// MARK: - Subscriber + receive

extension Subscriber {
    
    public func receive(
        _ content: Data,
        from callback: URL,
        on repository: SubscriptionRepository,
        delegate: SubscriberDelegate
    ) async throws {
        let subscription = try await repository.subscription(for: callback)
        guard subscription.isActive else {
            throw SubscriberError.receivingPayloadForInvalid(subscription)
        }
        try await delegate.subscription(subscription,
            received: content
        )
    }
    
}


// MARK: - Subscriber + callHTTPRequest

extension Subscriber {
    
    fileprivate func callHTTPRequest(to hubs: [URL], request: SubscriptionRequest) async throws {
        await withThrowingTaskGroup(of: (Data, URLResponse).self) { group in
            for hub in hubs {
                group.addTask {
                    try await URLSession.shared.data(
                        for: createURLRequest(hub, request: request)
                    )
                }
            }
        }
    }
    
    fileprivate func createURLRequest(_ url: URL, request: SubscriptionRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try request.urlEncoded().data(using: .utf8)
        return urlRequest
    }
    
    fileprivate func callHTTPRequest(to topic: URL) async throws -> (Data, HTTPURLResponse) {
        let request = URLRequest(url: topic)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse {
            return (data, response)
        }
        throw SubscriberError.failedToPerformDiscoveryMechanism(data, response)
    }
    
    fileprivate func performDiscoveryMechanism(for topic: URL) async throws -> (topic: URL, hubs: [URL]) {
        let (data, response) = try await callHTTPRequest(to: topic)
        if let onHeader = try? response.performDiscoveryMechanism() {
            return onHeader
        }
        if let onBody = try? data.performDiscoveryMechanism() {
            return onBody
        }
        throw SubscriberError.failedToPerformDiscoveryMechanism(data, response)
    }
    
}
