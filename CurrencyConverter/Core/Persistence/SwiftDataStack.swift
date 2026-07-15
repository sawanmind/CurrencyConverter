//
//  CoreDataStack.swift
//  CurrencyConverter
//

import Foundation
import SwiftData

enum SwiftDataStack {
    static let shared: ModelContainer = {
        let schema = Schema([CurrencyEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to load SwiftData container: \(error)")
        }
    }()
}
