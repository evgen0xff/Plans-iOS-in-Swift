//
//  NewPasswordVC.swift
//  Plans
//
//  Created by Star on 1/30/21.
//

import UIKit
import MaterialComponents

class NewPasswordVC: AuthBaseVC {
    // MARK: - IBOutlets

    @IBOutlet weak var txtfNewPass: MDCTextField!
    @IBOutlet weak var txtfConfrimPassword: MDCTextField!
    @IBOutlet weak var btnChangePass: UIButton!

    @IBOutlet weak var marginBottomChangeBtn: NSLayoutConstraint!
    // MARK: - Properties
    var btnShowHiddenNew: UIButton?
    var btnShowHiddenConfrim: UIButton?
    var controllersTextField = [MDCTextInputControllerUnderline]()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        marginBottomChangeBtn.constant = frame.height + 16.0
    }
    
    override func willHideKeyboard() {
        super.willHideKeyboard()
        marginBottomChangeBtn.constant = 16.0
    }

    
    private func setupTextFields() {
        // Email
        txtfNewPass.delegate = self
        txtfNewPass.placeholder = "New Password"
        txtfNewPass.addShowHideForSecureText()

        // Password
        txtfConfrimPassword.delegate = self
        txtfConfrimPassword.placeholder = "Confirm New Password"
        txtfConfrimPassword.addShowHideForSecureText()

        // Apply the app scheme to TextFields
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfNewPass))
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfConfrimPassword))

        controllersTextField.forEach { (item) in
            item.textInput?.textColor = .white
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.whiteTextField)
        }
    }

    private func updateUI() {
        let new = txtfNewPass.text?.trimmingCharacters(in: .whitespaces)
        let confirm = txtfConfrimPassword.text?.trimmingCharacters(in: .whitespaces)
        
        if new?.isValidPasssword() == true,
           confirm?.isValidPasssword() == true,
           new == confirm {
            btnChangePass.updateActive(true)
            userModel?.password = new
        }else {
            btnChangePass.updateActive(false)
        }

    }

    
    // MARK: - User Action Handlers

    @IBAction func actionBack(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangePassword(_ sender: UIButton) {
        view.endEditing(true)
        hitChangePasswordApi(userModel)
    }
    
    @IBAction func actionChangedNewPassword(_ sender: UITextField) {
        updateUI()
    }
    
    @IBAction func actionChangedConfirmPassword(_ sender: UITextField) {
        updateUI()
    }

}

extension NewPasswordVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtfNewPass {
            txtfConfrimPassword.becomeFirstResponder()
        }else {
            view.endEditing(true)
        }
        return true
    }
}



// MARK: - Backend API
extension NewPasswordVC {
    func hitChangePasswordApi(_ userModel : UserModel?){
        
        guard let userModel = userModel else { return }
        
        var email = ""
        var mobile = ""
        
        if let emailAddress = userModel.email {
            email  = emailAddress
        }
        
        if let mobileNo = userModel.mobile {
            mobile = mobileNo
        }
        
        let dictParam = [kMobile : mobile,
                         kEmail : email,
                         kPassword : userModel.password ?? "",
                         kConfirmPassword : userModel.password ?? ""]
        
        showLoader()
        USER_SERVICE.hitChangePasswordUserApi(dictParam, true).done { (userResponse) -> Void in
            self.hideLoaderAfter(ConstantTexts.passwordUpdated.localizedString, completion: {
                APP_MANAGER.gotoLandingVC()
            })
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}
