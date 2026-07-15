//
//  Currency.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Foundation

struct Currency: Sendable, Identifiable, Equatable {
    var id: String { code }
    let code: String
    let name: String
    let value: Double
}
