//
//  ChangePasswordVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit
import MaterialComponents

class ChangePasswordVC: UserBaseVC {

    // MARK: - ALL IBOutlet
    @IBOutlet weak var txtfCurrnetPassword: MDCTextField!
    @IBOutlet weak var txtfNewPassword: MDCTextField!
    @IBOutlet weak var txtfConfirmNewPassword: MDCTextField!
    @IBOutlet weak var btnSave: UIButton!

    // MARK: - All Properties
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - Private Meothds
    override func setupUI() {
        super.setupUI()
        
        txtfCurrnetPassword.delegate = self
        txtfNewPassword.delegate = self
        txtfConfirmNewPassword.delegate = self
        
        // Apply the app scheme to TextFields
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfCurrnetPassword))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfNewPassword))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfConfirmNewPassword))

        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            item.textInput?.addClearBtn(image: "ic_x_grey")
        }

        updateSaveBtn()
    }
    
    func updateSaveBtn() {
        let current = txtfCurrnetPassword.text?.trimmingCharacters(in: .whitespaces)
        let new = txtfNewPassword.text?.trimmingCharacters(in: .whitespaces)
        let confirm = txtfConfirmNewPassword.text?.trimmingCharacters(in: .whitespaces)

        btnSave.isHidden = !((current?.count ?? 0) > 7 && (new?.count ?? 0) > 7 && (confirm?.count ?? 0) > 7 )
    }


    // MARK: - User Action Handlers
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangePassword(_ sender: Any) {
        view.endEditing(true)
        if isValidData(isAlert: true) == true {
            let newPassword = txtfNewPassword.text?.trimmingCharacters(in: .whitespaces)
            let oldPassword = txtfCurrnetPassword.text?.trimmingCharacters(in: .whitespaces)
            hitChangePasswordApi(newPassword, oldPassword: oldPassword)
        }
    }

    @IBAction func actionChangedTextField(_ sender: UITextField) {
        updateSaveBtn()
    }
    
    @IBAction func actionTappedBackground(_ sender: Any) {
        view.endEditing(true)
    }
    
    func isValidData(isAlert: Bool = false) -> Bool {
        var result = true
        let current = txtfCurrnetPassword.text?.trimmingCharacters(in: .whitespaces)
        let new = txtfNewPassword.text?.trimmingCharacters(in: .whitespaces)
        let confirm = txtfConfirmNewPassword.text?.trimmingCharacters(in: .whitespaces)
        
        var msg: String? = nil
        
        if current == nil || current == ""{
            result = false
            msg = ConstantTexts.enterCurrentPasswordAlert.localizedString
        }else if current!.count < 8 {
            result = false
            msg = ConstantTexts.enterValidPasswrdAlt.localizedString
        }else if new == nil || new == ""{
            result = false
            msg = ConstantTexts.enterNewPasswordAlert.localizedString
        }else if new!.count < 8  {
            result = false
            msg = ConstantTexts.enterValidPasswrdAlt.localizedString
        }else if confirm == nil || confirm == ""{
            result = false
            msg = ConstantTexts.enterConfirmPasswordAlert.localizedString
        }else if confirm! != new! {
            result = false
            msg = ConstantTexts.passwordValidation.localizedString
        }else if new?.isValidPasssword() == false {
            result = false
            msg = ConstantTexts.enterValidNewPasswrdAlt.localizedString
        }
        
        if !result, isAlert {
            POPUP_MANAGER.makeToast(msg)
        }
        
        return result
    }

}

// MARK: - Backend API
extension ChangePasswordVC {
    
    func hitChangePasswordApi(_ password : String?, oldPassword: String?){
        guard let password = password, let oldPassword = oldPassword else { return }
        
        var email = ""
        var mobile = ""
        
        if  let mobileNumber = USER_MANAGER.mobile {
            mobile = mobileNumber
        }
        if  let emailAddress = USER_MANAGER.email {
            email = emailAddress
        }
        let dictParam = [kMobile : mobile,
                         kEmail : email,
                         kPassword : password,
                         kConfirmPassword : password,
                         "oldPassword": oldPassword]
        
        self.showLoader()
        USER_SERVICE.hitChangePasswordUserApi(dictParam, false).done { (userResponse) -> Void in
            self.hideLoader()
            self.navigationController?.popViewController(animated: true)
            POPUP_MANAGER.makeToast(ConstantTexts.passwordUpdated.localizedString)
        }.catch { (error) in
            self.hideLoader()
            let nsError = error as NSError
            POPUP_MANAGER.makeToast(nsError.userInfo["errorMessage"] as? String, target: self)
        }
    }
}

// MARK: - UITextFieldDelegate
extension ChangePasswordVC: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtfCurrnetPassword {
            txtfNewPassword.becomeFirstResponder()
        }else if textField == txtfNewPassword {
            txtfConfirmNewPassword.becomeFirstResponder()
        }else if textField == txtfConfirmNewPassword {
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = AppColor.grey_text
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
    }

    
}


