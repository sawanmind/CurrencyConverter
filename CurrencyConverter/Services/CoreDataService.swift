//
//  CoreDataService.swift
//  CurrencyConverter
//
//  Created by Sawan Kumar on 08/02/25.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "CurrencyDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }
    
    static func inMemory() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "CurrencyDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory Core Data stack: \(error)")
            }
        }
        return container
    }
}


protocol CoreDataServiceProtocol {
    func fetchStoredRates() -> Result<[Currency], Error>
    func storeExchangeRates(_ rates: [Currency]) -> Result<Void, Error>
    func clearStoredRates() -> Result<Void, Error>
}

class CoreDataService: CoreDataServiceProtocol {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(container: NSPersistentContainer = CoreDataStack.shared.container) {
        self.container = container
        self.context = container.viewContext
    }
    
    func fetchStoredRates() -> Result<[Currency], Error> {
        
        let fetchRequest: NSFetchRequest<CurrencyEntity> = CurrencyEntity.fetchRequest()
        
        do {
            let storedRates = try context.fetch(fetchRequest)
            let currencies = storedRates.map { Currency(code: $0.code ?? "", name: $0.name ?? "", value: $0.value) }
            return .success(currencies.sorted { $0.code < $1.code })
        } catch {
            return .failure(error)
        }
    }
    
    @discardableResult
    func storeExchangeRates(_ rates: [Currency]) -> Result<Void, Error> {
        do {
            try clearStoredRates().get()
            
            for rate in rates {
                let entity = CurrencyEntity(context: context)
                entity.code = rate.code
                entity.name = rate.name
                entity.value = rate.value
            }
            
            try saveContext()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    @discardableResult
    func clearStoredRates() -> Result<Void, Error> {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CurrencyEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try saveContext()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

