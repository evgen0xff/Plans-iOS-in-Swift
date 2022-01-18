//
//  SignUpProfilePictureVC.swift
//  Plans
//
//  Created by Star on 2/2/21.
//

import UIKit

class SignUpProfilePictureVC: AuthBaseVC {

    // MARK: - IBOutlet
    @IBOutlet weak var imgviewUserProfile: UIImageView!
    @IBOutlet weak var btnAddPhoto: UIButton!
    
    // MARK: - Properties
    var imageSelected: UIImage?
    var urlProfileImage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Private Method
    override func initializeData() {
        userModel = userModel ?? UserModel()
        urlProfileImage = userModel?.profileImage ?? userModel?.facebookImage
    }
    
    override func setupUI() {
        imgviewUserProfile.setUserImage(urlProfileImage, defaultImage: "ic_user_circle_white")
        updateUI()
    }
    
    func updateUI() {
        if imageSelected != nil {
            imgviewUserProfile.image = imageSelected
        }
        
        if imageSelected != nil || urlProfileImage != nil {
            btnAddPhoto.setTitle("Continue", for: .normal)
        }else {
            btnAddPhoto.setTitle("Add a Photo", for: .normal)
        }
    }
    
    // MARK: - User Action Handlers

    @IBAction func actionSkipBtn(_ sender: Any) {
        APP_MANAGER.pushNextStepForSignUp(userModel, skipMode:false, sender: self)
    }
    
    @IBAction func actionTappedUserProfile(_ sender: Any) {
        MEDIA_PICKER.showCameraGalleryActionSheet(sender: self,
                                                  delegate: self,
                                                  action: .userProfile)
    }
    
    @IBAction func actionAddPhoto(_ sender: Any) {
        if imageSelected != nil {
            hitUpdateUserApi(image: imageSelected)
        }else if urlProfileImage != nil {
            APP_MANAGER.pushNextStepForSignUp(userModel, skipMode:false, sender: self)
        }else {
            actionTappedUserProfile(self)
        }
    }
}

// MARK: - MediaPickerDelegate
extension SignUpProfilePictureVC : MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        imageSelected = image
        updateUI()
    }
}

// MARK: - Validations

extension SignUpProfilePictureVC {
    
    func hitUpdateUserApi(image: UIImage?) {
        guard let userModel = userModel, let image = image else { return }
        
        userModel.userId = USER_MANAGER.userId
        let dic = [ "userId": USER_MANAGER.userId ?? "",
                    "mediaType": "image"]

        showLoader()
        USER_SERVICE.hitUpdateUserApi(dic, userPhoto: image).done { (userResponse) -> Void in
            self.hideLoaderAfter(ConstantTexts.profileUpdatedSuccessfully.localizedString, completion: {
                if let profileImage = userResponse.userDetails?.profileImage {
                    USER_MANAGER.profileUrl = profileImage
                }
                APP_MANAGER.pushNextStepForSignUp(userModel, skipMode: false, sender: self)
            })
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}


