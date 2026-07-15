//
//  CurrencyRepositoryProtocol.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import Foundation

protocol CurrencyRepositoryProtocol: Sendable {
    var baseCurrency: String { get }
    func fetchRates() async throws -> [Currency]
}
