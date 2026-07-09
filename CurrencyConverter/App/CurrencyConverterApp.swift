//
//  CurrencyConverterApp.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import SwiftUI
import Combine

@main
struct CurrencyConverterApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                let currencyRepository = CurrencyRepository(apiService: CurrencyAPIService(), storageService: CoreDataService())
                let viewModel = CurrencyConverterViewModel(currencyRepository: currencyRepository)
                CurrencyConverterView(viewModel: viewModel)
            }
        }
    }
}
