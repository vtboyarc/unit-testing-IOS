//
//  NetworkingController.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//


import Foundation
import UIKit
import CoreData
import Freddy


open class NetworkingController: NSObject{
    
    typealias Payload = [String: AnyObject]
    var notificationCenter = NotificationCenter.default
    //URL Prefixes and appID provided by https://openexchangerates.org .
    //If you intend to RUN or MODIFY this app, please request your own appID from: https://openexchangerates.org it is very easy to do so
    //Given the "free" status of this app, exchange rates are only updated hourly
    let urlPrefixRates = "https://openexchangerates.org/api/latest.json?app_id="
    let urlPrefixFullNames = "https://openexchangerates.org/api/currencies.json?app_id="
    let appID = "db82ad7a2f1642848f56c87f103d3aae"
    let dataController = DataController.sharedInstance
    var currenciesArray = [["XYZ Code" : "Currency Name"]]
    
    func downladFullNames(_ completion: @escaping (_ result: String) -> Void){
        
        //Delete all existing currencies then fetch, could implement different architecture if we wanted to store historical data in the future.
        //Given that you always want the newest, safest data for currencies - or none at all - a full delete seemed least likely to present the user with a false, outdated or mismatched rates
        
       let success = DataController.sharedInstance.deleteAllCurrencies()
        
        if !success {
            self.postAlertNotification()
            print("Failure to delete current cureencies from CoreData")
            return
        }
        
        //Download currencies (just codes and fullNames) from FullNames endpoint
        let fullURL = URL(string: self.urlPrefixFullNames + self.appID)
        let request: NSMutableURLRequest = NSMutableURLRequest(url: fullURL!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                do{
                    let json = try JSON(data: data!)
                    let namesDict = try json.getDictionary()
                    
                    for currencyName in namesDict {
                        //Create new currency entity for each currency in response
                        let currency = NSEntityDescription.insertNewObject(forEntityName: Currency.identifier, into:self.dataController.managedObjectContext) as! Currency
                        //Set currency code and fullName
                        currency.code = currencyName.0
                        currency.fullName = try String(json: currencyName.1)
                        self.dataController.saveContext()
                        
                    }
                    completion("completed")
                }catch {
                self.postAlertNotification()
                    print("Failure to parse JSON or create new Core Data entities")
                }
            }
            else {
                self.postAlertNotification()
                print("Bad response from server. Status code: \(statusCode)")
            }
        }) 
        task.resume()
    }


    func downladExchangeRates(_ completion: @escaping (_ result: String) -> Void){
        //Download exchange rate data from Rates endpoint
        let fullURL = URL(string: self.urlPrefixRates + self.appID)
        let request: NSMutableURLRequest = NSMutableURLRequest(url: fullURL!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            let httpResponse = response as! HTTPURLResponse
            
            do{
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                
                  let json = try JSON(data: data!)
                let ratesDict = try json.getDictionary(at: "rates")
                    
                    for rate in ratesDict {
                       
                            //Fetch currency object based on code
                            let currencyFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Currency")
                            currencyFetch.predicate = NSPredicate(format: "code == %@", rate.0)
                            let currencyArray = try self.dataController.managedObjectContext.fetch(currencyFetch) as! [Currency]
                        
                            //Set usdRate for currency object
                            if currencyArray.count > 0 {
                            currencyArray[0].usdRate = try Double(json: rate.1) as NSNumber?
                            self.dataController.saveContext()
                                }
                            }
                completion("completed")
            }
            else {
                print("Bad response from server. Status code: \(statusCode)")
                self.postAlertNotification()
            }
            }
            catch let error{
                print("Failure to parse JSON or fetch from CoreData. Error Description: \(error)")
                self.postAlertNotification()
                }
        }) 
        task.resume()
    }
    
    
    //testing this in the CashPortStubs file
    func downloadMovers() -> [[String: String]]{
        //Insert Networking code - NSURLSession & JSON
        
        let movers = [["Code" : "ANG", "High" : "2.2", "Low" : "1.6"], ["Code" : "AUD", "High" : "1.2", "Low" : "1.5"]]
        
        return movers

    }

    func postAlertNotification(){
        self.notificationCenter.post(name: Notification.Name(rawValue: "UserDataAlert"), object: nil)
    }
    
   }


