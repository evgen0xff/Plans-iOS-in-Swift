//
//  SignUpEmailVC.swift
//  Plans
//
//  Created by Star on 1/25/21.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import MaterialComponents


class SignUpEmailVC: AuthBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var txtfEmail: MDCTextField!
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
        // Email
        txtfEmail.delegate = self
        txtfEmail.placeholder = "Email"
        txtfEmail.addCheckMark(imgCheck: "ic_check_circle_white")
        txtfEmail.text = userModel?.email

        // Apply the app scheme to TextFields
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfEmail))

        controllersTextField.forEach { (item) in
            item.textInput?.textColor = .white
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.whiteTextField)
            item.textInput?.addClearBtn(image: "ic_x_white")
        }
    }
    
    private func updateUI() {
        let valid = isValid()
        txtfEmail.trailingViewMode = valid ? .always : .never
        btnContinue.updateActive(valid)
    }
    
    private func isValid () -> Bool {
        var result = false
        let email = txtfEmail.text?.trimmingCharacters(in: .whitespaces)
        if email?.isValidEmail() == true {
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
            userModel?.email = txtfEmail.text?.trimmingCharacters(in: .whitespaces)
            hitVerifyEmailApi(model: userModel)
        }
    }
    
    @IBAction func actionChangedEmail(_ sender: UITextField) {
        updateUI()
    }

}

// MARK: - UITextFieldDelegate
extension SignUpEmailVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - BackEnd API

extension SignUpEmailVC
{
    func hitVerifyEmailApi(model : UserModel?) {
        guard let email = model?.email else { return }
        
        let dict = ["email" : email] as [String : Any]
        showLoader()
        USER_SERVICE.hitVerifyEmailApi(dict).done { (userResponse) -> Void in
            self.hideLoader()
            APP_MANAGER.pushNextStepForSignUp(model, skipMode: self.isSkipMode, sender: self)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

