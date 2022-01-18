//
//  SignUpPasswordVC.swift
//  Plans
//
//  Created by Star on 1/30/21.
//

import UIKit
import MaterialComponents

class SignUpPasswordVC: AuthBaseVC {
    // MARK: - IBOutlets

    @IBOutlet weak var txtfPassword: MDCTextField!
    @IBOutlet weak var btnCreateAccount: UIButton!
    @IBOutlet weak var marginBottomContinueBtn: NSLayoutConstraint!

    // MARK: - Properties
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
        marginBottomContinueBtn.constant = frame.height + 16.0
    }

    override func willHideKeyboard() {
        super.willHideKeyboard()
        marginBottomContinueBtn.constant = 16.0
    }

    
    private func setupTextFields() {
        // Password
        txtfPassword.delegate = self
        txtfPassword.placeholder = "Password"
        txtfPassword.addShowHideForSecureText()

        // Apply the app scheme to TextFields
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfPassword))

        controllersTextField.forEach { (item) in
            item.textInput?.textColor = .white
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.whiteTextField)
        }
    }

    private func updateUI() {
        let password = txtfPassword.text?.trimmingCharacters(in: .whitespaces)
        
        if password?.isValidPasssword() == true {
            btnCreateAccount.updateActive(true)
        }else {
            btnCreateAccount.updateActive(false)
        }

    }

    
    // MARK: - User Action Handlers

    @IBAction func actionBack(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangedPassword(_ sender: UITextField) {
        updateUI()
    }
    
    @IBAction func actionTerms(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushTermsOfServices()
    }
    
    @IBAction func actionPrivacy(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushPrivacyPolicy()
    }
    
    @IBAction func actionCreateAccount(_ sender: UIButton) {
        view.endEditing(true)
        userModel?.password = txtfPassword.text?.trimmingCharacters(in: .whitespaces)
        hitCreateAccountApi(userModel)
    }

}

extension SignUpPasswordVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}



// MARK: - Backend API
extension SignUpPasswordVC {

    func hitCreateAccountApi(_ userModel : UserModel?)
    {
        guard let userModel = userModel else { return }
        
        let latitude = LOCATION_MANAGER.currentLocation.coordinate.latitude
        let longitude = LOCATION_MANAGER.currentLocation.coordinate.longitude
        userModel.lat = latitude
        userModel.long = longitude
        
        showLoader()
        userModel.fcmId = USER_MANAGER.deviceToken
        userModel.userLocation = LOCATION_MANAGER.city_CounAddress
        
        USER_SERVICE.hitCreateUserApi(userModel.toJSON()).done { (userResponse) -> Void in
            if let accessToken = userResponse.accessToken {
                USER_MANAGER.initForLogin(userModel: userResponse, token: accessToken)
                ANALYTICS_MANAGER.logEvent(.sign_up, itemID: USER_MANAGER.userId)
                if USER_MANAGER.isClickedByAppLink == true {
                    ANALYTICS_MANAGER.logEvent(.invite_link, itemID: USER_MANAGER.userId)
                }
                self.hideLoaderAfter(ConstantTexts.accountCreated.localizedString, completion: {
                    APP_MANAGER.pushNextStepForSignUp(userModel, skipMode: self.isSkipMode, sender: self)
                })
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}
