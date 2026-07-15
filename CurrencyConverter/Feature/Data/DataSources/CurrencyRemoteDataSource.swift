//
//  CurrencyRemoteDataSource.swift
//  CurrencyConverter
//

import Foundation

protocol CurrencyRemoteDataSource: Sendable {
    func fetchExchangeRates(baseCurrency: String) async throws -> ExchangeRate
    func fetchCurrencies() async throws -> [String: String]
}

enum CurrencyEndpoint: Endpoint {
    case latest
    case currencies

    var path: String {
        switch self {
        case .latest:
            return "latest.json"
        case .currencies:
            return "currencies.json"
        }
    }
    
    var method: HTTPMethod { .get }
    var headers: [String : String] { [:] }
}


final class RESTCurrencyRemoteDataSource: CurrencyRemoteDataSource {

    private let client: HTTPClient
    private let configuration: APIConfiguration

    init(client: HTTPClient,configuration: APIConfiguration) {
        self.client = client
        self.configuration = configuration
    }

    func fetchExchangeRates(baseCurrency: String) async throws -> ExchangeRate {
        let request = try Request(endpoint: CurrencyEndpoint.latest)
            .queryItem(name: "base", value: baseCurrency)
            .queryItem(name: "app_id", value: configuration.appID)
            .build(baseURL: configuration.baseURL)

        return try await client.request(request,responseType: ExchangeRate.self)
    }

    func fetchCurrencies() async throws -> [String: String] {
        let request = try Request(endpoint: CurrencyEndpoint.currencies)
            .queryItem(name: "app_id", value: configuration.appID)
            .build(baseURL: configuration.baseURL)

        return try await client.request(request, responseType: [String: String].self)
    }
}
