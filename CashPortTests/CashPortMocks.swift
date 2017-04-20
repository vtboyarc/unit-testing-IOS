//
//  CashPortMocks.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//

import XCTest
//the name of the project
@testable import CashPort

class CashPortMocks: XCTestCase {
    
    //creating  mock of the NetworkingController class file
    let networkingController = NetworkingController()
    //MockNotificationCenter is a function I made down below in this file
    let mockNotificationCenter = MockNotificationCenter()
    
    override func setUp() {
        super.setUp()
        //notificationCenter is a var in the NetworkingController class
        //I have access to it in this file, because networkingController is an instance of it
        networkingController.notificationCenter = mockNotificationCenter
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        networkingController.notificationCenter = NotificationCenter.default
        super.tearDown()
    }
    
    //where the actual test assert takes place
    func testPostAlertNotifcation(){
        networkingController.postAlertNotification()
        XCTAssertTrue(mockNotificationCenter.didReceiveUserDataNotification,"USerDatAlert notification NOT sent")
    }
    
    
    
    class MockNotificationCenter: NotificationCenter {
        
        var didReceiveUserDataNotification = false
        
        override func post(name aName: NSNotification.Name, object anObject: Any?) {
            
            if aName == NSNotification.Name(rawValue:"UserDataAlert") {
                
                didReceiveUserDataNotification = true
        }
        }
    }
    
}
