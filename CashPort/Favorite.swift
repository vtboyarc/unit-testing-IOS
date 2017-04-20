//
//  Favorite.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//


import Foundation
import CoreData
import Freddy

class Favorite: NSManagedObject {
    
    //Current architecture deletes ALL currencies on refresh, in order to prevent bad/obsolete data. Therefore, we store identifiers (code and fullName), instead of currency objects as properties for Favorites below. If extending the app to store historical data, refactor below and deleteAll on refresh.
    
    static let identifier = "Favorite"
    
    @NSManaged var codeFROM: String?
    @NSManaged var fullNameFROM: String?
    @NSManaged var codeTO: String?
    @NSManaged var fullNameTO: String?
    
    
}
