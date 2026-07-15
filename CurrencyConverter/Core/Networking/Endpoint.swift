//
//  Endpoint.swift
//  CurrencyConverter
//

import Foundation

protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
}
