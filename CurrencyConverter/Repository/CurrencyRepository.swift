//
//  CurrencyRepository.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Combine
import Foundation

protocol UserDefaultsProtocol {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: UserDefaultsProtocol {}

protocol CurrencyRepositoryProtocol {
    func getExchangeRates(baseCurrency: String) -> AnyPublisher<[Currency], Error>
    func fetchCurrencies() -> AnyPublisher<[Currency], Error>
}

class CurrencyRepository: CurrencyRepositoryProtocol {
    private let apiService: CurrencyAPIServiceProtocol
    private let storageService: CoreDataServiceProtocol
    private let cacheExpiration: TimeInterval
    private let userDefaults: UserDefaultsProtocol

    init(
        apiService: CurrencyAPIServiceProtocol,
        storageService: CoreDataServiceProtocol,
        cacheExpiration: TimeInterval = 1800, // 30 minutes
        userDefaults: UserDefaultsProtocol = UserDefaults.standard
    ) {
        self.apiService = apiService
        self.storageService = storageService
        self.cacheExpiration = cacheExpiration
        self.userDefaults = userDefaults
    }

    func getExchangeRates(baseCurrency: String) -> AnyPublisher<[Currency], Error> {
        if let cachedRates = getCachedRates(), !cachedRates.isEmpty {
            return fetchCurrencies()
                .map { currencies in
                    self.mergeExchangeRatesWithCurrencies(rates: cachedRates, currencies: currencies)
                }
                .catch { _ in Just(cachedRates).setFailureType(to: Error.self) } // If currencies fail, return only cached rates
                .eraseToAnyPublisher()
        }

        return fetchAndStoreExchangeRates(baseCurrency: baseCurrency)
    }
    
    func fetchCurrencies() -> AnyPublisher<[Currency], Error> {
        if let cachedCurrencies = getCachedCurrencies(), !cachedCurrencies.isEmpty {
            return Just(cachedCurrencies)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return fetchAndStoreCurrencies()
    }
    
    private func getCachedCurrencies() -> [Currency]? {
        let lastFetchDate = userDefaults.object(forKey: "lastCurrencyFetchDate") as? Date ?? Date.distantPast
        let isCacheValid = Date().timeIntervalSince(lastFetchDate) < cacheExpiration
        let cachedCurrencies = try? storageService.fetchStoredRates().get()

        return isCacheValid ? cachedCurrencies : nil
    }

    private func getCachedRates() -> [Currency]? {
        let lastFetchDate = userDefaults.object(forKey: "lastExchangeFetchDate") as? Date ?? Date.distantPast
        let isCacheValid = Date().timeIntervalSince(lastFetchDate) < cacheExpiration
        let cachedRates = try? storageService.fetchStoredRates().get()

        return isCacheValid ? cachedRates : nil
    }

    private func fetchAndStoreExchangeRates(baseCurrency: String) -> AnyPublisher<[Currency], Error> {
        return apiService.fetchExchangeRates(baseCurrency: baseCurrency)
            .handleEvents(receiveOutput: { [weak self] rates in
                _ = self?.storageService.storeExchangeRates(rates)
                self?.userDefaults.set(Date(), forKey: "lastExchangeFetchDate")
            })
            .flatMap { rates in
                self.fetchCurrencies()
                    .map { currencies in
                        self.mergeExchangeRatesWithCurrencies(rates: rates, currencies: currencies)
                    }
                    .catch { _ in Just(rates).setFailureType(to: Error.self) }
            }
            .eraseToAnyPublisher()
    }

    private func fetchAndStoreCurrencies() -> AnyPublisher<[Currency], Error> {
        return apiService.fetchCurrencies()
            .map { dictionary -> [Currency] in
                dictionary.map { Currency(code: $0.key, name: $0.value, value: 0.0) }
            }
            .handleEvents(receiveOutput: { [weak self] currencies in
                var existingRates = self?.getCachedRates() ?? []
                let mergedData = self?.mergeExchangeRatesWithCurrencies(rates: existingRates, currencies: currencies) ?? existingRates
                
                _ = self?.storageService.storeExchangeRates(mergedData)
                self?.userDefaults.set(Date(), forKey: "lastCurrencyFetchDate")
            })
            .eraseToAnyPublisher()
    }

    private func mergeExchangeRatesWithCurrencies(rates: [Currency], currencies: [Currency]) -> [Currency] {
        var currencyMap = Dictionary(uniqueKeysWithValues: currencies.map { ($0.code, $0.name) })

        return rates.map { rate in
            Currency(
                code: rate.code,
                name: currencyMap[rate.code] ?? rate.code, // Preserve original exchange rate but add name if available
                value: rate.value
            )
        }
    }
}
