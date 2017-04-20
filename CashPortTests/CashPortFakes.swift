//
//  CashPortFakes.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//


import XCTest
import CoreData
@testable import CashPort

class CashPortFakes: XCTestCase {
    
    //CoreData properties
    var persistentStore: NSPersistentStore!
    var storeCoordinator: NSPersistentStoreCoordinator!
    var managedObjectContext: NSManagedObjectContext!
    var managedObjectModel: NSManagedObjectModel!
    
    var dataController = DataController.sharedInstance
    var fakeCurrency : Currency!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        managedObjectModel = NSManagedObjectModel.mergedModel(from: nil)
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        do{
            try  persistentStore = storeCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = storeCoordinator
        }
        catch{
            print("Unresolved error \(error)")
        }
        
        dataController.managedObjectContext = managedObjectContext
        
        fakeCurrency = NSEntityDescription.insertNewObject(forEntityName: Currency.identifier, into:managedObjectContext) as! Currency
        //Set currency code and fullName
        fakeCurrency.code = "ABC"
        fakeCurrency.fullName = "Another Bad Creation"
        fakeCurrency.usdRate = 98.6
        do{
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error)")
        }

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        dataController.deleteAllCurrencies()
        managedObjectModel = nil
        managedObjectContext = nil
        persistentStore = nil
        storeCoordinator = nil
        super.tearDown()
    }
    
    
    func testDeleteAllCurrencies(){
        
        XCTAssert(dataController.getAllCurrencies().count == 1, "More or less than 1 currency found")
        
        dataController.deleteAllCurrencies()
        
        XCTAssert(dataController.getAllCurrencies().count == 0, "Delete failed, more than 0 currencies found")
        
    }
    
}
