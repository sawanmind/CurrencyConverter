//
//  CurrencyConverter.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import Foundation

actor CurrencyConverter {

    private var currencies: [Currency] = []
    private let baseCurrencyCode: String
    private var selectedCurrencyCode: String = ""

    init(baseCurrencyCode: String) {
        self.baseCurrencyCode = baseCurrencyCode
    }

    func updateSelectedCurrency(_ code: String) {
        selectedCurrencyCode = code
    }
    
    func updateCurrencies(_ currencies: [Currency]) {
        self.currencies = currencies
    }

    func convert(amount: Double) -> [Currency] {

        guard amount > 0 else { return [] }
        
        guard let selectedRate = currencies.first(where: {
            $0.code == selectedCurrencyCode
        })?.value else {
            return []
        }

        return currencies
            .map {
                let value = ($0.value / selectedRate) * amount
                return Currency(
                        code: $0.code,
                        name: $0.name,
                        value: value
                )
            }
            .sorted { $0.code < $1.code }
    }
}
