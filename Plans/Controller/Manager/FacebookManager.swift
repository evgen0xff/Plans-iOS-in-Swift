//
//  FacebookManager.swift
//
//  Created by Star on 22/07/17.
//  Copyright © 2021 PlansCollective. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit

let params = ["fields": "id,name,email,birthday,user_friends"]

enum Permission: String {
    case publicProfile
    case birthday
    case friends
    case photos
    case email
    
    var stringValue: String {
        switch self {
        case .publicProfile: return "public_profile"
        case .birthday: return "user_birthday"
        case .photos: return "user_photos"
        case .email: return "email"
        case .friends: return "user_friends"
        }
    }
}

class FacebookManager: NSObject {
    
    // MARK: - Singleton Instantiation
    private static let _shared: FacebookManager = FacebookManager()
    static var shared: FacebookManager {
        return ._shared
    }
    
    // MARK: - Private Properties
    private weak var guestViewC: UIViewController? = nil
    
    // MARK: - Public Properties
    public var fbInfoProvider: ((Bool, FBUser)->())? = nil
    
    // MARK: - Initializers
    private override init() {
        // This will resctrict the instantiation of this class.
    }
    
    // MARK: - Public Methods
    func loginWithFacebook(readPermissions: [String], target: UIViewController?) {
        guard let target = target else { return }
        self.guestViewC = target
        let login = LoginManager()
        login.logOut()
        login.logIn(permissions: readPermissions,
                    from: guestViewC, handler: { (result, error) in
                        if (error == nil) {
                            if let loginResult: LoginManagerLoginResult = result {
                                if(loginResult.isCancelled) {
                                    //Show Cancel alert
                                } else if(loginResult.grantedPermissions.contains("email")) {
                                    self.getInfoAboutUser()
                                }
                            }
                        } else { return }
        })
    }
    
    // MARK: - Private Methods
    private func getInfoAboutUser() {
        if AccessToken.current != nil {
            
            let current = AccessToken.current
            
            if current?.hasGranted(.userBirthday) == true {
                print("The app has the birthday permission on Facebook")
            }else {
                print("The app has not the birthday permission on Facebook")
            }
            
            let requestMe = GraphRequest.init(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.width(400).height(400), email, birthday"])
                
            let connection = GraphRequestConnection()
            connection.add(requestMe, completion: {
                (request, result, error) in
                let result = result as? [String: Any]
                if error != nil {
                    LoginManager().logOut()
                    return
                } else {
                   
                    let fbUser = FBUser(jsonDic: result)

                    if let facebookToken = AccessToken.current?.tokenString {
                        fbUser.fbToken = facebookToken
                    }
                   
                    self.fbInfoProvider?(true, fbUser)
                }
            })
            connection.start()
        }
    }

    func getFriendsList(userId: String) {
        let request = GraphRequest(graphPath: "/me/friends", parameters: params)
        let connection = GraphRequestConnection()
        connection.add(request, completion: {
            (request, response, error) in
            if(error != nil){}
            if(error == nil) {}
        })
        connection.start()
    }

}
