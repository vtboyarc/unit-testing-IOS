//
//  DataController.swift
//
//  Created by Adam Carter on 4/20/17.
//


import Foundation
import CoreData

open class DataController: NSObject {
    
    static let sharedInstance = DataController()
    let notificationCenter = NotificationCenter.default
    
    fileprivate override init() {}
    
    fileprivate lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[(urls.endIndex - 1)]
    }()
    
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "CashPort", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("CashPort.sqlite")
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            let userInfo: [String: AnyObject] = [
                NSLocalizedDescriptionKey: "Failed to initialize the application's saved data" as AnyObject,
                NSLocalizedFailureReasonErrorKey: "There was an error creating or loading the application's saved data" as AnyObject,
                NSUnderlyingErrorKey: error as NSError
            ]
            
            let wrappedError = NSError(domain: "com.teamtreehouse.CoreDataError", code: 9999, userInfo: userInfo)
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            self.postAlertNotification()
            abort()
        }
        
        return coordinator
    }()
    
    open lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        managedObjectContext.persistentStoreCoordinator = coordinator
        
        return managedObjectContext
    }()
    
    open func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                print("Unresolved error \(error), \(error.userInfo)")
                self.postAlertNotification()
            }
        }
    }
    
   open func deleteAllFavorites() -> Bool {
        let favoritesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Favorite")
        var favoritesArray : [Favorite] = []
        
        do {
            
            favoritesArray = try managedObjectContext.fetch(favoritesRequest) as! [Favorite]
            for Favorite in favoritesArray{
                managedObjectContext.delete(Favorite)
                saveContext()
            }
            return true
            
        } catch let error as NSError {
            print("Error fetching all currencies: \(error)")
            self.postAlertNotification()
            return false
        }
    }
    
    open func deleteAllCurrencies() -> Bool {
        let currencyRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Currency")
        var currencyArray : [Currency] = []
        
        do {
            
            currencyArray = try managedObjectContext.fetch(currencyRequest) as! [Currency]
            for Currency in currencyArray{
                managedObjectContext.delete(Currency)
                saveContext()
            }
            return true
            
        } catch let error as NSError {
            print("Error fetching all currencies: \(error)")
            self.postAlertNotification()
            return false
        }
    }
    
    func getAllCurrencies() -> [Currency] {
        let currencyRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Currency")
        let sortByFullName = NSSortDescriptor(key: "fullName", ascending:true)
        currencyRequest.sortDescriptors = [sortByFullName]
        var currencyArray : [Currency] = []
        do {

        currencyArray = try managedObjectContext.fetch(currencyRequest) as! [Currency]
        return currencyArray
            
        } catch let error as NSError {
        print("Error fetching all currencies: \(error)")
        self.postAlertNotification()
        return currencyArray
        }
        
    }
    
    func getCurrencyByCodeFullName(_ code: String, fullName: String) -> (Currency?){
        //Fetch currency by code AND fullName to eliminate risk of mismatch from updated API data
        let currencyFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Currency")
        currencyFetch.predicate = NSPredicate(format: "code == %@ AND fullName == %@", code, fullName)
        do{
            let currencyArray = try managedObjectContext.fetch(currencyFetch) as! [Currency]
            return currencyArray[0]
        }
        catch let error as NSError {
            print("Error fetching currency by code and name: \(error)")
            self.postAlertNotification()
            return nil
        }
    }
    
    func getAllFavorites() -> [Favorite] {
        let currencyRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Favorite")
        var favoriteArray : [Favorite] = []
        do {
            favoriteArray = try managedObjectContext.fetch(currencyRequest) as! [Favorite]
            return favoriteArray
            
        } catch let error as NSError {
            print("Error getting all favorites: \(error)")
            self.postAlertNotification()
            return favoriteArray
        }
    }
    
    func setCurrentFavorite (_ fromCurrency: Bool, currency: Currency) -> Void{
        //Set currently selected TO and FROM as lone "favorite" to be used to pre-populate fields on next load
        //This is overbuilt for current needs, but was built so it would be easily entensible to store list of favorites, tableview on new tab, etc...
        
        var currentFavorites: [Favorite] = DataController.sharedInstance.getAllFavorites()
        
        if currentFavorites.count == 1 {
            //Update existing favorite
            let currentFavorite: Favorite = currentFavorites[0]
            
            if fromCurrency{
                //fromCurrency was set by user
                currentFavorite.codeFROM = currency.code
                currentFavorite.fullNameFROM = currency.fullName
            }
            else{
                //toCurrency was set by user
                currentFavorite.codeTO = currency.code
                currentFavorite.fullNameTO = currency.fullName
            }
            DataController.sharedInstance.saveContext()
            return
        }
        
        if currentFavorites.count > 1 {
            //Extra Favorites have accumulated somehow, clear them out
            //Remove this safety check if extending to store list of favorites
            DataController.sharedInstance.deleteAllFavorites()
            DataController.sharedInstance.saveContext()
            currentFavorites = DataController.sharedInstance.getAllFavorites()
            print("System is accumulating Favorites, this shouldn't happen under current architecture.")
        }
        
        if currentFavorites.count == 0 {
            //No existing favorites, create one and set first value
            let newFavorite = NSEntityDescription.insertNewObject(forEntityName: Favorite.identifier, into:self.managedObjectContext) as! Favorite
            
            if fromCurrency{
                //fromCurrency was set by user
                newFavorite.codeFROM = currency.code
                newFavorite.fullNameFROM = currency.fullName
            }
            else{
                //toCurrency was set by user
                newFavorite.codeTO = currency.code
                newFavorite.fullNameTO = currency.fullName
            }
            DataController.sharedInstance.saveContext()
            return
        }
    }
    
    func postAlertNotification(){
        self.notificationCenter.post(name: Notification.Name(rawValue: "UserDataAlert"), object: nil)
    }
}





































