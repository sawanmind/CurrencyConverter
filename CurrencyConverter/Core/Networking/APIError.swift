//
//  APIError.swift
//  CurrencyConverter
//

import Foundation

enum APIError: LocalizedError {

    case invalidURL
    case invalidResponse
    case invalidStatusCode(Int)
    case decodingFailed
    case networkUnavailable
    case requestFailed(Error)
}

extension APIError {

    init(_ error: Error) {

        if let apiError = error as? APIError {
            self = apiError
            return
        }

        if let urlError = error as? URLError {

            switch urlError.code {

            case .notConnectedToInternet,
                 .networkConnectionLost:
                self = .networkUnavailable

            default:
                self = .requestFailed(urlError)
            }

            return
        }

        if error is DecodingError {
            self = .decodingFailed
            return
        }

        self = .requestFailed(error)
    }
}

extension APIError {

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "The request URL is invalid."

        case .invalidResponse:
            return "The server returned an invalid response."

        case .invalidStatusCode(let statusCode):
            return "Unexpected HTTP status code: \(statusCode)."

        case .decodingFailed:
            return "Failed to decode the server response."

        case .networkUnavailable:
            return "No internet connection."

        case .requestFailed(let error):
            return error.localizedDescription
        }
    }
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.decodingFailed, .decodingFailed),
             (.networkUnavailable, .networkUnavailable):
            return true
        case (.invalidStatusCode(let l), .invalidStatusCode(let r)):
            return l == r
        case (.requestFailed(let l), .requestFailed(let r)):
            return (l as NSError) == (r as NSError)
        default:
            return false
        }
    }
}
