//
//  CurrencyConverterViewModel.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 06/02/25.
//

import Combine
import Foundation
import SwiftUI
import Network

class CurrencyConverterViewModel: ObservableObject {
    @Published var amount: String = "1" {
        didSet { convertCurrencies() }
    }
    
    @Published var selectedCurrency: String = "USD"
    @Published var convertedCurrencies: [Currency] = []
    @Published var showAlert = false
    @Published var alertMessage = ""

    private let currencyRepository: CurrencyRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    internal var exchangeRates: [Currency] = []
    private let monitor = NWPathMonitor()

    init(currencyRepository: CurrencyRepositoryProtocol) {
        self.currencyRepository = currencyRepository
        setupListeners()
        fetchExchangeRates()
        self.checkInternet() 
    }

    private func setupListeners() {
        EventBus.shared.currencySelected
            .sink { [weak self] currencyCode in
                self?.selectedCurrency = currencyCode
                self?.fetchExchangeRates()
            }
            .store(in: &cancellables)
    }

    func fetchExchangeRates() {
        currencyRepository.getExchangeRates(baseCurrency: selectedCurrency)
            .sink(receiveCompletion: { _ in }, receiveValue: { rates in
                DispatchQueue.main.async {
                    self.exchangeRates = rates
                    self.convertCurrencies()
                }
            })
            .store(in: &cancellables)
    }

    func convertCurrencies() {
        if let baseRate = exchangeRates.first(where: { $0.code == selectedCurrency })?.value {
            performConversion(baseRate: baseRate)
            return
        }

        if let usdRate = exchangeRates.first(where: { $0.code == "USD" })?.value {
            let inferredRate = 1.0 / usdRate
            storeManualRate(for: selectedCurrency, rate: inferredRate)
            performConversion(baseRate: inferredRate)
            return
        }

        convertedCurrencies = []
    }

    private func storeManualRate(for currency: String, rate: Double) {
        if !exchangeRates.contains(where: { $0.code == currency }) {
            exchangeRates.append(Currency(code: currency, name: currency, value: rate))
        }
    }

    private func performConversion(baseRate: Double) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            convertedCurrencies = []
            return
        }

        convertedCurrencies = exchangeRates.map { currency in
            let convertedValue = (currency.value / baseRate) * amountValue
            return Currency(code: currency.code, name: currency.name, value: convertedValue)
        }.sorted { $0.name < $1.name }
    }
    
    func currencyListView() -> some View {
        CurrencyListView(viewModel: CurrencyListViewModel(currencyRepository: self.currencyRepository, baseCurrency: selectedCurrency))
    }

    func checkInternet() {
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status != .satisfied && self.exchangeRates.isEmpty {
                    self.alertMessage = "Internet is needed for the first time to fetch exchange rates."
                    self.showAlert = true
                }
                self.monitor.cancel()
            }
        }
    }

}
