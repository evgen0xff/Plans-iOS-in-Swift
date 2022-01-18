//
//  ResetPasswordVC.swift
//  Plans
//
//  Created by Star on 1/30/21.
//

import UIKit
import MaterialComponents

class ResetPasswordVC: AuthBaseVC {

    // MARK: - IBOutlets

    @IBOutlet weak var btnPhone: UIButton!
    @IBOutlet weak var btnEmail: UIButton!
    
    @IBOutlet weak var viewEmail: UIView!
    @IBOutlet weak var txtfEmail: MDCTextField!
    
    @IBOutlet weak var viewMobile: UIView!
    @IBOutlet weak var lblCountryCode: UILabel!
    @IBOutlet weak var txtfMobile: UITextField!
    
    @IBOutlet weak var btnSendVerificationCode: UIButton!
    @IBOutlet weak var maginBottonSendBtn: NSLayoutConstraint!
    
    // MARK: - Properties
    var imgViewCheckMark: UIImageView?
    var controllersTextField = [MDCTextInputControllerUnderline]()

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
        btnPhone.isSelected = true
        btnEmail.isSelected = false
        setupTextFields()
        updateUI()
    }
    
    override func willShowKeyboard(frame: CGRect) {
        super.willShowKeyboard(frame: frame)
        maginBottonSendBtn.constant = frame.height + 16.0
    }
    
    override func willHideKeyboard() {
        super.willHideKeyboard()
        maginBottonSendBtn.constant = 16.0
    }

    private func setupTextFields() {
        // Email
        txtfEmail.delegate = self
        txtfEmail.placeholder = "Email"
        txtfEmail.addCheckMark(imgCheck: "ic_check_circle_white")
        txtfEmail.addClearBtn(image: "ic_x_white")
        
        // Mobile
        txtfMobile.delegate = self
        txtfMobile.attributedPlaceholder = NSAttributedString(string: "000-000-0000",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])

        // Apply the app scheme to TextFields
        controllersTextField.append(MDCTextInputControllerUnderline(textInput: txtfEmail))

        controllersTextField.forEach { (item) in
            item.textInput?.textColor = .white
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.whiteTextField)
        }
    }
    
    private func updateUI() {
        var isActive = false
        if btnPhone.isSelected == true {
            btnPhone.setTitleColor(.white, for: .normal)
            btnEmail.setTitleColor(AppColor.whiteOpacity50, for: .normal)
            viewMobile.isHidden = false
            viewEmail.isHidden = true
            
            txtfMobile.text = txtfMobile.text?.formatPhoneNumber(maxLength: maxLength)
            lblCountryCode.text = "\(strISOCode) \(strCountryCode)"
            let text = txtfMobile.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "") ?? ""
            isActive = (text.count >= minLength) && (text.count <= maxLength)

        }else if btnEmail.isSelected == true {
            btnEmail.setTitleColor(.white, for: .normal)
            btnPhone.setTitleColor(AppColor.whiteOpacity50, for: .normal)
            viewMobile.isHidden = true
            viewEmail.isHidden = false

            let email = txtfEmail.text?.trimmingCharacters(in: .whitespaces)
            isActive = email?.isValidEmail() ?? false
            txtfEmail.trailingViewMode = isActive ? .always : .never
        }
        
        btnSendVerificationCode.updateActive(isActive)
    }
    

    @IBAction func actionBackBtn(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionPhoneBtn(_ sender: Any) {
        view.endEditing(true)
        btnPhone.isSelected = true
        btnEmail.isSelected = false
        updateUI()
    }
    
    @IBAction func actionEmailBtn(_ sender: Any) {
        view.endEditing(true)
        btnEmail.isSelected = true
        btnPhone.isSelected = false
        updateUI()
    }
    
    @IBAction func actionChangedEmail(_ sender: UITextField) {
        updateUI()
    }

    @IBAction func actionChangedMobile(_ sender: UITextField) {
        updateUI()
    }

    @IBAction func actionCountryCode(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushPinCodeVC(delegate: self, sender: self)
    }
    
    @IBAction func actionSendVerificationCode(_ sender: Any) {
        view.endEditing(true)
        userModel?.mobile = nil
        userModel?.email = nil
        userModel?.otp = nil
        userModel?.communicationType = nil
        userModel?.isCreateAccount = "false"

        if btnPhone.isSelected == true {
            let number = txtfMobile.text?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "") ?? ""
            let mobile = strCountryCode + number
            userModel?.mobile = mobile
            userModel?.communicationType = "true"
        }else if btnEmail.isSelected == true {
            userModel?.email = txtfEmail.text?.trimmingCharacters(in: .whitespaces)
            userModel?.communicationType = "false"
        }
        
        if userModel?.communicationType != nil {
            hitSaveOtpApi(userModel)
        }
    }
    
}

// MARK: - UITextFieldDelegate
extension ResetPasswordVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - PinCodeVCDelegate
extension ResetPasswordVC: PinCodeVCDelegate {
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
extension ResetPasswordVC {
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



