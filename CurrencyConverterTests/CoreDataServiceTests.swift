//
//  CoreDataServiceTests.swift
//  CurrencyConverterTests
//
//  Created by Sawan Kumar on 06/02/25.
//

import XCTest
@testable import CurrencyConverter

class CoreDataServiceTests: XCTestCase {
    var coreDataService: MockCoreDataService!

    override func setUp() {
        super.setUp()
        coreDataService = MockCoreDataService()
    }

    override func tearDown() {
        coreDataService = nil
        super.tearDown()
    }

    // Tests if exchange rates are stored and retrieved correctly from Core Data.
    func testStoresAndFetchesCorrectRates() {
        let rates = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        XCTAssertNoThrow(coreDataService.storeExchangeRates(rates), "Storage should not throw an error")

        let result = coreDataService.fetchStoredRates()
        switch result {
        case .success(let storedRates):
            XCTAssertEqual(storedRates.count, 2, "Stored rates count does not match")
            XCTAssertTrue(storedRates.contains(where: { $0.code == "USD" }), "USD should be in stored rates")
            XCTAssertTrue(storedRates.contains(where: { $0.code == "EUR" }), "EUR should be in stored rates")
        case .failure(let error):
            XCTFail("Fetching stored rates failed: \(error)")
        }
    }

    // Tests that the service correctly handles a failure when storing rates.
    func testHandlesStorageFailure() {
        coreDataService.shouldReturnError = true

        let storeResult = coreDataService.storeExchangeRates([Currency(code: "GBP", name: "British Pound", value: 0.78)])
        switch storeResult {
        case .failure(let error):
            XCTAssertNotNil(error, "Storage error should be returned")
        case .success:
            XCTFail("Storage failure should have been simulated but succeeded")
        }
    }

    // Tests that the service correctly handles a failure when fetching stored rates.
    func testHandlesFetchFailure() {
        coreDataService.shouldReturnError = true

        let fetchResult = coreDataService.fetchStoredRates()
        switch fetchResult {
        case .failure(let error):
            XCTAssertNotNil(error, "Fetch error should be returned")
        case .success:
            XCTFail("Fetch failure should have been simulated but succeeded")
        }
    }

    // Tests that stored exchange rates can be cleared successfully.
    func testClearStoredRates() {
        let rates = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        coreDataService.storeExchangeRates(rates)
        XCTAssertEqual(try? coreDataService.fetchStoredRates().get().count, 2, "Rates should be stored before clearing")

        let clearResult = coreDataService.clearStoredRates()
        switch clearResult {
        case .success:
            XCTAssertEqual(try? coreDataService.fetchStoredRates().get().count, 0, "Stored rates should be cleared")
        case .failure(let error):
            XCTFail("Clear stored rates should not fail, but got error: \(error)")
        }
    }
}

class MockCoreDataService: CoreDataServiceProtocol {
    private(set) var storedRates: [Currency] = []
    var shouldReturnError = false
    var storeCalled = false

    func fetchStoredRates() -> Result<[Currency], Error> {
        shouldReturnError
            ? .failure(NSError(domain: "MockCoreDataServiceError", code: 1, userInfo: nil))
            : .success(storedRates)
    }

    func storeExchangeRates(_ rates: [Currency]) -> Result<Void, Error> {
        guard !shouldReturnError else {
            return .failure(NSError(domain: "MockCoreDataServiceError", code: 2, userInfo: nil))
        }
        storeCalled = true
        storedRates = rates
        return .success(())
    }

    func clearStoredRates() -> Result<Void, Error> {
        guard !shouldReturnError else {
            return .failure(NSError(domain: "MockCoreDataServiceError", code: 3, userInfo: nil))
        }
        storedRates.removeAll()
        return .success(())
    }

    func reset() {
        storedRates = []
        storeCalled = false
        shouldReturnError = false
    }
}
