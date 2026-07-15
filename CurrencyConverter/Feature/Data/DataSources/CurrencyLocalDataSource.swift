
import Foundation
import SwiftData

protocol CurrencyLocalDataSource: Sendable {
    func fetch() async throws -> [Currency]
    func save(_ currencies: [Currency]) async throws
}

actor SwiftDataCurrencyLocalDataSource: CurrencyLocalDataSource, ModelActor {

    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor

    private var modelContext: ModelContext {
        modelExecutor.modelContext
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    func fetch() async throws -> [Currency] {
        let descriptor = FetchDescriptor<CurrencyEntity>(
            sortBy: [SortDescriptor(\.code)]
        )
        let records = try modelContext.fetch(descriptor)
        return records.map({$0.toDomain()})
    }

    func save(_ currencies: [Currency]) async throws {
        guard !currencies.isEmpty else { return }

        let descriptor = FetchDescriptor<CurrencyEntity>()
        let existing = try modelContext.fetch(descriptor)

        var existingByCode: [String: CurrencyEntity] = [:]
        for record in existing {
            existingByCode[record.code] = record
        }

        for currency in currencies {
            if let record = existingByCode[currency.code] {
                record.name = currency.name
                record.value = currency.value
            } else {
                let entity = CurrencyEntity(code: currency.code, name: currency.name, value: currency.value)
                modelContext.insert(entity)
            }
        }

        try modelContext.save()
    }
}
