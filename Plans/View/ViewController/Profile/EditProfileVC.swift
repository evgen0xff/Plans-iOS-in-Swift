//
//  EditProfileVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit
import MaterialComponents
import Photos

class EditProfileVC: UserBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var btnSave: UIButton!
    @IBOutlet weak var imgviewProfile: UIImageView!
    @IBOutlet weak var txtfieldFirstName: MDCTextField!
    @IBOutlet weak var txtfieldLastName: MDCTextField!
    @IBOutlet weak var txtviewBio: MDCMultilineTextField!
    @IBOutlet weak var txtfieldEmail: MDCTextField!
    @IBOutlet weak var txtfieldPhoneNumber: MDCTextField!
    @IBOutlet weak var txtfieldLocation: MDCTextField!
    @IBOutlet weak var btnLocationClear: UIButton!
    @IBOutlet weak var heightBioTextView: NSLayoutConstraint!
    
    // MARK: - Properties
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()

    // MARK: - ViewController Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func initializeData() {
        super.initializeData()
        getUserProfile()
    }
    
    override func setupUI() {
        super.setupUI()
        setupTextFields()
    }
    
    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionSaveBtn(_ sender: Any) {
        view.endEditing(true)
        updateUserProfile()
    }
    
    @IBAction func actionTapBackground(_ sender: Any) {
        view.endEditing(true)

    }
    
    @IBAction func actionProfileImageBtn(_ sender: Any) {
        self.view.endEditing(true)
        MEDIA_PICKER.showCameraGalleryActionSheet(sender: self,
                                                  delegate: self,
                                                  action: .userProfile)
    }
    
    @IBAction func actionLocationClearBtn(_ sender: UIButton) {
        view.endEditing(true)
        if sender == btnLocationClear {
            var location = ""
            if btnLocationClear.isSelected == false {
                location = LOCATION_MANAGER.city_CounAddress as String
            }
            updateLoation(location)
            updateSaveBtn()
        }
    }
    
    @IBAction func actionChangedTextField(_ sender: UITextField) {
        updateSaveBtn()
    }
    
    
    // MARK: - Private Methods
    func setupTextFields() {
        // First Name
        txtfieldFirstName.delegate = self
        
        // Last Name
        txtfieldLastName.delegate = self
        
        // Bio
        txtviewBio.placeholder = "Bio"
        txtviewBio.textView?.delegate = self
        
        // Email
        txtfieldEmail.delegate = self
        txtfieldEmail.isUserInteractionEnabled = false

        // Phone Number
        txtfieldPhoneNumber.delegate = self
        txtfieldPhoneNumber.isUserInteractionEnabled = false
        
        // Location Number
        txtfieldLocation.delegate = self
        txtfieldLocation.isUserInteractionEnabled = false


        // Apply the app scheme to TextFields
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfieldFirstName))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfieldLastName))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtviewBio))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfieldEmail))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfieldPhoneNumber))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtfieldLocation))
        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            item.textInput?.addClearBtn(image: "ic_x_grey")
        }
    }
    
    func updateUI(user: UserModel?) {
        guard let user = user else { return }
        activeUser = user
        
        // Profile Image
        if let data = user.imageData, let image = UIImage(data: data) {
            imgviewProfile.image = image
        }else {
            imgviewProfile.setUserImage(user.profileImage)
        }
        
        // First Name
        txtfieldFirstName.text = user.firstName
        
        // Last Name
        txtfieldLastName.text = user.lastName
        
        // Bio
        updateBioTextView(user.bio)
        
        // Email
        txtfieldEmail.text = user.email
        
        // Phone Number
        txtfieldPhoneNumber.text = user.mobile
        
        // Location
        updateLoation(user.location)

        // Save Btn
        updateSaveBtn()
    }
    
    func updateBioTextView(_ text: String?) {
        txtviewBio.text = text
        txtviewBio.sizeToFit()
        let width = txtviewBio.frame.size.width - txtviewBio.clearButton.bounds.width
        if var height = text?.height(withConstrainedWidth: width, font: AppFont.regular.size(17)) {
            height += 40
            if height > 60.0 {
                heightBioTextView.constant = height
            }else {
                heightBioTextView.constant = 60.0
            }
        }
        txtviewBio.sizeToFit()
    }
    
    func updateLoation(_ text: String?) {
        txtfieldLocation.text = text?.removeOwnCountry()
        if let text = text, text != "" {
            btnLocationClear.isSelected = true
        }else {
            btnLocationClear.isSelected = false
        }
    }
    
    func updateSaveBtn() {
        var result = false
        
        let newFirstName = txtfieldFirstName.text?.trimmingCharacters(in: .whitespaces)
        let newLastName = txtfieldLastName.text?.trimmingCharacters(in: .whitespaces)
        let newLocation = txtfieldLocation.text?.trimmingCharacters(in: .whitespaces)
        let newBio = txtviewBio.text?.trimmingCharacters(in: .whitespaces)

        if isValidate() == true {
            if activeUser?.imageData != nil {
                result = true
            }else if activeUser?.firstName != newFirstName {
                result = true
            }else if activeUser?.lastName != newLastName {
                result = true
            }else if (activeUser?.location ?? "") != newLocation {
                result = true
            }else if (activeUser?.bio ?? "") != newBio {
                result = true
            }
        }
        
        btnSave.isHidden = !result
    }
    
    func isValidate() -> Bool {

        var result = true

        let firstName = txtfieldFirstName.text?.trimmingCharacters(in: .whitespaces)
        let lastName = txtfieldLastName.text?.trimmingCharacters(in: .whitespaces)
        
        if firstName == nil || firstName == "" {
            result = false
        }
        
        if result == true && ( lastName == nil || lastName == "") {
            result = false
        }
        
        return result
    }
    

    
}

// MARK: - Backend Api Methods

extension EditProfileVC {
    
    //Get user profile
    
    private func getUserProfile() {
        showLoader()
        USER_SERVICE.hitUserProfileApi().done { (response) -> Void in
            self.hideLoader()
            self.updateUI(user: response)
        }.catch { (error) in
            self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
    private func prepareUserProfileDic() -> [String:Any]? {
        guard let userId = activeUser?._id else { return nil}
        let newUser = UserModel()
        newUser._id = userId
        newUser.firstName = txtfieldFirstName.text?.trimmingCharacters(in: .whitespaces)
        newUser.lastName = txtfieldLastName.text?.trimmingCharacters(in: .whitespaces)
        newUser.userLocation = txtfieldLocation.text?.trimmingCharacters(in: .whitespaces)
        newUser.bio = txtviewBio.text?.trimmingCharacters(in: .whitespaces)
        return newUser.toJSON()
    }
    
    // Update User Info

    private func updateUserProfile() {
        guard let userInfo = prepareUserProfileDic() else { return }
        showLoader()
        USER_SERVICE.hitUpdateUserProfileApi(userInfo).done { (response) -> Void in
            self.hideLoader()
            if self.activeUser?.imageData != nil {
                self.changeProfileImage(image: self.imgviewProfile.image)
            }
            else {
                USER_MANAGER.updateUserInfoFromEditProfile(newUser: response)
                self.navigationController?.popViewController(animated: false)
                POPUP_MANAGER.makeToast(ConstantTexts.profileUpdated.localizedString)
            }
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // Change profile image
    
    private func changeProfileImage(image: UIImage?) {
        guard let userId = activeUser?._id, let image = image else {
            hideLoader()
            return
        }
        showLoader()
        USER_SERVICE.hitUpdateUserApi(["userId":userId], userPhoto: image).done { (resposne) -> Void in
            self.hideLoader()
            USER_MANAGER.updateUserInfoFromEditProfile(newUser: resposne)
            self.navigationController?.popViewController(animated: false)
            POPUP_MANAGER.makeToast(ConstantTexts.profileUpdated.localizedString)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    

}



// MARK: - UITextFieldDelegate
extension EditProfileVC : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var result = true

        let currLength = textField.text?.count ?? 0
        let newLength = currLength + string.count - range.length
        
        if range.length > 0 {
            return true
        }

        switch textField {
        case txtfieldFirstName, txtfieldLastName:
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

// MARK: - UITextViewDelegate
extension EditProfileVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == txtviewBio.textView {
            if (txtviewBio.text?.count ?? 0) > 500 {
                txtviewBio.text = activeUser?.bio
            }else {
                activeUser?.bio = txtviewBio.text
            }
            updateBioTextView(txtviewBio.text)
            updateSaveBtn()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        txtviewBio.textColor = .black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        txtviewBio.textColor = AppColor.grey_text
    }

}




// MARK: - MediaPickerDelegate
extension EditProfileVC : MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        activeUser?.imageData = image?.pngData()
        imgviewProfile.image = image
        updateSaveBtn()
    }
    
}

