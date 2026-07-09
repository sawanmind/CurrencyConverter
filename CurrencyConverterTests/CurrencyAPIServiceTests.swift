//
//  CurrencyAPIServiceTests.swift
//  CurrencyConverterTests
//
//  Created by Sawan Kumar on 06/02/25.
//

import XCTest
import Combine
@testable import CurrencyConverter

class CurrencyAPIServiceTests: XCTestCase {
    var apiService: MockCurrencyAPIService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        apiService = MockCurrencyAPIService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        apiService.reset()
        apiService = nil
        cancellables = nil
        super.tearDown()
    }

    // Tests if fetching exchange rates returns the expected data successfully.
    func testFetchExchangeRates_Success() {
        let expectation = expectation(description: "Exchange rates should be fetched successfully")
        
        apiService.exchangeRates = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        apiService.fetchExchangeRates(baseCurrency: "USD")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { rates in
                XCTAssertEqual(rates.count, 2, "Unexpected number of exchange rates")
                XCTAssertTrue(rates.contains { $0.code == "USD" }, "USD should be in the response")
                XCTAssertTrue(rates.contains { $0.code == "EUR" }, "EUR should be in the response")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Tests if fetching exchange rates fails when an invalid base currency is provided.
    func testFetchExchangeRates_FailsForInvalidBaseCurrency() {
        let expectation = expectation(description: "Fetching exchange rates should fail for an invalid base currency")

        apiService.shouldFail = true

        apiService.fetchExchangeRates(baseCurrency: "INVALID")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure but received success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure but received data")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Tests if fetching available currencies returns the correct data.
    func testFetchCurrencies_Success() {
        let expectation = expectation(description: "Currencies should be fetched successfully")

        apiService.currencyList = [
            "USD": "US Dollar",
            "EUR": "Euro"
        ]

        apiService.fetchCurrencies()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { currencies in
                XCTAssertEqual(currencies.count, 2, "Unexpected number of currencies")
                XCTAssertTrue(currencies.contains { $0.key == "USD" }, "USD should be in the response")
                XCTAssertTrue(currencies.contains { $0.key == "EUR" }, "EUR should be in the response")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Tests if fetching currencies fails due to an invalid URL.
    func testFetchCurrencies_FailsForInvalidURL() {
        let expectation = expectation(description: "Fetching currencies should fail due to an invalid URL")

        apiService.shouldFail = true

        apiService.fetchCurrencies()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure but received success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure but received data")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }
    
    
    func testAPIFailureReturnsError() {
        let apiService = CurrencyAPIService()
        let expectation = expectation(description: "API should return an error on failure")

        let cancellable = apiService.fetchExchangeRates(baseCurrency: "INVALID")
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("API should fail but returned data")
            })

        wait(for: [expectation], timeout: 5)
        cancellable.cancel()
    }
}

class MockCurrencyAPIService: CurrencyAPIServiceProtocol {
    var exchangeRates: [Currency] = []
    var currencyList: [String : String] = [:]
    var fetchCalled = false
    var fetchCurrenciesCalled = false
    var shouldFail = false

    func fetchExchangeRates(baseCurrency: String) -> AnyPublisher<[Currency], Error> {
        fetchCalled = true
        if shouldFail {
            return Fail(error: NSError(domain: "MockAPIServiceError", code: -1, userInfo: nil))
                .eraseToAnyPublisher()
        }
        return Just(exchangeRates)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchCurrencies() -> AnyPublisher<[String : String], Error> {
        fetchCurrenciesCalled = true
        if shouldFail {
            return Fail(error: NSError(domain: "MockAPIServiceError", code: -1, userInfo: nil))
                .eraseToAnyPublisher()
        }
        return Just(currencyList)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func reset() {
        fetchCalled = false
        fetchCurrenciesCalled = false
        shouldFail = false
        exchangeRates = []
        currencyList = [:]
    }
}
