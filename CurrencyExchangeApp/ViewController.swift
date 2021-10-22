//
//  ViewController.swift
//  CurrencyExchangeApp
//
//  Created by Yinxing Gao on 10/21/21.
//

import UIKit
import SwiftyJSON
import SwiftSpinner
import Alamofire
import PromiseKit

class ViewController: UIViewController {

    var currencies = ["USD", "CNY", "EUR", "GBP", "CAD", "AUD", "KRW", "JPY"]
    var fromCurrency: String = "USD"
    var toCurrency: String = "CNY"
    let baseURL = "http://api.exchangeratesapi.io/v1/"
    let apiKey = "515b5c9d119e2c45e0fb33bc11b707e8"
    
    @IBOutlet weak var fromPicker: UIPickerView!
    @IBOutlet weak var toPicker: UIPickerView!
    @IBOutlet weak var ConvertDetails: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fromPicker.dataSource = self
        fromPicker.delegate = self
        toPicker.dataSource = self
        toPicker.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getCurrencyOnline()
            .done { getCurrencyOnline in
                self.currencies = getCurrencyOnline
                self.fromPicker.reloadAllComponents()
                self.toPicker.reloadAllComponents()
                
                if let fromIdx = self.currencies.firstIndex(of: self.fromCurrency) {
                    self.fromPicker.selectRow(fromIdx, inComponent:0, animated:false)
                }
                if let toIdx = self.currencies.firstIndex(of: self.toCurrency) {
                    self.toPicker.selectRow(toIdx, inComponent:0, animated:false)
                }
            }
            .catch { _ in
                self.fromPicker.selectRow(0, inComponent:0, animated:true)
                self.toPicker.selectRow(0, inComponent:0, animated:true)
            }
    }
    
    func getCurrencyOnline() -> Promise<Array<String>>{
        
        return Promise<Array<String>>{seal -> Void in
            let url = baseURL + "symbols" + "?access_key=" + apiKey
            
            AF.request(url).responseJSON{ response in
                switch response.result {
                case .success(let pass):
                    let currencies = JSON(pass)["symbols"].dictionaryValue.keys.sorted()
                    seal.fulfill(currencies)
                case .failure(let error):
                    print(error)
                    seal.reject(error)
                }
            }
        }
    }
    
    func submitButton(_ fromCurrency: String, _ toCurrency: String) -> Promise<(Float,Float)>{
        
        return Promise<(Float,Float)>{seal -> Void in
            
            let url = baseURL + "latest" + "?access_key=" + apiKey + "&symbols=" + fromCurrency + "," + toCurrency
            
            AF.request(url).responseJSON { response in
                switch response.result {
                case .success(let pass):
                    let rates = JSON(pass)["rates"]
                    let fromCurrencyRate = rates[fromCurrency].floatValue
                    let toCurrencyRate = rates[toCurrency].floatValue
                    seal.fulfill((fromCurrencyRate, toCurrencyRate))
                    
                case .failure(let error):
                    print("error")
                    seal.reject(error)
                }
            }
        }
    }
    
    
    @IBAction func submitButton(_ sender: Any) {
        submitButton(fromCurrency, toCurrency)
            .done { fromCurrencyRate, toCurrencyRate in
                self.ConvertDetails.text = "1 \(self.fromCurrency) = \(toCurrencyRate/fromCurrencyRate) \(self.toCurrency)"
            }
            .catch { error in
                print(error)
            }
    }
}

extension ViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
}

extension ViewController: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == fromPicker {
            self.fromCurrency = self.currencies[row]
        } else if pickerView == toPicker {
            self.toCurrency = self.currencies[row]
        }
    }
}
