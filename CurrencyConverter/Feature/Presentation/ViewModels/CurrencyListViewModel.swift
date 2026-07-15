//
//  CurrencyListViewModel.swift
//  CurrencyConverter
//
import Foundation
import Observation

@MainActor
protocol CurrencySelectionDelegate: AnyObject, Sendable {
    func selected(_ currency: Currency)
}


@MainActor
@Observable
final class CurrencyListViewModel {

    var searchText = "" {
        didSet {
            applyFilter()
        }
    }

    private(set) var state: ViewState = .idle
    private var allCurrencies: [Currency] = []
    private let repository: CurrencyRepositoryProtocol
    private weak var delegate: CurrencySelectionDelegate?
    private let networkMonitor: NetworkMonitoring
    
    init(repository: CurrencyRepositoryProtocol,
         delegate: CurrencySelectionDelegate?,
         networkMonitor: NetworkMonitoring) {
        self.repository = repository
        self.delegate = delegate
        self.networkMonitor = networkMonitor
        self.startMonitoring()
    }
    
    private func startMonitoring() {
        Task {
            for await connected in networkMonitor.isConnected {
                guard connected else { continue }
                if case .error = state {
                    await load()
                }
            }
        }
    }

    func load() async {
        state = .isLoading
        
        do {
            allCurrencies = try await repository.fetchRates()
            applyFilter()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func selected(_ currency: Currency) {
        delegate?.selected(currency)
    }

    private func applyFilter() {
        guard !allCurrencies.isEmpty else {
            state = .empty
            return
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            state = .loaded(allCurrencies)
            return
        }

        let filtered = allCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(query)
                || $0.name.localizedCaseInsensitiveContains(query)
        }
        state = filtered.isEmpty ? .empty : .loaded(filtered)
    }

}
