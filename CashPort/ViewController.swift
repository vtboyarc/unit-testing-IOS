//
//  ViewController.swift
//  CashPort
//
//  Created by Adam Carter on 4/20/17.
//


import Foundation
import UIKit
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var fromAmountField: UITextField!
    @IBOutlet weak var fromNameLabel: UILabel!
    @IBOutlet weak var toNameLabel: UILabel!
    @IBOutlet weak var toAmountLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    
    //Initial values set to negatives for ease in debugging and validation checks
    var fromRate: Double = -99.9
    var toRate: Double = -99.9
    
    var networkingController = NetworkingController()
    var currencyArray: [Currency] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(userDataAlert), name: NSNotification.Name(rawValue: "UserDataAlert"), object: nil)
        self.pickerView.delegate = self
        addDoneButtonOnKeyboard()
        formatMovers()
        reloadAll()
    }
    
    @IBAction func setFromCurrency(){
        //Set FROM currency in UI, conversion calculator and saved favorite
        self.fromNameLabel.text = self.currencyArray[self.pickerView.selectedRow(inComponent: 0)].pickerName
        self.fromRate = Double(self.currencyArray[self.pickerView.selectedRow(inComponent: 0)].usdRate!)
        DataController.sharedInstance.setCurrentFavorite(true, currency:self.currencyArray[self.pickerView.selectedRow(inComponent: 0)])
        
    }
    
    @IBAction func setToCurrency(){
        //Set TO currency in UI, conversion calculator and saved favorite
        self.toNameLabel.text = self.currencyArray[self.pickerView.selectedRow(inComponent: 0)].pickerName
        self.toRate = Double(self.currencyArray[self.pickerView.selectedRow(inComponent: 0)].usdRate!)
        DataController.sharedInstance.setCurrentFavorite(false, currency:self.currencyArray[self.pickerView.selectedRow(inComponent: 0)])
    }
    
    @IBAction func convertCurrency(){
        let isValid = inputValidation()
        //If inputs are valid procede with conversion, if not return early
        if !isValid {
            return
        }
        let fromAmount = Double(self.fromAmountField.text!)
        let toAmount = ((self.toRate / self.fromRate) * fromAmount!)
        self.toAmountLabel.text = String(format: "%.2f", toAmount)
    }
    
    @IBAction func reloadAll(){
        showLoadingScreen()
        refreshDataAndUI(){_ in
            self.currencyArray = DataController.sharedInstance.getAllCurrencies()
        }
    }
    
    func setLastUpdatedLabel(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm aa"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        self.lastUpdatedLabel.text = "   Last Updated:\n   \(dateString)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func refreshDataAndUI(_ completion: @escaping  (_ result: String) -> Void){
        //Pull data from endpoints, create new set of CoreData currency entities, assign rates, trigger UI refreshes and hide loadingScreen
        
        self.networkingController.downladFullNames(){_ in 
            self.networkingController.downladExchangeRates(){
                _ in
                DispatchQueue.main.async {
                    self.pickerView.reloadAllComponents()
                    self.setDefaultCurrencies()
                    self.hideLoadingScreen()
                    self.setLastUpdatedLabel()
                }
            completion("completed")
            }
            completion("completed")
            }
    }
    
    func setDefaultCurrencies(){
        //Check for lone "Favorite", which is updated after every new TO or FROM currency is set
        //Current architecture can be extended to handle a list of favorites with minor changes
        
        var currentFavorites: [Favorite] = DataController.sharedInstance.getAllFavorites()
        if currentFavorites.count == 1 {
            //Only set default if exactly one favorite exists, otherwise do not prepopulate fields
            
            let currentFavorite: Favorite = currentFavorites[0]
            if currentFavorite.codeFROM != nil {
                //Fetch FROM currency based on code and fullName match - uses a combination of currency code and full name to eliminate the chance of displaying an incorrect currency or mismatched rate given code/name changes from the API since last session
                
                if let fromCurrency =  DataController.sharedInstance.getCurrencyByCodeFullName(currentFavorite.codeFROM!, fullName: currentFavorite.fullNameFROM!){
                    //set FROM currency
                    self.fromNameLabel.text = fromCurrency.pickerName
                    self.fromRate = Double(fromCurrency.usdRate!)
                }
            }
            if currentFavorite.codeTO != nil {
                //fetch TO currency based on code and fullName match - uses a combination of currency code and full name, to eliminate the chances of displaying a currency where the API code has changed
                
                if let toCurrency =  DataController.sharedInstance.getCurrencyByCodeFullName(currentFavorite.codeTO!, fullName: currentFavorite.fullNameTO!){
                    //set TO currency
                    self.toNameLabel.text = toCurrency.pickerName
                    self.toRate = Double(toCurrency.usdRate!)
                }
            }
        }
    }
    
    func inputValidation() -> Bool{
        //Check for valid inputs, display custom alerts
        let alert = UIAlertController(title: nil, message: "Invalid Input", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        var message = "Invalid Input"
        var invalidCount = 0
        
        //Alerts for single invalid inputs
        if self.fromRate <= 0 {
            invalidCount += 1
            message = "Please select a 'FROM' currency"
        }
        if self.toRate <= 0 {
            invalidCount += 1
            message = "Please select a 'TO' currency"
        }
        if self.toNameLabel.text == self.fromNameLabel.text {
            invalidCount += 1
            message = "It looks like your 'TO' and FROM currencies are the same."
        }
        if Double(self.fromAmountField.text!) <= 0 {
            invalidCount += 1
            message = "Please enter a valid amount (no negatives, commas or symbols"
        }
        //Alert for multiple invalid inputs
        if invalidCount > 1 {
            message = "Please enter a valid amount and select both 'TO' and 'FROM' currencies"
        }
        if invalidCount > 0 {
            alert.message = message
            present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.currencyArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        //Set custom picker style, allow for padding on left
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.text = String("   " + self.currencyArray[row].pickerName)
        pickerLabel.font = UIFont(name: "Kohinoor Bangla", size: 15)
        pickerLabel.textAlignment = NSTextAlignment.left
        return pickerLabel
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        //No need for this currenty, setTo and setFrom buttons handle the work
    }
    
    func formatMovers() -> (String){
        var moverString = ""
        
        let movers : [[String: String]] = networkingController.downloadMovers()
        
        for Array in movers{
            let code = Array["Code"]!
            let high = Array["High"]!
            let low = Array["Low"]!
            
            moverString = moverString + "\(code): \(high) - \(low)  "
        }
        return moverString
    }
    
    func showLoadingScreen() -> Void {
        self.loadingView.alpha = 1
        self.loadingView.isHidden = false
    }
    
    func hideLoadingScreen() -> Void {
        UIView.animate(withDuration: 0.75, delay: 1.0, options: UIViewAnimationOptions(), animations: {
            self.loadingView.alpha = 0},
            completion: { finished in
                    self.loadingView.isHidden = true })
    }
    
    func addDoneButtonOnKeyboard()
    {
        //Add "Done" button to default Numeric Keypad
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        navBar.barStyle = UIBarStyle.blackTranslucent;
        navBar.backgroundColor = UIColor.lightGray;
        navBar.alpha = 1.0;
        let navItem = UINavigationItem()
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.closeKeyboard))
        navItem.rightBarButtonItem = doneButton
        navBar.pushItem(navItem, animated: false)
        self.fromAmountField.inputAccessoryView = navBar        
    }
    
    func closeKeyboard()
    {
        self.fromAmountField.resignFirstResponder()
    }
    
    func userDataAlert(){
        DispatchQueue.main.async {
        let alert = UIAlertController(title: "Warning", message: "Data did not update properly. Please close and relaunch the app.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    }
}

