//
//  HTTPClient.swift
//  CurrencyConverter
//

import Foundation

protocol HTTPClient: Sendable {
    func request<Response: Decodable>(_ request: URLRequest, responseType: Response.Type)
    async throws -> Response
}

final class URLSessionHTTPClient: HTTPClient {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    func request<Response: Decodable>(
        _ request: URLRequest,
        responseType: Response.Type
    ) async throws -> Response {

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidStatusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError(error)
        }
    }
}
