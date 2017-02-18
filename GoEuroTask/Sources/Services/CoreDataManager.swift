//
//  GECoreDataManager.swift
//  GoEuroTask
//
//  Created by Roman Sinelnikov on 18/02/17.
//  Copyright © 2017 Roman Sinelnikov. All rights reserved.
//

import Foundation
import CoreData


protocol CoreDataManager {
    var viewContext: NSManagedObjectContext { get }
    func write(block: @escaping (NSManagedObjectContext) throws -> ()) throws
}

public class CoreDataSwiftManager: CoreDataManager {

    /// Context only for reading, do not use it for writing!!!
    public let viewContext: NSManagedObjectContext
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator
    private let managedObjectModel: NSManagedObjectModel
    private let backgroundContext: NSManagedObjectContext
    init() throws {
        self.managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)!
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
            .appendingPathComponent("app.sqlite")

        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        try persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil
        )
        
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        self.viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backgroundContextChanged(notification:)),
            name: .NSManagedObjectContextDidSave,
            object: self.backgroundContext
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc private func backgroundContextChanged(notification: Notification) {
        self.viewContext.perform {
            self.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    /// Do not use this func from main queue, it can block it
    ///
    /// - Parameter block: block to execute
    /// - Throws: error that occured inside the block or writing error
    public func write(block: @escaping (NSManagedObjectContext) throws -> ()) throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.backgroundContext
        var error: Swift.Error? = nil
        context.performAndWait {
            do {
                try block(context)
                try context.save()
                self.backgroundContext.perform {
                    try? self.backgroundContext.save()
                }

            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }
}
