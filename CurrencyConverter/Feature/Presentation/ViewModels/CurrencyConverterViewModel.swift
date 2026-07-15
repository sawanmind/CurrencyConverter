import Foundation
import Observation
import Combine

@MainActor
final class CurrencyConverterViewModel: ObservableObject {
    
    @Published var amount: String = "1"
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var selectedCurrencyCode: String
    private var converter: CurrencyConverter
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor: NetworkMonitoring
    private let repository: CurrencyRepositoryProtocol
    
    /*
     I have already injected NetworkMonitoring into the ViewModel as the starting point. The next step would be to move the retry behavior into the networking layer so failed requests can resume automatically when the network is available again. I didn’t implement that because it requires a dedicated retry/orchestration mechanism, which I felt was outside the scope of this assignment.
     */
    init(repository: CurrencyRepositoryProtocol, networkMonitor: NetworkMonitoring) {
        self.repository = repository
        self.selectedCurrencyCode = repository.baseCurrency
        self.converter = CurrencyConverter(baseCurrencyCode: repository.baseCurrency)
        self.networkMonitor = networkMonitor
        self.bindAmountTextField()
        self.startMonitoring()
    }
    
    private func bindAmountTextField() {
        $amount
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                guard case .loaded = self.state else { return }
                
                Task {
                    await self.applyConversion()
                }
            }
            .store(in: &cancellables)
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
    
    @MainActor
    func load() async {
        state = .isLoading
        do {
            let currencies = try await repository.fetchRates()
            await self.converter.updateSelectedCurrency(self.selectedCurrencyCode)
            await self.converter.updateCurrencies(currencies)
            await applyConversion()

        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func applyConversion() async {
        let value = Double(amount) ?? 0
        let currencies = await converter.convert(amount: value)
        state = .loaded(currencies)
    }
    
    func makeCurrencyListViewModel() -> CurrencyListViewModel {
        CurrencyListViewModel(repository: repository, delegate: self, networkMonitor: self.networkMonitor)
    }
}

extension CurrencyConverterViewModel: CurrencySelectionDelegate {

    func selected(_ currency: Currency) {
        self.selectedCurrencyCode = currency.code
        Task {
            await converter.updateSelectedCurrency(currency.code)
            await applyConversion()
        }
    }
}
