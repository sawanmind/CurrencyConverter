import XCTest
@testable import CurrencyConverter

private final class MockRepository: CurrencyRepositoryProtocol, @unchecked Sendable {
    var baseCurrency: String = "USD"
    var stubbedResult: Result<[Currency], Error> = .success([])

    func fetchRates() async throws -> [Currency] {
        try stubbedResult.get()
    }
}

private final class MockNetworkMonitor: NetworkMonitoring {
    var isConnected: AsyncStream<Bool> { AsyncStream { _ in } }
}

@MainActor
private final class MockSelectionDelegate: CurrencySelectionDelegate {
    private(set) var selectedCurrency: Currency?
    func selected(_ currency: Currency) { selectedCurrency = currency }
}

@MainActor
final class CurrencyListViewModelTests: XCTestCase {

    private var repository: MockRepository!
    private var networkMonitor: MockNetworkMonitor!
    private var sut: CurrencyListViewModel!

    override func setUp() {
        super.setUp()
        repository = MockRepository()
        networkMonitor = MockNetworkMonitor()
        sut = CurrencyListViewModel(repository: repository, delegate: nil, networkMonitor: networkMonitor)
    }

    override func tearDown() {
        sut = nil
        networkMonitor = nil
        repository = nil
        super.tearDown()
    }

    func testLoadSetsStateToLoadedOnSuccess() async {
        let currencies = [Currency(code: "USD", name: "US Dollar", value: 1.0)]
        repository.stubbedResult = .success(currencies)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(currencies))
    }

    func testLoadSetsStateToEmptyWhenRepositoryReturnsNoCurrencies() async {
        repository.stubbedResult = .success([])

        await sut.load()

        XCTAssertEqual(sut.state, .empty)
    }

    func testLoadSetsStateToErrorOnFailure() async {
        repository.stubbedResult = .failure(APIError.networkUnavailable)

        await sut.load()

        if case .error = sut.state { } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testSearchTextFiltersResultsByCode() async {
        repository.stubbedResult = .success([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
        ])
        await sut.load()

        sut.searchText = "USD"

        XCTAssertEqual(sut.state, .loaded([Currency(code: "USD", name: "US Dollar", value: 1.0)]))
    }

    func testSearchTextFiltersResultsByName() async {
        repository.stubbedResult = .success([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
        ])
        await sut.load()

        sut.searchText = "Euro"

        XCTAssertEqual(sut.state, .loaded([Currency(code: "EUR", name: "Euro", value: 0.92)]))
    }

    func testSearchTextIsCaseInsensitive() async {
        repository.stubbedResult = .success([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        await sut.load()

        sut.searchText = "usd"

        XCTAssertEqual(sut.state, .loaded([Currency(code: "USD", name: "US Dollar", value: 1.0)]))
    }

    func testSearchTextSetsEmptyStateWhenNoMatchFound() async {
        repository.stubbedResult = .success([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        await sut.load()

        sut.searchText = "XYZ"

        XCTAssertEqual(sut.state, .empty)
    }

    func testSearchTextShowsAllCurrenciesWhenSearchFieldIsEmpty() async {
        let currencies = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
        ]
        repository.stubbedResult = .success(currencies)
        await sut.load()
        sut.searchText = "USD"

        sut.searchText = ""

        XCTAssertEqual(sut.state, .loaded(currencies))
    }

    func testSelectedNotifiesDelegate() async {
        let delegate = MockSelectionDelegate()
        sut = CurrencyListViewModel(repository: repository, delegate: delegate, networkMonitor: networkMonitor)
        let currency = Currency(code: "EUR", name: "Euro", value: 0.92)

        sut.selected(currency)

        XCTAssertEqual(delegate.selectedCurrency, currency)
    }
}
