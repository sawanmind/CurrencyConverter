import XCTest
@testable import CurrencyConverter

private final class MockHTTPClient: HTTPClient, @unchecked Sendable {

    var result: Result<Any, Error> = .success(())
    private(set) var request: URLRequest?

    func request<Response: Decodable>(_ request: URLRequest,
    responseType: Response.Type) async throws -> Response {
        self.request = request
        switch result {
        case .success(let value):
            return value as! Response
        case .failure(let error):
            throw error
        }
    }
}

final class RESTCurrencyRemoteDataSourceTests: XCTestCase {

    private var client: MockHTTPClient!
    private var sut: RESTCurrencyRemoteDataSource!

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        sut = RESTCurrencyRemoteDataSource(
            client: client,
            configuration: APIConfiguration(
                baseURL: URL(string: "https://api.test.com")!,
                appID: "test-app-id"
            )
        )
    }

    override func tearDown() {
        sut = nil
        client = nil
        super.tearDown()
    }

    func testFetchExchangeRatesForURLValidatationAndQuery() async throws {
        client.result = .success(ExchangeRate(rates: ["USD": 1.0]))

        _ = try await sut.fetchExchangeRates(baseCurrency: "USD")

        let url = client.request?.url
        XCTAssertEqual(url?.host, "api.test.com")
        XCTAssertTrue(url?.path.contains("latest.json") == true)
        
        let query = url?.query ?? ""
        XCTAssertTrue(query.contains("base=USD"))
        XCTAssertTrue(query.contains("app_id=test-app-id"))
    }

    func testFetchExchangeRatesWithExpectedResult() async throws {
        client.result = .success(ExchangeRate(rates: ["USD": 1.0, "EUR": 0.92]))

        let result = try await sut.fetchExchangeRates(baseCurrency: "USD")

        XCTAssertEqual(result.rates["USD"], 1.0)
        XCTAssertEqual(result.rates["EUR"], 0.92)
    }

    func testFetchExchangeRatesForInvalidResponse() async {
        client.result = .failure(APIError.invalidResponse)

        do {
            _ = try await sut.fetchExchangeRates(baseCurrency: "USD")
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchCurrenciesForURLValidatationAndQuery() async throws {
        client.result = .success(["USD": "US Dollar"])

        _ = try await sut.fetchCurrencies()

        let url = client.request?.url
        XCTAssertEqual(url?.host, "api.test.com")
        XCTAssertTrue(url?.path.contains("currencies.json") == true)
        
        let query = url?.query ?? ""
        XCTAssertTrue(query.contains("app_id=test-app-id"))
    }

    func testFetchCurrenciesWithExpectedResult() async throws {
        client.result = .success(["USD": "US Dollar", "EUR": "Euro"])

        let result = try await sut.fetchCurrencies()

        XCTAssertEqual(result["USD"], "US Dollar")
        XCTAssertEqual(result["EUR"], "Euro")
    }

    func testFetchCurrenciesForInvalidResponse() async {
        client.result = .failure(APIError.networkUnavailable)

        do {
            _ = try await sut.fetchCurrencies()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
