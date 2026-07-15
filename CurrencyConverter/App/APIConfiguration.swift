//
//  APIConfiguration.swift
//  CurrencyConverter
//

import Foundation

struct APIConfiguration: Sendable {

    let baseURL: URL
    let appID: String

    static let `default` = APIConfiguration(
        baseURL: URL(string: "https://openexchangerates.org/api")!,
        appID: "fa4e733abc6b42828c42103c99906426"
    )
}
