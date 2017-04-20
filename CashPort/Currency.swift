//
//  Currency.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//


import Foundation
import CoreData
import Freddy

class Currency: NSManagedObject {
    
static let identifier = "Currency"
    
    @NSManaged var code: String?
    @NSManaged var usdRate: NSNumber?
    @NSManaged var fullName: String?
   
    var pickerName : String {
    get{
       return "\(fullName!) (\(code!))"
    }
        }
}
