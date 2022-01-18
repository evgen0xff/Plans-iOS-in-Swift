//
//  UserBaseVC.swift
//  Plans
//
//  Created by Star on 2/9/21.
//

import UIKit

// ViewController related to User Info
// UserBaseVC -> PlansContentBaseVC -> PlansBaseVC -> BaseViewController -> UIViewController
// User Info action

class UserBaseVC: PlansContentBaseVC {

    var userID: String?
    var activeUser: UserModel?
    
    override func initializeData() {
        super.initializeData()
        userID = userID ?? activeUser?._id ?? activeUser?.userId ?? activeUser?.friendId
    }

}

// MARK: - Common Methods
extension UserBaseVC {
    func sendMessage(user: UserModel?) {
        if user?.friendShipStatus != 5 {
            APP_MANAGER.pushChatMessageVC(otherUser: user)
        }else {
            unblockUser(user) { success in
                if success == true {
                    APP_MANAGER.pushChatMessageVC(otherUser: user)
                }
            }
        }
    }
    
    func reportUser(user: UserModel?) {
        guard let userId = user?._id else { return }
        let _ = showPlansAlertYesNo(message: ConstantTexts.reportUser.localizedString) {
            self.reportEntity(id: userId, type: "user")
        }
    }


}

// MARK: - BackEnd API
extension UserBaseVC  {
    func getProfile(isShowLoader: Bool = false, complete: ((_ user: UserModel?) -> ())? = nil) {
        guard let userID = userID else {
            complete?(nil)
            return
        }
        let dict = ["userId" : userID]

        if isShowLoader == true { showLoader() }
        USER_SERVICE.getUserProfileApi(dict).done { (response) -> Void in
            self.hideLoader()
            self.activeUser = response
            complete?(response)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
}

// MARK: - Menu Option
extension UserBaseVC {
    func processUserMenuAction(titleAction: String?, user: UserModel?) -> Bool {
        var result = false
        guard let user = user else { return result }
        
        result = true

        switch titleAction {
        case "Block User":
            blockUser(user: user)
            break
        case "Send Message":
            sendMessage(user: user)
            break
        case "Report":
            reportUser(user: user)
            break
        default:
            result = false
            break
        }
        return result
    }

}



