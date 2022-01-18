//
//  DeleteAccountVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit
import MaterialComponents

class DeleteAccountVC: UserBaseVC {

    // MARK: - All IBOutlet
    
    @IBOutlet weak var deleteMsgTextVw: MDCTextField!
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var btnDeleteAccount: UIButton!
    
    // MARK: - Properties
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    private func setUpView() {
        deleteMsgTextVw?.delegate = self

        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: deleteMsgTextVw))
        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            item.textInput?.addClearBtn(image: "ic_x_grey")
        }

        let nameF = USER_MANAGER.fullName
        if nameF != "" {
            userNameLbl.text = nameF! + ", we are sorry to see you go"
        }
    }
    
    
    private func isVaild() -> Bool {
        var result = true
        let password = deleteMsgTextVw.text?.trimmingCharacters(in: .whitespaces)
        if password == nil || password?.count == 0 {
            result = false
        }else if password!.count < 8 || password!.count > 25 {
            result = false
        }
        return result
    }

    
    // MARK: - User Action Handlers
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteAccountMethod(_ sender: UIButton) {
        view.endEditing(true)

        if isVaild() == true {
            let _ = showPlansAlertYesNo(message: ConstantTexts.deleteAccountAlert.localizedString, titleYes: "Delete", actionYes: {
                self.deleteAccount()
            }, blurEnabled: true)
        }
    }
    @IBAction func actionTappedBackground(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func actionChangedPassword(_ sender: UITextField) {
        if isVaild() == true {
            btnDeleteAccount.isUserInteractionEnabled = true
            btnDeleteAccount.backgroundColor = AppColor.purple_join
        }else {
            btnDeleteAccount.isUserInteractionEnabled = false
            btnDeleteAccount.backgroundColor = AppColor.grey_button
        }
    }
    
    
    
}

// MARK: - UITextFieldDelegate

extension DeleteAccountVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = AppColor.grey_text
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
    }

}

// MARK: - Backend API
extension DeleteAccountVC {
    private func deleteAccount() {
        guard let password = deleteMsgTextVw?.text?.trimmingCharacters(in: .whitespaces) else { return }

        showLoader()
        let dict = ["password": password]
        USER_SERVICE.deleteUserApi(dict).done { (response) -> Void in
            self.hideLoader()
            if let _ = response.message {
               APP_MANAGER.gotoLandingVC()
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

