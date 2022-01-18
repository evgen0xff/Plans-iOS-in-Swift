//
//  ConfirmCode.swift
//  Plans
//
//  Created by Star on 4/20/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import SVPinView

class ConfirmCodeVC: AuthBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var viewSVPin: SVPinView!
    @IBOutlet weak var btnResendCode: UIButton!
    @IBOutlet weak var btnContinue: UIButton!
    
    @IBOutlet weak var maginBottomContinueBtn: NSLayoutConstraint!
    
    // MARK: - Properties

    // MARK: - ViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func willShowKeyboard(frame: CGRect) {
        super.willShowKeyboard(frame: frame)
        maginBottomContinueBtn.constant = frame.height + 16.0
    }
    
    override func willHideKeyboard() {
        super.willHideKeyboard()
        maginBottomContinueBtn.constant = 16.0
    }
    
    // MARK: - Private Methods
    override func initializeData() {
        userModel = userModel ?? UserModel()
    }
    
    override func setupUI() {
        var description = "Enter the code we've sent to "
        if userModel?.communicationType == "true" {
            description += userModel?.mobile?.getFormattedPhoneNumber(isOmitOwnCountryCode: false) ?? ""
        }else if userModel?.communicationType == "false" {
            description += userModel?.email ?? ""
        }
        lblDescription.text = description
        setupPinView()
        updateUI()
    }
    
    func setupPinView() {
        viewSVPin.pinLength = 6
        viewSVPin.secureCharacter = "\u{25CF}"
        viewSVPin.textColor = UIColor.white
        viewSVPin.borderLineColor = UIColor.white
        viewSVPin.borderLineThickness = 2
        viewSVPin.shouldSecureText = true
        viewSVPin.style = .underline
        viewSVPin.backgroundColor = UIColor.clear
        viewSVPin.font = AppFont.regular.size(26)
        viewSVPin.keyboardType = .numberPad
        viewSVPin.shouldSecureText = false
        viewSVPin.didFinishCallback = { pin in
            self.updateUI()
            self.actionContinueBtn(self)
        }
        viewSVPin.didChangeCallback = { pin in
            self.updateUI()
        }
    }
    
    func updateUI() {
        let pin = viewSVPin.getPin()
        if pin.count == 6 {
            btnContinue.updateActive(true)
        }else {
            btnContinue.updateActive(false)
        }
    }
    
    func pushNextStep() {
        if userModel?.isCreateAccount == "true" {
            APP_MANAGER.pushNextStepForSignUp(userModel, skipMode:isSkipMode, sender: self)
        }else {
            APP_MANAGER.pushNewPassVC(userModel, sender: self)
        }
    }

    // MARK: - User Action Handlers
    @IBAction func actionBackBtn(_ sender: UIButton) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionResendCodeBtn(_ sender: Any) {
        view.endEditing(true)
        hitSaveOtpApi()
    }
    
    @IBAction func actionContinueBtn(_ sender: Any) {
        view.endEditing(true)
        userModel?.otp = viewSVPin.getPin()
        hitVerifyOtpApi()
    }
    
}

// MARK: - BackEnd API
extension ConfirmCodeVC {
    func hitVerifyOtpApi() {
        guard let userModel = userModel else { return }
        
        showLoader()
        USER_SERVICE.hitVerifyOtpApi(userModel.toJSON()).done { (userResponse) -> Void in
            if userResponse.isVerified == 1 {
                self.hideLoaderAfter(ConstantTexts.otpVerifiedSuccessfully.localizedString, completion: {
                    self.pushNextStep()
                })
            }else {
                self.hideLoader()
                POPUP_MANAGER.makeToast(userResponse.message, target: self)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func hitSaveOtpApi() {
        guard let userModel = userModel else { return }

        viewSVPin.clearPin()
        showLoader()
        USER_SERVICE.hitSaveOtpApi(userModel.toJSON()).done { (userResponse) -> Void in
                if let _ = userResponse.otp {
                    self.hideLoaderAfter(ConstantTexts.verificationCodeSent.localizedString)
                }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

}
