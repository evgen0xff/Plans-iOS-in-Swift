//
//  LoginVC.swift
//  Plans
//
//  Created by Star on 1/25/21.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import MaterialComponents


class LoginVC: AuthBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var txtfEmail: MDCTextField!
    @IBOutlet weak var txtfPassword: MDCTextField!
    @IBOutlet weak var btnForgotPassword: UIButton!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var maginBottomLoginBtn: NSLayoutConstraint!
    
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
        maginBottomLoginBtn.constant = frame.height + 16.0
    }
    
    override func willHideKeyboard() {
        super.willHideKeyboard()
        maginBottomLoginBtn.constant = 16.0
    }
    
    private func setupTextFields() {
        // Email
        txtfEmail.delegate = self
        txtfEmail.placeholder = "Email"
        txtfEmail.addCheckMark(imgCheck: "ic_check_circle_white")
        txtfEmail.addClearBtn(image: "ic_x_white")
        
        // Password
        txtfPassword.delegate = self
        txtfPassword.placeholder = "Password"
        txtfPassword.addShowHideForSecureText()

        // Apply the app scheme to TextFields
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfEmail))
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfPassword))

        controllersTextField.forEach { (item) in
            item.textInput?.textColor = .white
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.whiteTextField)
        }
    }

    private func updateUI() {
        btnLogin.updateActive(isValid())
    }
    
    private func isValid() -> Bool {
        var result = true

        let email = txtfEmail.text?.trimmingCharacters(in: .whitespaces)
        let password = txtfPassword.text?.trimmingCharacters(in: .whitespaces)

        result = email?.isValidEmail() ?? false
        txtfEmail.trailingViewMode = result == true ? .always : .never

        if password?.isValidPasssword() == false {
            result = false
        }

        if result == true {
            userModel?.email = email
            userModel?.password = password
        }


        return result
    }

    
    // MARK: - User Action Handlers

    @IBAction func actionBack(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionForgotPassword(_ sender: UIButton) {
        view.endEditing(true)
        APP_MANAGER.pushResetPassword()
    }
    
    @IBAction func actionLogin(_ sender: UIButton) {
        view.endEditing(true)
        hitLoginApi(userModel)
    }
    
    @IBAction func actionChangedEmail(_ sender: UITextField) {
        updateUI()
    }
    
    @IBAction func actionChangedPassword(_ sender: UITextField) {
        updateUI()
    }

}

extension LoginVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtfEmail {
            txtfPassword.becomeFirstResponder()
        }else {
            view.endEditing(true)
        }
        return true
    }
}



// MARK: - Backend API
extension LoginVC {
    
    func hitLoginApi(_ userModel : UserModel?) {
        guard let userModel = userModel else { return }
        
        userModel.fcmId = USER_MANAGER.deviceToken
        userModel.loginType = "true"
//        userModel.loginType = "admin"
        userModel.lat = LOCATION_MANAGER.currentLocation.coordinate.latitude
        userModel.long = LOCATION_MANAGER.currentLocation.coordinate.longitude

        showLoader()
        USER_SERVICE.hitLogInUserApi(userModel.toJSON()).done { (userResponse) -> Void in
            
            if let userProfile = userResponse.userProfile,
                let accessToken = userResponse.accessToken {
                USER_MANAGER.initForLogin(userModel: userProfile, token: accessToken)
                ANALYTICS_MANAGER.logEvent(.login, itemID: USER_MANAGER.userId)
            }
            self.hideLoaderAfter(ConstantTexts.signInSuccessfully.localizedString, completion: {
                APP_MANAGER.startHomeVC()
            })
            
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}
