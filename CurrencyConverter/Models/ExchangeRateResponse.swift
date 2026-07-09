//
//  ExchangeRateResponse.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Foundation

struct ExchangeRateResponse: Codable {
    let rates: [String: Double]
}
