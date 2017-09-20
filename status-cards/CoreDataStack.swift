//
//  CoreDataStack.swift
//  status-cards
//
//  Created by Sergey Khruschak on 9/14/17.
//  Copyright © 2017 Sergey Khruschak. All rights reserved.
//

import Foundation
import CoreData

@available(OSX 10.12, *)
class CoreDataStack: NSObject {
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Dictionary")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. 
                // You should not use this function in a shipping application, although it may be useful during development.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
    
    func load(completionClosure: @escaping () -> ()) {
        guard let modelURL = Bundle.main.url(forResource: "status_cards", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
            
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
            
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
            
        managedObjectContext.persistentStoreCoordinator = psc
            
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        queue.async {
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                fatalError("Unable to resolve document directory")
            }
            let storeURL = docURL.appendingPathComponent("Dictionary.sqlite")
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                DispatchQueue.main.sync(execute: completionClosure)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    
    /*
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.appendingPathComponent("org.sergkh.status_cards")
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {        
        let modelURL = Bundle.main.url(forResource: "status_cards", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("dictionary.sqlite")
        do {
            // If your looking for any kind of migration then here is the time to pass it to the options
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch let  error as NSError {
            print("Ops there was an error \(error.localizedDescription)")
            abort()
        }
        return coordinator
    }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
     // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
     let fileManager = FileManager.default
     var shouldFail = false
     var error: NSError? = nil
     var failureReason = "There was an error creating or loading the application's saved data."
     
     // Make sure the application files directory is there
     let propertiesOpt = self.applicationDocumentsDirectory.resourceValuesForKeys([URLResourceKey.isDirectoryKey], error: &error)
     if let properties = propertiesOpt {
     if !properties[URLResourceKey.isDirectoryKey]!.boolValue {
     failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
     shouldFail = true
     }
     } else if error!.code == NSFileReadNoSuchFileError {
     error = nil
     fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil, error: &error)
     }
     
     // Create the coordinator and store
     var coordinator: NSPersistentStoreCoordinator?
     if !shouldFail && (error == nil) {
     coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
     let url = self.applicationDocumentsDirectory.appendingPathComponent("status_cards.storedata")
     if coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
     coordinator = nil
     }
     }
     
     if shouldFail || (error != nil) {
     // Report any error we got.
     var dict = [String: AnyObject]()
     dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
     dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
     if error != nil {
     dict[NSUnderlyingErrorKey] = error
     }
     error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
     NSApplication.shared().presentError(error!)
     return nil
     } else {
     return coordinator
     }
     }()*/
    

}
