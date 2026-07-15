//
//  RateFreshnessStore.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import Foundation

protocol RateFreshnessStore: Sendable {
    func isExpired() -> Bool
    func markFetched(at date: Date)
}

final class UserDefaultsRateFreshnessStore: RateFreshnessStore, @unchecked Sendable {

    private let defaults: UserDefaults
    private let key = "com.currencyconverter.lastFetchedAt"
    private let exchangeRateTTL: TimeInterval
    
    init(defaults: UserDefaults = .standard, exchangeRateTTL: TimeInterval = 30 * 60) {
        self.defaults = defaults
        self.exchangeRateTTL = exchangeRateTTL
    }

    private var lastFetchedAt: Date? {
        defaults.object(forKey: key) as? Date
    }

    func markFetched(at date: Date) {
        defaults.set(date, forKey: key)
    }
    
    func isExpired() -> Bool {
        guard let lastFetchedAt = self.lastFetchedAt else { return true }
        return Date().timeIntervalSince(lastFetchedAt) > self.exchangeRateTTL
    }
}
