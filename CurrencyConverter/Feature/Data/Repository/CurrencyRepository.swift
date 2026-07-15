//
//  CurrencyRepository.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import Foundation

final class CurrencyRepository: CurrencyRepositoryProtocol {

    var baseCurrency: String { "USD" }
    private let remote: CurrencyRemoteDataSource
    private let local: CurrencyLocalDataSource
    private let freshnessStore: RateFreshnessStore

    init(
        remote: CurrencyRemoteDataSource,
        local: CurrencyLocalDataSource,
        freshnessStore: RateFreshnessStore
    ) {
        self.remote = remote
        self.local = local
        self.freshnessStore = freshnessStore
    }

    func fetchRates() async throws -> [Currency] {
        let cached = try await local.fetch()

        if !cached.isEmpty, !freshnessStore.isExpired() {
            return cached
        }

        do {
            let fresh = try await fetchRemoteCurrencies()
            try await local.save(fresh)
            freshnessStore.markFetched(at: Date())
            return fresh
        } catch {
            if !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    private func fetchRemoteCurrencies() async throws -> [Currency] {
        async let _exchangeRates = remote.fetchExchangeRates(baseCurrency: self.baseCurrency)
        async let _currencies = remote.fetchCurrencies()

        let (exchangeRates, currencies) = try await (_exchangeRates, _currencies)
        
        return exchangeRates.rates
            .map {
                Currency(
                    code: $0.key,
                    name: currencies[$0.key] ?? $0.key,
                    value: $0.value
                )
            }
            .sorted { $0.code < $1.code }
    }
    
}
