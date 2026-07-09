//
//  CurrencyRepositoryTests.swift
//  CurrencyConverterTests
//
//  Created by Sawan Kumar on 06/02/25.
//

import XCTest
import Combine
@testable import CurrencyConverter

class CurrencyRepositoryTests: XCTestCase {
    var mockRepository: MockCurrencyRepository!
    var mockAPIService: MockCurrencyAPIService!
    var mockStorageService: MockCoreDataService!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockAPIService = MockCurrencyAPIService()
        mockStorageService = MockCoreDataService()
        mockRepository = MockCurrencyRepository(apiService: mockAPIService, storageService: mockStorageService)
        UserDefaults.standard.removeObject(forKey: "lastFetchDate")
    }

    override func tearDown() {
        mockRepository = nil
        mockAPIService = nil
        mockStorageService = nil
        cancellables.removeAll()
        UserDefaults.standard.removeObject(forKey: "lastFetchDate")
        super.tearDown()
    }

    // Ensures cached exchange rates are returned if available.
    func testReturnsCachedExchangeRates() {
        mockStorageService.storeExchangeRates([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27)
        ])

        UserDefaults.standard.set(Date(), forKey: "lastFetchDate")

        let expectation = expectation(description: "Should return cached exchange rates")

        mockRepository.getExchangeRates(baseCurrency: "USD")
            .sink(receiveCompletion: { _ in }, receiveValue: { rates in
                XCTAssertEqual(rates.count, 2, "Cached rates count mismatch")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Ensures exchange rates are fetched from API if cache is empty.
    func testFetchesExchangeRatesFromAPIIfCacheIsEmpty() {
        mockStorageService.storeExchangeRates([])
        let expectation = expectation(description: "Should fetch from API")

        mockRepository.getExchangeRates(baseCurrency: "USD")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertTrue(self.mockAPIService.fetchCalled, "API should be called when cache is empty")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Ensures exchange rates are fetched from API if cache is expired.
    func testFetchesExchangeRatesFromAPIIfCacheExpired() {
        mockStorageService.storeExchangeRates([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27)
        ])

        let expiredDate = Date().addingTimeInterval(-4000)
        UserDefaults.standard.set(expiredDate, forKey: "lastFetchDate")
        
        let expectation = expectation(description: "Should fetch new data from API")

        mockRepository.getExchangeRates(baseCurrency: "USD")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertTrue(self.mockAPIService.fetchCalled, "Should fetch from API if cache is expired")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Ensures fetched data is stored in cache after an API call.
    func testFetchedDataIsStoredInCache() {
        mockStorageService.storeExchangeRates([])

        let expectedRates = [
            Currency(code: "EUR", name: "Euro", value: 0.92),
            Currency(code: "JPY", name: "Japanese Yen", value: 120.5)
        ]
        
        mockAPIService.exchangeRates = expectedRates

        let expectation = expectation(description: "Should store fetched data in cache")

        mockRepository.getExchangeRates(baseCurrency: "USD")
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                XCTAssertTrue(self.mockStorageService.storeCalled, "Data should be stored in cache")
                XCTAssertEqual(self.mockStorageService.storedRates, expectedRates, "Stored exchange rates mismatch")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Ensures API failure returns an error and doesn't provide data.
    func testAPIFailureReturnsError() {
        mockStorageService.storeExchangeRates([])
        mockAPIService.shouldFail = true

        let expectation = expectation(description: "Should return an error if API fails")

        mockRepository.getExchangeRates(baseCurrency: "USD")
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    expectation.fulfill()
                default:
                    XCTFail("Should return failure but completed successfully")
                }
            }, receiveValue: { _ in
                XCTFail("Should not return data if API fails")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Ensures currencies are fetched correctly.
    func testFetchCurrencies() {
        let expectation = XCTestExpectation(description: "Should fetch mock currencies")

        mockRepository.currencies = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        mockRepository.fetchCurrencies()
            .sink(receiveCompletion: { _ in }, receiveValue: { currencies in
                XCTAssertEqual(currencies.count, 2, "Should return 2 currencies")
                XCTAssertTrue(self.mockRepository.fetchCurrenciesCalled, "fetchCurrencies() should be called")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2)
    }
}


class MockCurrencyRepository: CurrencyRepositoryProtocol {
    var exchangeRates: [Currency] = []
    var currencies: [Currency] = []
    var fetchCalled = false
    var fetchCurrenciesCalled = false
    var shouldFail = false

    private let apiService: MockCurrencyAPIService
    private let storageService: MockCoreDataService

    init(apiService: MockCurrencyAPIService, storageService: MockCoreDataService) {
        self.apiService = apiService
        self.storageService = storageService
    }


    func getExchangeRates(baseCurrency: String) -> AnyPublisher<[Currency], Error> {
        fetchCalled = true
        
        if shouldFail {
            return Fail(error: NSError(domain: "MockCurrencyRepositoryError", code: -1, userInfo: nil))
                .eraseToAnyPublisher()
        }
        
        let lastFetchDate = UserDefaults.standard.object(forKey: "lastFetchDate") as? Date ?? Date.distantPast
        let currentTime = Date()
        let timeSinceLastFetch = currentTime.timeIntervalSince(lastFetchDate)
        let isCacheValid = timeSinceLastFetch < 1800
        
        if let cachedRates = try? storageService.fetchStoredRates().get(), isCacheValid, !cachedRates.isEmpty {
            return Just(cachedRates)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return apiService.fetchExchangeRates(baseCurrency: baseCurrency)
            .handleEvents(receiveOutput: { [weak self] rates in
                _ = self?.storageService.storeExchangeRates(rates)
            })
            .eraseToAnyPublisher()
    }
    

    func fetchCurrencies() -> AnyPublisher<[Currency], Error> {
        fetchCurrenciesCalled = true

        if shouldFail {
            return Fail(error: NSError(domain: "MockCurrencyRepositoryError", code: -1, userInfo: nil))
                .eraseToAnyPublisher()
        }

        if !currencies.isEmpty {
            return Just(currencies)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return apiService.fetchCurrencies()
            .map { dictionary in
                dictionary.map { Currency(code: $0.key, name: $0.value, value: 0.0) }
            }
            .handleEvents(receiveOutput: { [weak self] fetchedCurrencies in
                self?.currencies = fetchedCurrencies
            })
            .eraseToAnyPublisher()
    }
    
    func reset() {
        exchangeRates = []
        currencies = []
        fetchCalled = false
        fetchCurrenciesCalled = false
        shouldFail = false
    }
}
