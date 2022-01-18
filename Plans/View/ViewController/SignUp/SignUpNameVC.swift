//
//  SignUpNameVC.swift
//  Plans
//
//  Created by Star on 1/25/21.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import MaterialComponents


class SignUpNameVC: AuthBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var txtfFirstName: MDCTextField!
    @IBOutlet weak var txtfLastName: MDCTextField!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var marginBottomContinueBtn: NSLayoutConstraint!
    
    // MARK: - Properties
    var controllersTextField = [MDCTextInputControllerUnderline]()

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Private Methods
    override func initializeData() {
        userModel = userModel ?? UserModel()
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
        // First Name
        txtfFirstName.delegate = self
        txtfFirstName.placeholder = "First Name"
        txtfFirstName.text = userModel?.firstName

        // Last Name
        txtfLastName.delegate = self
        txtfLastName.placeholder = "Last Name"
        txtfLastName.clearButton.tintColor = .white
        txtfLastName.text = userModel?.lastName

        // Apply the app scheme to TextFields
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfFirstName))
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfLastName))

        controllersTextField.forEach { (item) in
            item.textInput?.textColor = .white
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.whiteTextField)
            item.textInput?.addClearBtn(image: "ic_x_white")

        }
    }
    
    private func updateUI() {
        btnContinue.updateActive(isValid())
    }
    
    private func isValid () -> Bool {
        var result = false
        let first = txtfFirstName.text?.trimmingCharacters(in: .whitespaces)
        let last = txtfLastName.text?.trimmingCharacters(in: .whitespaces)
        if first?.isValidUsername() == true,
           last?.isValidUsername() == true {
            result = true
        }
        return result
    }

    
    // MARK: - User Action Handlers

    @IBAction func actionBack(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionContinue(_ sender: UIButton) {
        view.endEditing(true)
        if isValid() == true {
            userModel?.firstName = txtfFirstName.text?.trimmingCharacters(in: .whitespaces)
            userModel?.lastName = txtfLastName.text?.trimmingCharacters(in: .whitespaces)
            APP_MANAGER.pushNextStepForSignUp(userModel, skipMode:isSkipMode, sender: self)
        }
    }
    
    @IBAction func actionChangedFirstName(_ sender: UITextField) {
        updateUI()
    }
    
    @IBAction func actionChangedLastName(_ sender: UITextField) {
        updateUI()
    }

}

extension SignUpNameVC : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var result = true

        let currLength = textField.text?.count ?? 0
        let newLength = currLength + string.count - range.length
        
        if range.length > 0 {
            return true
        }

        switch textField {
        case txtfFirstName, txtfLastName:
            if newLength > 50 {
                result = false
            }
            break
        default:
            break
        }

        return result
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtfFirstName {
            txtfLastName.becomeFirstResponder()
        }else {
            view.endEditing(true)
        }
        return true
    }
}

