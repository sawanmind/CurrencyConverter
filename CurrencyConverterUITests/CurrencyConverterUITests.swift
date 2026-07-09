//
//  CurrencyConverterUITests.swift
//  CurrencyConverterUITests
//
//  Created by Sawan Kumar on 06/02/25.
//

import XCTest

class CurrencyConverterUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCurrencySelection() {
        let selectCurrencyButton = app.buttons["selectCurrencyButton"]
        XCTAssertTrue(selectCurrencyButton.waitForExistence(timeout: 5), "Currency selection button not found")
        
        selectCurrencyButton.tap()

        let currencyListView = app.navigationBars["Select Currency"]
        XCTAssertTrue(currencyListView.waitForExistence(timeout: 5), "Currency list view should be displayed")
        
        let firstCurrency = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'currencyCell_'")).firstMatch
        XCTAssertTrue(firstCurrency.waitForExistence(timeout: 5), "No currency options found in the list")

        firstCurrency.tap()

        XCTAssertTrue(selectCurrencyButton.waitForExistence(timeout: 5), "Did not return to main screen after currency selection")
    }
    
    func testButtonTap() {
        let selectCurrencyButton = app.buttons["selectCurrencyButton"]
        XCTAssertTrue(selectCurrencyButton.waitForExistence(timeout: 5), "Currency selection button not found")
        
        selectCurrencyButton.tap()

        let currencyListView = app.navigationBars["Select Currency"]
        XCTAssertTrue(currencyListView.waitForExistence(timeout: 5), "Currency list did not appear after tapping selection button")
    }
    
    func testAmountInput() {
        let amountTextField = app.textFields["amountTextField"]
        XCTAssertTrue(amountTextField.waitForExistence(timeout: 5), "Amount input field not found")
        
        amountTextField.tap()
        amountTextField.clearText()
        amountTextField.tap()
        amountTextField.typeText("100")
        
        XCTAssertEqual(amountTextField.value as? String, "100", "Amount input field did not update correctly")
    }
    
    func testCurrencyConversionUpdates() {
        let amountTextField = app.textFields["amountTextField"]
        XCTAssertTrue(amountTextField.waitForExistence(timeout: 5), "Amount input field not found")

        amountTextField.tap()
        amountTextField.clearText()
        amountTextField.tap()
        amountTextField.typeText("50")
        
        let convertedCurrencies = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'currencyGrid_'"))
        XCTAssertTrue(convertedCurrencies.count > 0, "No converted currency displayed in the grid")
    }
    
    func testAccessibilityIdentifiers() {
        let selectCurrencyButton = app.buttons["selectCurrencyButton"]
        XCTAssertTrue(selectCurrencyButton.exists, "Currency selection button should be accessible")
        
        let amountTextField = app.textFields["amountTextField"]
        XCTAssertTrue(amountTextField.exists, "Amount input field should have an accessibility identifier")
    }
    
    
    func testLargeAmountConversion() {
        let amountTextField = app.textFields["amountTextField"]
        amountTextField.tap()
        amountTextField.typeText("9999999999")
        
        let convertedGrid = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'currencyGrid_'"))
        let exists = convertedGrid.element.waitForExistence(timeout: 5)
        
        XCTAssertTrue(exists, "Should display converted values for large amounts")
    }
    

}

extension XCUIElement {
    func clearText() {
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (value as? String)?.count ?? 10)
        typeText(deleteString)
    }
}
