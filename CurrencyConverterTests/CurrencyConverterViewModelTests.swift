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
final class CurrencyConverterViewModelTests: XCTestCase {

    private var repository: MockRepository!
    private var networkMonitor: MockNetworkMonitor!
    private var sut: CurrencyConverterViewModel!

    override func setUp() {
        super.setUp()
        repository = MockRepository()
        networkMonitor = MockNetworkMonitor()
        sut = CurrencyConverterViewModel(repository: repository, networkMonitor: networkMonitor)
    }

    override func tearDown() {
        sut = nil
        networkMonitor = nil
        repository = nil
        super.tearDown()
    }

    func testInitSelectedCurrencyCodeEqualsBaseCurrency() {
        XCTAssertEqual(sut.selectedCurrencyCode, repository.baseCurrency)
    }

    func testInitStateIsIdle() {
        XCTAssertEqual(sut.state, .idle)
    }

    func testLoadSetsStateToLoadedOnSuccess() async {
        repository.stubbedResult = .success([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
        ])

        await sut.load()

        if case .loaded = sut.state { } else {
            XCTFail("Expected .loaded state, got \(sut.state)")
        }
    }

    func testLoadSetsStateToErrorOnFailure() async {
        repository.stubbedResult = .failure(APIError.networkUnavailable)

        await sut.load()

        if case .error = sut.state { } else {
            XCTFail("Expected .error state, got \(sut.state)")
        }
    }

    func testSelectedCurrencyCode() async {
        repository.stubbedResult = .success([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
        ])
        await sut.load()

        sut.selected(Currency(code: "EUR", name: "Euro", value: 0.92))

        XCTAssertEqual(sut.selectedCurrencyCode, "EUR")
    }

    func testApplyConversionSetsLoadedStateWithConvertedValues() async {
        repository.stubbedResult = .success([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
        ])
        await sut.load()
        sut.amount = "100"

        await sut.applyConversion()

        if case .loaded(let currencies) = sut.state {
            let usd = currencies.first(where: { $0.code == "USD" })!
            XCTAssertEqual(usd.value, 100.0, accuracy: 0.001)
        } else {
            XCTFail("Expected .loaded state, got \(sut.state)")
        }
    }

    func testApplyConversionReturnsEmptyConvertedListWhenAmountIsInvalid() async {
        repository.stubbedResult = .success([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
        ])
        await sut.load()
        sut.amount = "abc"

        await sut.applyConversion()

        XCTAssertEqual(sut.state, .loaded([]))
    }
}
