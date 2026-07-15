//
//  ViewState.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 10/07/26.
//

import Foundation

enum ViewState: Equatable {
    case idle
    case isLoading
    case loaded([Currency])
    case empty
    case error(String)
}
