//
//  CurrencyConverterViewModelTests.swift
//  CurrencyConverterTests
//
//  Created by Sawan Kumar on 06/02/25.
//

import XCTest
import Combine
@testable import CurrencyConverter

class CurrencyConverterViewModelTests: XCTestCase {
    
    var viewModel: CurrencyConverterViewModel!
    var mockAPIService: MockCurrencyAPIService!
    var mockStorageService: MockCoreDataService!
    var mockRepository: MockCurrencyRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockAPIService = MockCurrencyAPIService()
        mockStorageService = MockCoreDataService()
        mockRepository = MockCurrencyRepository(apiService: mockAPIService, storageService: mockStorageService)
        viewModel = CurrencyConverterViewModel(currencyRepository: mockRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // Checks if the default values in the ViewModel are set correctly.
    func testDefaultValues() {
        XCTAssertEqual(viewModel.amount, "1", "Initial amount should be 1")
        XCTAssertEqual(viewModel.selectedCurrency, "USD", "Initial selected currency should be USD")
        XCTAssertTrue(viewModel.convertedCurrencies.isEmpty, "Converted currencies should be empty initially")
    }

    // Validates currency conversion from USD to INR and EUR.
    func testConversionFromUSDToOtherCurrencies() {
        mockRepository.exchangeRates = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        viewModel.selectedCurrency = "USD"
        viewModel.amount = "10"
        viewModel.exchangeRates = mockRepository.exchangeRates
        viewModel.convertCurrencies()

        let inrRate = viewModel.convertedCurrencies.first(where: { $0.code == "INR" })?.value
        let eurRate = viewModel.convertedCurrencies.first(where: { $0.code == "EUR" })?.value

        XCTAssertNotNil(inrRate, "INR conversion result should not be nil")
        XCTAssertNotNil(eurRate, "EUR conversion result should not be nil")

        let expectedINR = 10 * 83.27
        let expectedEUR = 10 * 0.92

        XCTAssertEqual(inrRate!, expectedINR, accuracy: 0.1, "INR conversion is incorrect")
        XCTAssertEqual(eurRate!, expectedEUR, accuracy: 0.1, "EUR conversion is incorrect")
    }

    // Validates currency conversion from INR to USD and EUR.
    func testConversionFromINRToOtherCurrencies() {
        mockRepository.exchangeRates = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27),
            Currency(code: "EUR", name: "Euro", value: 0.92)
        ]

        viewModel.selectedCurrency = "INR"
        viewModel.amount = "100"
        viewModel.exchangeRates = mockRepository.exchangeRates
        viewModel.convertCurrencies()

        let usdRate = viewModel.convertedCurrencies.first(where: { $0.code == "USD" })?.value
        let eurRate = viewModel.convertedCurrencies.first(where: { $0.code == "EUR" })?.value

        XCTAssertNotNil(usdRate, "USD conversion result should not be nil")
        XCTAssertNotNil(eurRate, "EUR conversion result should not be nil")

        let expectedUSD = 100 / 83.27
        let expectedEUR = expectedUSD * 0.92

        XCTAssertEqual(usdRate!, expectedUSD, accuracy: 0.1, "USD conversion is incorrect")
        XCTAssertEqual(eurRate!, expectedEUR, accuracy: 0.1, "EUR conversion is incorrect")
    }

    // Ensures invalid input does not trigger currency conversion.
    func testInvalidAmountInput() {
        viewModel.amount = "abc"
        viewModel.convertCurrencies()
        XCTAssertTrue(viewModel.convertedCurrencies.isEmpty, "Conversion should not occur for invalid input")

        viewModel.amount = "-10"
        viewModel.convertCurrencies()
        XCTAssertTrue(viewModel.convertedCurrencies.isEmpty, "Conversion should not occur for negative values")

        viewModel.amount = "0"
        viewModel.convertCurrencies()
        XCTAssertTrue(viewModel.convertedCurrencies.isEmpty, "Conversion should not occur for zero")
    }

    // Checks if exchange rates are fetched properly.
    func testFetchExchangeRates() {
        mockRepository.fetchCalled = false
        let expectation = expectation(description: "Fetching exchange rates")

        viewModel.fetchExchangeRates()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.mockRepository.fetchCalled, "Fetch request should be triggered")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    // Ensures that fetching exchange rates updates converted currencies.
    func testFetchingExchangeRatesUpdatesConvertedCurrencies() {
        mockRepository.exchangeRates = [
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
            Currency(code: "INR", name: "Indian Rupee", value: 83.27)
        ]

        viewModel.exchangeRates = mockRepository.exchangeRates
        viewModel.convertCurrencies()

        XCTAssertEqual(viewModel.convertedCurrencies.count, 3, "Converted currencies count should be updated")
        XCTAssertEqual(viewModel.convertedCurrencies.first?.code, "EUR", "Currency list should be sorted alphabetically")
    }

    // Verifies that selecting a currency triggers the update through EventBus.
    func testEventBusTriggersCurrencyUpdate() {
        let expectation = expectation(description: "Currency selection should update view model")

        let cancellable = viewModel.$selectedCurrency
            .dropFirst()
            .sink { newCurrency in
                if newCurrency == "EUR" {
                    expectation.fulfill()
                }
            }
        
        EventBus.shared.currencySelected.send("EUR")

        wait(for: [expectation], timeout: 2)
        cancellable.cancel()
    }
  
}
