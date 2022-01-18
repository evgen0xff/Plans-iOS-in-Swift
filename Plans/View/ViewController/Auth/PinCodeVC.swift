//
//  PinCodeVC.swift
//  Plans
//
//  Created by Star on 01/25/21.
//  Copyright © 2021 Plans Collective LLC. All rights reserved.
//

import UIKit

protocol PinCodeVCDelegate {
    func didSelectedPinCode (dicPinCode: [String: Any]?)
}

extension PinCodeVCDelegate {
    func didSelectedPinCode (dicPinCode: [String: Any]?){}
}

class PinCodeVC: BaseViewController {

    // MARK: - IBoutlets
    
    @IBOutlet weak var txtfSearch: UITextField!
    @IBOutlet weak var tableV: UITableView!
    
    // MARK: - Properties
    var delegate : PinCodeVCDelegate?
    var dataArray = NSMutableArray()
    var dataSearchArray = NSMutableArray()
    var controller: AnyObject!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Search Bar UI Modifications
    override func initializeData() {
        let countryHandler: CountryHandler = CountryHandler()
        var arr: NSMutableArray = NSMutableArray()
        arr = countryHandler.fetchCountry()
        dataArray = arr
        dataSearchArray = arr
    }
    
    override func setupUI() {
        txtfSearch.delegate = self
        txtfSearch.attributedPlaceholder = NSAttributedString(string: "Search",
                                                                   attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        tableV.reloadData()
    }
        
    // MARK: - Search Bar Method
    
    private func searchText() {
        if txtfSearch.text != ""
        {
            let pred: NSPredicate = NSPredicate(format: "CountryEnglishName CONTAINS[cd] %@", txtfSearch.text!)
            let filteredVisitors = NSMutableArray(array: dataArray.filtered(using: pred))
            dataSearchArray =  filteredVisitors
        }
        else {
            dataSearchArray = dataArray
        }
        tableV.reloadData()
    }
    
    // MARK: - User Actions

    @IBAction func back_Btn(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangedSearch(_ sender: UITextField) {
        searchText()
    }

}

// MARK: - UITextFieldDelegate
extension PinCodeVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - Table View Datasource

extension PinCodeVC : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSearchArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countryCell", for: indexPath)
        let dict: [String : AnyObject] = dataSearchArray[indexPath.row] as! [String : AnyObject]
        (cell.viewWithTag(100) as? UILabel)?.text = dict["CountryEnglishName"] as? String
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - Table View Delegates

extension PinCodeVC : UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        view.endEditing(true)
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        delegate?.didSelectedPinCode(dicPinCode: dataSearchArray[indexPath.row] as? [String: Any])
        navigationController?.popViewController(animated: true)
    }
}
