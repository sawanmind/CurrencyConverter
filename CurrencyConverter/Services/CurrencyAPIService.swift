//
//  CurrencyAPIService.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Foundation
import Combine

protocol CurrencyAPIServiceProtocol {
    func fetchExchangeRates(baseCurrency: String) -> AnyPublisher<[Currency], Error>
    func fetchCurrencies() -> AnyPublisher<[String: String], Error>
}

class CurrencyAPIService: CurrencyAPIServiceProtocol {
    static let shared = CurrencyAPIService()
    
    private let baseURL = "https://openexchangerates.org/api/" // This will be move to configuration file and other endpoints
    private let appID = "f04dce83be604e8587f878da4babbf48" // This will be store in some secure place. Just for assignment I as hardcoded here
    
    private var cachedRates: [String: [Currency]] = [:]
    private var cachedCurrencyNames: [String: String] = [:]
    private var cacheExpiration: TimeInterval = 1800
    private var lastFetchDate: Date?
    
    func fetchExchangeRates(baseCurrency: String = "USD") -> AnyPublisher<[Currency], Error> {
        if let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheExpiration,
           let cachedRates = cachedRates[baseCurrency] {
            return Just(cachedRates)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: "\(baseURL)latest.json?app_id=\(appID)&base=\(baseCurrency)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return fetchCurrencies()
            .flatMap { currencyNames in
                self.cachedCurrencyNames = currencyNames
                return URLSession.shared.dataTaskPublisher(for: url)
                    .map(\.data)
                    .decode(type: ExchangeRateResponse.self, decoder: JSONDecoder())
                    .map { response in
                        let rates = response.rates.map { key, value in
                            Currency(code: key, name: currencyNames[key] ?? key, value: value)
                        }
                        let sortedRates = rates.sorted { $0.code < $1.code }
                        
                        self.cachedRates[baseCurrency] = sortedRates
                        self.lastFetchDate = Date()
                        return sortedRates
                    }
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func fetchCurrencies() -> AnyPublisher<[String: String], Error> {
        if !cachedCurrencyNames.isEmpty {
            return Just(cachedCurrencyNames)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        guard let url = URL(string: "\(baseURL)currencies.json?app_id=\(appID)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .handleEvents(receiveOutput: { self.cachedCurrencyNames = $0 })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
