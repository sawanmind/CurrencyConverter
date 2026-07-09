//
//  CurrencyListViewModelTests.swift
//  CurrencyConverterTests
//
//  Created by Sawan Kumar on 08/02/25.
//

import XCTest
import Combine
@testable import CurrencyConverter

class CurrencyListViewModelTests: XCTestCase {
    var viewModel: CurrencyListViewModel!
    var mockAPIService: MockCurrencyAPIService!
    var mockStorageService: MockCoreDataService!
    var mockRepository: MockCurrencyRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockAPIService = MockCurrencyAPIService()
        mockStorageService = MockCoreDataService()
        mockRepository = MockCurrencyRepository(apiService: mockAPIService, storageService: mockStorageService)
        viewModel = CurrencyListViewModel(currencyRepository: mockRepository, baseCurrency: "USD")
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // Ensures the ViewModel starts with empty values.
    func testInitialState() {
        XCTAssertTrue(viewModel.currencies.isEmpty, "Currencies should be empty initially")
        XCTAssertTrue(viewModel.filteredCurrencies.isEmpty, "Filtered currencies should be empty initially")
        XCTAssertEqual(viewModel.searchText, "", "Search text should be empty initially")
    }

    // Checks if currencies are fetched correctly and stored.
    func testFetchCurrencies() {
        let expectation = expectation(description: "Currencies should be fetched and stored")

        mockRepository.currencies = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27)
        ]

        viewModel.fetchCurrencies()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.viewModel.currencies.count, 3, "Currencies count mismatch after fetch")
            XCTAssertEqual(self.viewModel.filteredCurrencies.count, 3, "Filtered currencies should match initially")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    // Tests if filtering works correctly based on search input.
    func testSearchTextFiltering() {
        viewModel.currencies = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27)
        ]

        viewModel.searchText = "USD"
        XCTAssertEqual(viewModel.filteredCurrencies.count, 1, "Filtered list should contain only USD")
        XCTAssertEqual(viewModel.filteredCurrencies.first?.code, "USD", "Incorrect search result for 'USD'")

        viewModel.searchText = "eur"
        XCTAssertEqual(viewModel.filteredCurrencies.count, 1, "Filtered list should contain only EUR")
        XCTAssertEqual(viewModel.filteredCurrencies.first?.code, "EUR", "Incorrect search result for 'eur'")

        viewModel.searchText = "ind"
        XCTAssertEqual(viewModel.filteredCurrencies.count, 1, "Filtered list should contain only INR")
        XCTAssertEqual(viewModel.filteredCurrencies.first?.code, "INR", "Incorrect search result for 'ind'")

        viewModel.searchText = "ZZZ"
        XCTAssertTrue(viewModel.filteredCurrencies.isEmpty, "Search should return an empty list for unknown text")
    }

    // Ensures that clearing the search resets the filtered list.
    func testSearchClearedResetsFilter() {
        viewModel.currencies = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        viewModel.searchText = "USD"
        XCTAssertEqual(viewModel.filteredCurrencies.count, 1, "Filtered list should contain 1 match")

        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredCurrencies.count, 2, "Clearing search should reset filtered list")
    }

    // Ensures selecting a currency triggers an update via EventBus.
    func testSelectCurrency() {
        let expectation = expectation(description: "Currency selection should be sent to EventBus")
        let mockCurrency = Currency(code: "USD", name: "US Dollar", value: 1.0)

        let eventBusCancellable = EventBus.shared.currencySelected
            .first()
            .sink { selectedCode in
                XCTAssertEqual(selectedCode, "USD", "Selected currency should be 'USD'")
                expectation.fulfill()
            }

        viewModel.selectCurrency(mockCurrency)

        wait(for: [expectation], timeout: 1)
        eventBusCancellable.cancel()
    }

    // Tests behavior when fetching an empty currency list.
    func testFetchEmptyCurrencies() {
        let expectation = expectation(description: "Fetching empty currencies should work correctly")

        mockRepository.exchangeRates = []
        viewModel.fetchCurrencies()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(self.viewModel.currencies.isEmpty, "Currencies should be empty after fetching empty data")
            XCTAssertTrue(self.viewModel.filteredCurrencies.isEmpty, "Filtered currencies should be empty")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
