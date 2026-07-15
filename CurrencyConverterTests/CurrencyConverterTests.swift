import XCTest
@testable import CurrencyConverter

final class CurrencyConverterTests: XCTestCase {

    private var sut: CurrencyConverter!

    override func setUp() {
        super.setUp()
        sut = CurrencyConverter(baseCurrencyCode: "USD")
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testWhenAmountIsZero() async {
        await sut.updateCurrencies([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        await sut.updateSelectedCurrency("USD")

        let result = await sut.convert(amount: 0)

        XCTAssertTrue(result.isEmpty)
    }

    func testWhenAmountIsNegative() async {
        await sut.updateCurrencies([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        await sut.updateSelectedCurrency("USD")

        let result = await sut.convert(amount: -50)

        XCTAssertTrue(result.isEmpty)
    }

    func testWhenNoCurrenciesLoaded() async {
        await sut.updateSelectedCurrency("USD")

        let result = await sut.convert(amount: 100)

        XCTAssertTrue(result.isEmpty)
    }

    func testCorrectValueCalculation() async {
        await sut.updateCurrencies([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
            Currency(code: "GBP", name: "British Pound", value: 0.79),
        ])
     
        await sut.updateSelectedCurrency("USD")

        let result = await sut.convert(amount: 100)

        let eur = result.first(where: { $0.code == "EUR" })!
        let gbp = result.first(where: { $0.code == "GBP" })!
        let usd = result.first(where: { $0.code == "USD" })!
        
        XCTAssertEqual(eur.value, 92.0, accuracy: 0.001)
        XCTAssertEqual(gbp.value, 79.0, accuracy: 0.001)
        XCTAssertEqual(usd.value, 100.0, accuracy: 0.001)
    }

    func testSelectedCurrencyAlwaysEqualsInputAmount() async {
        await sut.updateCurrencies([
            Currency(code: "EUR", name: "Euro", value: 0.92),
            Currency(code: "GBP", name: "British Pound", value: 0.79),
        ])
        await sut.updateSelectedCurrency("EUR")

        let result = await sut.convert(amount: 200)

        let eur = result.first(where: { $0.code == "EUR" })!
        XCTAssertEqual(eur.value, 200.0, accuracy: 0.001)
    }

    func testCurrencySortedByCode() async {
        await sut.updateCurrencies([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "AED", name: "UAE Dirham", value: 3.67),
            Currency(code: "GBP", name: "British Pound", value: 0.79),
        ])
        await sut.updateSelectedCurrency("USD")

        let result = await sut.convert(amount: 100)

        XCTAssertEqual(result.map(\.code), ["AED", "GBP", "USD"])
    }
}
