//
//  CurrencyEntity.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import SwiftData

@Model
final class CurrencyEntity {
    @Attribute(.unique) var code: String
    var name: String
    var value: Double
    
    init(code: String, name: String, value: Double) {
        self.code = code
        self.name = name
        self.value = value
    }
}

extension CurrencyEntity {
    func toDomain() -> Currency {
        Currency(code: code, name: name, value: value)
    }
}
