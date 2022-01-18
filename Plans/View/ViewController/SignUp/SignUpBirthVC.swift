//
//  SignUpBirthVC.swift
//  Plans
//
//  Created by Star on 1/25/21.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import MaterialComponents


class SignUpBirthVC: AuthBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var txtfMonth: UITextField!
    @IBOutlet weak var txtfDay: UITextField!
    @IBOutlet weak var txtfYear: UITextField!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var marginBottomContinueBtn: NSLayoutConstraint!

    
    // MARK: - Properties
    var dateSelected: Date?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Private Methods
    override func initializeData() {
        userModel = userModel ?? UserModel()
        if let dob = userModel?.dob {
            dateSelected = Date(timeIntervalSince1970: dob)
        }
    }
    
    override func setupUI() {
        setupTextFields()
        updateUI()
    }
    
    override func willShowKeyboard(frame: CGRect) {
        super.willShowKeyboard(frame: frame)
        marginBottomContinueBtn.constant = frame.height + 16.0
    }

    override func willHideKeyboard() {
        super.willHideKeyboard()
        marginBottomContinueBtn.constant = 16.0
    }

    
    private func setupTextFields() {
        txtfMonth.delegate = self
        txtfDay.delegate = self
        txtfYear.delegate = self
        
        txtfMonth.attributedPlaceholder = NSAttributedString(string: "MM",
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txtfDay.attributedPlaceholder = NSAttributedString(string: "DD",
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txtfYear.attributedPlaceholder = NSAttributedString(string: "YYYY",
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txtfMonth.inputView = DATE_PICKER
        txtfDay.inputView = DATE_PICKER
        txtfYear.inputView = DATE_PICKER
        DATE_PICKER.delegate = self
        DATE_PICKER.datePickerMode = .date

        txtfMonth.clearButtonMode = .never
        txtfDay.clearButtonMode = .never
        txtfYear.clearButtonMode = .never
    }
    
    private func updateBirthdayUI() {
        txtfMonth.text = dateSelected?.dateStringWith(strFormat: "MM")
        txtfDay.text = dateSelected?.dateStringWith(strFormat: "dd")
        txtfYear.text = dateSelected?.dateStringWith(strFormat: "yyyy")
    }
    
    private func updateUI() {
        let valid = isValid()
        updateBirthdayUI()
        btnContinue.updateActive(valid)
    }
    
    private func isValid () -> Bool {
        var result = false
        if let date = dateSelected, date <= Date().agoYears(years: 13).date(month: 12, day: 31) {
            result = true
        }
        return result
    }
    
    func sycDatePickerWith(textField: UITextField) {
        switch textField {
        case txtfMonth, txtfDay, txtfYear:
            let maxDate = Date().agoYears(years: 13)
            DATE_PICKER.date = dateSelected ?? maxDate
            DATE_PICKER.maximumDate = maxDate.date(month: 12, day: 31)
            break
        default:
            break
        }
    }

    
    // MARK: - User Action Handlers

    @IBAction func actionBack(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionContinue(_ sender: UIButton) {
        view.endEditing(true)
        if isValid() == true {
            userModel?.dob = dateSelected?.timeIntervalSince1970
            APP_MANAGER.pushNextStepForSignUp(userModel, skipMode:isSkipMode, sender: self)
        }
    }

}

// MARK: - UITextFieldDelegate
extension SignUpBirthVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case txtfMonth:
            txtfDay.becomeFirstResponder()
            break
        case txtfDay:
            txtfYear.becomeFirstResponder()
            break
        case txtfYear:
            view.endEditing(true)
            break
        default:
            view.endEditing(true)
            break
        }

        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        sycDatePickerWith(textField: textField)
        return true
    }

}

// MARK: - DatePickerViewDelegate

extension SignUpBirthVC: DatePickerViewDelegate {
    func datePickerView(_ pickerView: UIView, didDone selectedDate: Date) {
        view.endEditing(true)
        dateSelected = selectedDate
        updateUI()
    }

    func datePickerView(_ pickerView: UIView, didCancel selectedDate: Date) {
        view.endEditing(true)
    }

}


