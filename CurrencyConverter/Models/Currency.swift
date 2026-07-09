//
//  Currency.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Foundation

struct Currency: Equatable {
    let id = UUID()
    let code: String
    let name: String
    let value: Double
    
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.id == rhs.id
    }
}
