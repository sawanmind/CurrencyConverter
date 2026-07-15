import XCTest

class CurrencyListViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    /// The list is sorted alphabetically by currency code, so rows past the
    /// first screenful (e.g. EUR, JPY) don't exist in the accessibility tree
    /// until the list is scrolled to render them. Swipes up until the row
    /// appears or `maxSwipes` is reached.
    @discardableResult
    private func scrollUntilVisible(_ element: XCUIElement, maxSwipes: Int = 200) -> Bool {
        var attempts = 0
        while !element.exists && attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
        return element.exists
    }

    func testCurrencyListTitleAppears() {
        let selectCurrencyButton = app.buttons["selectCurrencyButton"]
        XCTAssertTrue(selectCurrencyButton.waitForExistence(timeout: 5), "Currency selection button not found")

        selectCurrencyButton.tap()

        let currencyListTitle = app.navigationBars["Select Currency"]
        XCTAssertTrue(currencyListTitle.waitForExistence(timeout: 5), "Currency list title should be displayed")
    }

    func testSearchFieldFiltersCurrencyList() {
        app.buttons["selectCurrencyButton"].tap()

        let eurRow = app.buttons["currencyCell_EUR"]
        XCTAssertTrue(scrollUntilVisible(eurRow), "EUR row not found before searching")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field not found")
        searchField.tap()
        searchField.typeText("Euro")

        XCTAssertTrue(app.buttons["currencyCell_EUR"].waitForExistence(timeout: 5), "EUR row should still be visible after searching for 'Euro'")
        XCTAssertFalse(app.buttons["currencyCell_JPY"].exists, "JPY row should be filtered out after searching for 'Euro'")
    }

    func testClearingSearchRestoresFullCurrencyList() {
        app.buttons["selectCurrencyButton"].tap()

        XCTAssertTrue(scrollUntilVisible(app.buttons["currencyCell_JPY"]), "JPY row not found before searching")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field not found")
        searchField.tap()
        searchField.typeText("Euro")
        XCTAssertFalse(app.buttons["currencyCell_JPY"].exists, "JPY row should be filtered out after searching for 'Euro'")

        let clearButton = app.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        } else {
            searchField.buttons.firstMatch.tap()
        }

        XCTAssertTrue(scrollUntilVisible(app.buttons["currencyCell_JPY"]), "JPY row should reappear after clearing the search")
    }

    func testSelectingCurrencyDismissesListAndUpdatesButton() {
        let selectCurrencyButton = app.buttons["selectCurrencyButton"]
        selectCurrencyButton.tap()

        let eurRow = app.buttons["currencyCell_EUR"]
        XCTAssertTrue(scrollUntilVisible(eurRow), "EUR row not found")
        eurRow.tap()

        let currencyListTitle = app.navigationBars["Select Currency"]
        XCTAssertFalse(currencyListTitle.waitForExistence(timeout: 5), "Currency list should be dismissed after selecting a currency")

        XCTAssertTrue(selectCurrencyButton.waitForExistence(timeout: 5), "Did not return to main screen after currency selection")
        XCTAssertTrue(selectCurrencyButton.label.contains("EUR"), "Currency selection button should update to reflect the selected currency")
    }
}
