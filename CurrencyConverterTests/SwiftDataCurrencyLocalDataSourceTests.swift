import XCTest
import SwiftData
@testable import CurrencyConverter

final class SwiftDataCurrencyLocalDataSourceTests: XCTestCase {

    private func makeContainer() -> ModelContainer {
        let schema = Schema([CurrencyEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to load in-memory SwiftData container: \(error)")
        }
    }

    private func makeSUT() -> SwiftDataCurrencyLocalDataSource {
        SwiftDataCurrencyLocalDataSource(modelContainer: makeContainer())
    }

    func testFetchShouldReturnEmptyWhenStoreIsEmpty() async throws {
        let sut = makeSUT()
        let result = try await sut.fetch()
        XCTAssertTrue(result.isEmpty)
    }

    func testFetchShouldReturnAllSavedCurrencies() async throws {
        let sut = makeSUT()
        try await sut.save([
            Currency(code: "USD", name: "US Dollar", value: 1.0),
            Currency(code: "EUR", name: "Euro", value: 0.92),
        ])

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 2)
        let usd = result.first(where: { $0.code == "USD" })
        let eur = result.first(where: { $0.code == "EUR" })
        XCTAssertEqual(usd?.name, "US Dollar")
        XCTAssertEqual(usd?.value, 1.0)
        XCTAssertEqual(eur?.name, "Euro")
        XCTAssertEqual(eur?.value, 0.92)
    }

    func testSaveWithEmptyArray() async throws {
        let sut = makeSUT()
        try await sut.save([])
        let result = try await sut.fetch()
        XCTAssertTrue(result.isEmpty)
    }

    func testInsertNewCurrency() async throws {
        let sut = makeSUT()
        try await sut.save([Currency(code: "JPY", name: "Japanese Yen", value: 149.5)])

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].code, "JPY")
        XCTAssertEqual(result[0].name, "Japanese Yen")
        XCTAssertEqual(result[0].value, 149.5)
    }

    func testUpdateExistingCurrency() async throws {
        let sut = makeSUT()
        try await sut.save([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        try await sut.save([Currency(code: "USD", name: "United States Dollar", value: 1.05)])

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "United States Dollar")
        XCTAssertEqual(result[0].value, 1.05)
    }

    func testMixOfNewAndExistingCurrency() async throws {
        let sut = makeSUT()
        try await sut.save([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        
        // Here, I am updating exiting and interting new currency
        try await sut.save([
            Currency(code: "USD", name: "US Dollar", value: 1.01),
            Currency(code: "CAD", name: "Canadian Dollar", value: 1.36),
        ])

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first(where: { $0.code == "USD" })?.value, 1.01)
        XCTAssertEqual(result.first(where: { $0.code == "CAD" })?.value, 1.36)
    }

    func testDoesNotOverwritePreviouslySavedCurrencies() async throws {
        let sut = makeSUT()
        try await sut.save([Currency(code: "USD", name: "US Dollar", value: 1.0)])
        try await sut.save([Currency(code: "EUR", name: "Euro", value: 0.92)])
        try await sut.save([Currency(code: "JPY", name: "Japanese Yen", value: 149.5)])

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 3)
    }

    func testNotSavedCurrencyTwice() async throws {
        let sut = makeSUT()
        let currency = [Currency(code: "USD", name: "US Dollar", value: 1.0)]
        try await sut.save(currency)
        try await sut.save(currency)

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].code, "USD")
        XCTAssertEqual(result[0].value, 1.0)
    }

    func testLargeBatchInsertsAllCurrencies() async throws {
        let sut = makeSUT()
        let currencies = (1...50).map { i in
            Currency(code: "C\(String(format: "%02d", i))", name: "Currency \(i)", value: Double(i))
        }
        try await sut.save(currencies)

        let result = try await sut.fetch()

        XCTAssertEqual(result.count, 50)
    }
}
