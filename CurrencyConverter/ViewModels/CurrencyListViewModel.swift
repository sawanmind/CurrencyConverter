//
//  CurrencyListViewModel.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Combine
import SwiftUI

class CurrencyListViewModel: ObservableObject {
    @Published var currencies: [Currency] = [] {
        didSet { applyFilter() }
    }
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }
    @Published var filteredCurrencies: [Currency] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let currencyRepository: CurrencyRepositoryProtocol
    private let baseCurrency: String
    
    init(currencyRepository: CurrencyRepositoryProtocol, baseCurrency: String) {
        self.currencyRepository = currencyRepository
        self.baseCurrency = baseCurrency
        fetchCurrencies()
    }
    
    func fetchCurrencies() {
        currencyRepository.fetchCurrencies()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] currencies in
                self?.currencies = currencies
            })
            .store(in: &cancellables)
    }

    private func applyFilter() {
        filteredCurrencies = searchText.isEmpty
            ? currencies
            : currencies.filter {
                $0.code.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
    }

    func selectCurrency(_ currency: Currency) {
        EventBus.shared.currencySelected.send(currency.code)
    }
}
