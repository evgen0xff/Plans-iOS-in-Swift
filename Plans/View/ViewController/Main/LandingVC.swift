//
//  LandingVC.swift
//  Plans
//
//  Created by Plans Collective LLC on 4/23/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AuthenticationServices

class LandingVC: BaseViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var btnCreateAccount: UIButton!
    @IBOutlet weak var stackSigninWithAppleContainer: UIStackView!
    
    // MARK: - Properties
    
    var avPlayer: AVPlayer!
    var avPlayerLayer: AVPlayerLayer!
    
    // MARK: - View Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NOTIFICATION_CENTER.addObserver(self,
                                        selector: #selector(playerItemDidReachEnd(notification:)),
                                        name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                        object: avPlayer.currentItem)
        avPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.removeObserver(self, name:  NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        avPlayer.pause()
    }
    
    // MARK: - Private Methods
    
    override func setupUI() {
        super.setupUI()
        
        let theURL = Bundle.main.url(forResource: "vi_landing", withExtension: "mp4")
        avPlayer = AVPlayer(url: theURL!)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avPlayer.volume = 0
        avPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        avPlayerLayer.frame = view.layer.bounds
        view.backgroundColor = UIColor.clear;
        view.layer.insertSublayer(avPlayerLayer, at: 0)
        
        setupSigninWithAppleBtn()
    }
    
    @objc private func playerItemDidReachEnd(notification: NSNotification) {
        guard let p: AVPlayerItem = notification.object as? AVPlayerItem else { return }
        p.seek(to: CMTime.zero, completionHandler: nil)
    }
    
    private func setupSigninWithAppleBtn() {
        if #available(iOS 13.0, *) {
            let authorizationButton = ASAuthorizationAppleIDButton(type: .continue, style: .black)
            authorizationButton.cornerRadius = 5.0
            authorizationButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
            stackSigninWithAppleContainer.addArrangedSubview(authorizationButton)
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// - Tag: perform_appleid_request
    @available(iOS 13.0, *)
    @objc
    func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // - Tag: perform_appleid_password_request
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    @available(iOS 13.0, *)
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(),
                        ASAuthorizationPasswordProvider().createRequest()]
        
        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    private func saveUserInKeychain(_ userIdentifier: String?, email: String? = nil, firstName: String? = nil, lastName: String? = nil) {
        do {
            guard let id = userIdentifier else { return }
            try KeychainItem(key: kUserIdApple).saveItem(id)
            if let email = email {
                try KeychainItem(key: kEmail).saveItem(email)
            }
            if let firstName = firstName {
                try KeychainItem(key: kFirstName).saveItem(firstName)
            }
            if let lastName = lastName {
                try KeychainItem(key: kLastName).saveItem(lastName)
            }
        } catch {
            print("Unable to save userIdentifier to keychain.")
        }
    }


    
    // MARK: - IBAction Methods
    
    @IBAction func tapFacebook(_ sender: UIButton) {
        FacebookManager.shared.loginWithFacebook(readPermissions: [Permission.publicProfile.stringValue, Permission.email.stringValue, Permission.birthday.stringValue], target: self)
        FacebookManager.shared.fbInfoProvider = {
            (success, fbUser) in
            if success {
                self.hitLoginApi(UserModel(fbUser: fbUser))
            }
        }
    }
    
    @IBAction func tapLogin(_ sender: UIButton) {
        APP_MANAGER.pushLoginVC()
    }

    @IBAction func tapCreateAccount(_ sender: UIButton) {
        APP_MANAGER.pushNextStepForSignUp(sender: self)
    }
    
}

// MARK: - Hit Login API

extension LandingVC {
    func hitLoginApi(_ userModel : UserModel) {

        userModel.fcmId = USER_MANAGER.deviceToken
        userModel.loginType = "false"
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
            APP_MANAGER.pushNextStepForSignUp(userModel, skipMode: true, sender: self)
        }
    }
}


@available(iOS 13.0, *)
extension LandingVC: ASAuthorizationControllerDelegate {
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            // Create an account in your system.
            let userIdApple = appleIDCredential.user
            let email = appleIDCredential.email ?? KeychainItem.getStringWith(key: kEmail)
            let firstName = appleIDCredential.fullName?.givenName ?? KeychainItem.getStringWith(key: kFirstName)
            let lastName = appleIDCredential.fullName?.familyName ?? KeychainItem.getStringWith(key: kLastName)
            saveUserInKeychain(userIdApple, email: email, firstName: firstName, lastName: lastName)
            if email?.isValidEmail() == true {
                let user = UserModel()
                user.socialId = userIdApple
                user.firstName = firstName
                user.lastName = lastName
                user.email = email
                APP_CONFIG.defautMainQ.async {
                    self.hitLoginApi(user)
                }
            }else {
                self.makeToast("We can't get any invalid email for your account")
            }
        default:
            break
        }
        
    }
    
    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

@available(iOS 13.0, *)
extension LandingVC: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
