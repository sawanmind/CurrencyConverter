//
//  EventBus.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 08/02/25.
//

import Combine

class EventBus {
    static let shared = EventBus()
    
    let currencySelected = PassthroughSubject<String, Never>()
    
    private init() {}
}
