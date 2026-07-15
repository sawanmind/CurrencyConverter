import XCTest
@testable import CurrencyConverter

private final class MockCurrencyRemoteDataSource: CurrencyRemoteDataSource, @unchecked Sendable {

    var exchangeRatesResult: Result<ExchangeRate, Error> = .success(ExchangeRate(rates: [:]))
    var currenciesResult: Result<[String: String], Error> = .success([:])
    private(set) var fetchExchangeRatesCallCount = 0

    func fetchExchangeRates(baseCurrency: String) async throws -> ExchangeRate {
        fetchExchangeRatesCallCount += 1
        return try exchangeRatesResult.get()
    }

    func fetchCurrencies() async throws -> [String: String] {
        return try currenciesResult.get()
    }
}

private final class MockCurrencyLocalDataSource: CurrencyLocalDataSource, @unchecked Sendable {

    var fetchResult: [Currency] = []
    private(set) var savedCurrencies: [Currency] = []

    func fetch() async throws -> [Currency] {
        return fetchResult
    }

    func save(_ currencies: [Currency]) async throws {
        savedCurrencies = currencies
    }
}

private final class MockRateFreshnessStore: RateFreshnessStore, @unchecked Sendable {

    var stubbedIsExpired = true
    private(set) var markFetchedCallCount = 0

    func isExpired() -> Bool {
        stubbedIsExpired
    }

    func markFetched(at date: Date) {
        markFetchedCallCount += 1
    }
}

final class CurrencyRepositoryTests: XCTestCase {

    private var remote: MockCurrencyRemoteDataSource!
    private var local: MockCurrencyLocalDataSource!
    private var freshnessStore: MockRateFreshnessStore!
    private var sut: CurrencyRepository!

    override func setUp() {
        super.setUp()
        remote = MockCurrencyRemoteDataSource()
        local = MockCurrencyLocalDataSource()
        freshnessStore = MockRateFreshnessStore()
        sut = CurrencyRepository(remote: remote, local: local, freshnessStore: freshnessStore)
    }

    override func tearDown() {
        sut = nil
        freshnessStore = nil
        local = nil
        remote = nil
        super.tearDown()
    }

    func testFetchRatesAndReturnCachedDataWhenCacheIsNotExpired() async throws {
        let cached = [Currency(code: "USD", name: "US Dollar", value: 1.0)]
        local.fetchResult = cached
        freshnessStore.stubbedIsExpired = false

        let result = try await sut.fetchRates()

        XCTAssertEqual(result, cached)
        XCTAssertEqual(remote.fetchExchangeRatesCallCount, 0)
    }

    func testFetchRatesAndFetchFreshDataWhenCacheIsEmpty() async throws {
        local.fetchResult = []
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .success(ExchangeRate(rates: ["USD": 1.0]))
        remote.currenciesResult = .success(["USD": "US Dollar"])

        _ = try await sut.fetchRates()

        XCTAssertEqual(remote.fetchExchangeRatesCallCount, 1)
    }

    func testFetchRatesAndFetchFreshDataWhenCacheIsExpired() async throws {
        local.fetchResult = [Currency(code: "USD", name: "US Dollar", value: 1.0)]
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .success(ExchangeRate(rates: ["EUR": 0.92]))
        remote.currenciesResult = .success(["EUR": "Euro"])

        _ = try await sut.fetchRates()

        XCTAssertEqual(remote.fetchExchangeRatesCallCount, 1)
    }

    func testFetchRatesAndSaveFreshDataToLocalAfterRemoteFetch() async throws {
        local.fetchResult = []
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .success(ExchangeRate(rates: ["USD": 1.0]))
        remote.currenciesResult = .success(["USD": "US Dollar"])

        _ = try await sut.fetchRates()

        XCTAssertFalse(local.savedCurrencies.isEmpty)
        XCTAssertEqual(local.savedCurrencies.first?.code, "USD")
    }

    func testFetchRatesAndMarksFetchedAfterRemoteFetch() async throws {
        local.fetchResult = []
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .success(ExchangeRate(rates: ["USD": 1.0]))
        remote.currenciesResult = .success(["USD": "US Dollar"])

        _ = try await sut.fetchRates()

        XCTAssertEqual(freshnessStore.markFetchedCallCount, 1)
    }

    func testFetchRatesAndReturnMappedCurrenciesAfterRemoteFetch() async throws {
        local.fetchResult = []
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .success(ExchangeRate(rates: ["USD": 1.0, "EUR": 0.92]))
        remote.currenciesResult = .success(["USD": "US Dollar", "EUR": "Euro"])

        let result = try await sut.fetchRates()

        // Currency is sorted by code in implementation itself
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.code, "EUR")
        XCTAssertEqual(result.first?.name, "Euro")
        XCTAssertEqual(result.last?.code, "USD")
        XCTAssertEqual(result.last?.name, "US Dollar")
    }

    func testFetchRatesAndReturnOldCachedDataOnRemoteFailureWhenCacheAvailable() async throws {
        let old = [Currency(code: "USD", name: "US Dollar", value: 1.0)]
        local.fetchResult = old
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .failure(APIError.networkUnavailable)

        let result = try await sut.fetchRates()

        XCTAssertEqual(result, old)
    }

    func testFetchRatesAndThrowsErrorWhenRemoteFailsAndCacheIsEmpty() async {
        local.fetchResult = []
        freshnessStore.stubbedIsExpired = true
        remote.exchangeRatesResult = .failure(APIError.networkUnavailable)

        do {
            _ = try await sut.fetchRates()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
