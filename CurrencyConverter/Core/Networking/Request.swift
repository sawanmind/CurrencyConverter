//
//  Request.swift
//  CurrencyConverter
//

import Foundation

struct Request: Sendable {

    private let endpoint: Endpoint
    private let queryItems: [URLQueryItem]
    private let headers: [String: String]

    init(
        endpoint: Endpoint,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) {
        self.endpoint = endpoint
        self.queryItems = queryItems
        self.headers = headers
    }
}

// MARK: - Builder

extension Request {

    func queryItem(
        name: String,
        value: String?
    ) -> Request {

        var items = queryItems
        items.append(URLQueryItem(name: name, value: value))

        return Request(
            endpoint: endpoint,
            queryItems: items,
            headers: headers
        )
    }

    func headers(
        _ headers: [String: String]
    ) -> Request {

        Request(
            endpoint: endpoint,
            queryItems: queryItems,
            headers: self.headers.merging(headers) { _, new in new }
        )
    }
}

// MARK: - Build

extension Request {

    func build(baseURL: URL) throws -> URLRequest {

        let url = try buildURL(baseURL: baseURL)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers
            .merging(headers) { _, new in new }
            .forEach {
                request.setValue($1, forHTTPHeaderField: $0)
            }

        return request
    }

    private func buildURL(baseURL: URL) throws -> URL {

        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        return url
    }
}
