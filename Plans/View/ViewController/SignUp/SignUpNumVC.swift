//
//  SignUpNumVC.swift
//  Plans
//
//  Created by Star on 1/30/21.
//

import UIKit
import MaterialComponents

class SignUpNumVC: AuthBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var lblCountryCode: UILabel!
    @IBOutlet weak var txtfMobile: UITextField!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var marginBottomContinueBtn: NSLayoutConstraint!
    
    // MARK: - Properties
    var maxLength = 10
    var minLength = 10
    var strCountryCode = "+1"
    var strISOCode = "US"

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
        // Mobile
        txtfMobile.delegate = self
        txtfMobile.attributedPlaceholder = NSAttributedString(string: "000-000-0000",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])

    }
    
    private func updateUI() {
        txtfMobile.text = txtfMobile.text?.formatPhoneNumber(maxLength: maxLength)
        lblCountryCode.text = "\(strISOCode) \(strCountryCode)"
        let text = txtfMobile.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "") ?? ""
        let isActive = (text.count >= minLength) && (text.count <= maxLength)

        btnContinue.updateActive(isActive)
    }
    

    @IBAction func actionBackBtn(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangedMobile(_ sender: UITextField) {
        updateUI()
    }

    @IBAction func actionCountryCode(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushPinCodeVC(delegate: self, sender: self)
    }
    
    @IBAction func actionContinueBtn(_ sender: Any) {
        view.endEditing(true)
        userModel?.isCreateAccount = "true"
        userModel?.communicationType = "true"

        let number = txtfMobile.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "") ?? ""
        let mobile = strCountryCode + number
        userModel?.mobile = mobile
        
        hitSaveOtpApi(userModel)
    }
    
}

// MARK: - UITextFieldDelegate
extension SignUpNumVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - PinCodeVCDelegate
extension SignUpNumVC: PinCodeVCDelegate {
    func didSelectedPinCode(dicPinCode: [String : Any]?) {
        guard let dict = dicPinCode else { return }
        if dict.count>0 {
            if let strName = dict["ISOCode"] as? String,
                let strCode = dict["CountryCode"] as? String,
                let Max_NSN = dict["Max_NSN"] as? Int,
                let Min_NSN = dict["Min_NSN"] as? Int
            {
                    maxLength = Max_NSN
                    minLength = Min_NSN
                    strISOCode = strName
                    strCountryCode = strCode
                    updateUI()
            }
        }

    }
}

// MARK: - Backend API
extension SignUpNumVC {
    func hitSaveOtpApi(_ userModel : UserModel?) {
        guard let userModel = userModel else { return }
        showLoader()
        USER_SERVICE.hitSaveOtpApi(userModel.toJSON()).done { (userResponse) -> Void in
            if let otp = userResponse.otp {
                self.hideLoaderAfter(ConstantTexts.verificationCodeSent.localizedString, completion: {
                    userModel.otp = otp
                    APP_MANAGER.pushConfirmCodeVC(userModel: userModel, sender: self)
                })
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}




