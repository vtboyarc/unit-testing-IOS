//
//  CashPortStubs.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//


import XCTest
@testable import CashPort

//Stubs are a replacement for a dependency in the code. Acts in place of a data source
class CashPortStubs: XCTestCase {
    
    var mockNetworkingController = MockNetworkingController()
    //creating an instance of the ViewController
    var viewController = ViewController()
    
    override func setUp() {
        super.setUp()
        viewController.networkingController = mockNetworkingController
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        viewController.networkingController = NetworkingController()
        super.tearDown()
    }
    
    func testFormatMovers(){
        //formatMovers is a function in the ViewController
        let moverString = viewController.formatMovers()
        
        XCTAssert(moverString == "ABC: 2.0 - 1.0  XYZ: 3.0 - 2.0  ", "MoverString is NOT formatting correctly")
    }
    
    //Stubbing out the data
    class MockNetworkingController: NetworkingController{
        //overriding method so we can stub out our own data, that we want to return
        //make sure it has the same structure as the orginal method we are testing
        //this works because we have the mock instance setup in the setUp method
        override func downloadMovers() -> [[String : String]] {
            return [["Code" : "ABC", "High" : "2.0", "Low" : "1.0"], ["Code" : "XYZ", "High" : "3.0", "Low" : "2.0"]]
        }
        
    }
    
}
