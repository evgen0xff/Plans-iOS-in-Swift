//
//  PlansContentBaseVC.swift
//  Plans
//
//  Created by Star on 2/9/21.
//

import UIKit

// ViewContorller for Plans Contents without bottom tabbar
// PlansContentBaseVC -> PlansBaseVC -> BaseViewController -> UIViewController
// Non-Tabbar


class PlansContentBaseVC: PlansBaseVC {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        APP_MANAGER.updateTabBar(isHiddenCenterAction: true)
    }

}

// MARK: - Friend Relationship
extension PlansContentBaseVC {
    func unFriendMethod(_ friend: UserModel?) {
        guard let friendId = friend?._id else { return }
        
        var fullName = ""
        if let name = friend?.fullName, name != "" {
            fullName = name
        }else if let first = friend?.firstName, first != "", let last = friend?.lastName, last != "" {
            fullName = first + " " + last
        }else if let name = friend?.name, name != "" {
            fullName = name
        }

        let message = "Are you sure you want to unfriend \(fullName)?"
        let _ = showPlansAlertYesNo(message: message, titleYes: "Cancel", titleNo: "Unfriend", actionNo: {
            let dict = ["friendId": friendId]
            self.showLoader()
            FRIENDS_SERVICE.hitUnfriendApi(dict).done { (response) -> Void in
                self.hideLoader()
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
            }
        }, blurEnabled: true, urlImage: friend?.profileImage)
    }
    
    func sendFriendRequest(_ mobileNumber: String?) {
        guard let mobile = mobileNumber else { return }
        let dict = ["mobile": mobile]
        showLoader()
        FRIENDS_SERVICE.hitsendRequestApi(dict).done { (response) -> Void in
                self.hideLoader()
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            ANALYTICS_MANAGER.logEvent(.friend_request)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
    func acceptRequestMethod(friendId: String? = nil, user: UserModel? = nil) {
        guard let friendId = friendId ?? user?._id ?? user?.userId ?? user?.friendId else { return }

        let dict = ["friendId": friendId]
        let fullName = user?.fullName ?? user?.name ?? "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        
        self.showLoader()
        FRIENDS_SERVICE.hitAcceptRequestApi(dict).done { (response) -> Void in
            self.hideLoader()
            POPUP_MANAGER.makeToast(ConstantTexts.youNowFriendsWith.localizedString + "\(fullName)")
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            ANALYTICS_MANAGER.logEvent(.friend_add)
        }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }

    func cancelFriendRequestMethod(_ friendId: String?) {
        self.showLoader()
        guard let friendId = friendId else { return }
        let dict = ["friendId": friendId]
        FRIENDS_SERVICE.cancelRequestApi(dict).done { (response) -> Void in
                self.hideLoader()
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
    func rejectRequestMethod(_ friendId: String?) {
        guard let friendId = friendId else { return }
        
        let dict = ["friendId": friendId]
        self.showLoader()
        FRIENDS_SERVICE.hitRejectRequestApi(dict).done { (response) -> Void in
            self.hideLoader()
            POPUP_MANAGER.makeToast(ConstantTexts.friendRequestRejected.localizedString)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }

    
    func unblockUser(_ user: UserModel?, complete: ((_ success: Bool?) -> Void)? = nil) {
        guard let userId = user?._id else {
            complete?(false)
            return
        }
        
        let fullName = user?.fullName ?? user?.name ?? "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        
        let _ = showPlansAlertYesNo(message: "Are you sure you want to unblock \(fullName)?", titleYes: "Unblock", actionYes: {
            self.showLoader()
            let dict = ["friendId": userId]
            FRIENDS_SERVICE.unBlockUserRequest(dict).done { (response) -> Void in
                self.hideLoader()
                POPUP_MANAGER.makeToast("You have unblocked \(fullName)")
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                complete?(true)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
                complete?(false)
            }

        }, blurEnabled: true)
    }
    
    func blockUser(user: UserModel?) {
        guard let friendId = user?._id ?? user?.userId ?? user?.friendId else { return }
        let fullName = "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        let _ = showPlansAlertYesNo(message: "Are you sure you want to block \(fullName)?", titleYes: "Block", actionYes: {
            self.showLoader()
            let dict = ["friendId": friendId]
            FRIENDS_SERVICE.blockUserRequest(dict).done { (response) -> Void in
                self.hideLoader()
                if let msg = response.message,
                   msg != "" {
                    POPUP_MANAGER.makeToast("You have blocked \(fullName)")
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                }
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
            }

        }, blurEnabled: true)

    }
}

// MARK: - Common Methods
extension PlansContentBaseVC {
    func getAttriString(friends: Int = 0, contacts: Int = 0, emails: Int = 0, isSelected: Bool = true ) -> NSMutableAttributedString? {
        var result: NSMutableAttributedString? = nil
        var arrayAttri = [NSMutableAttributedString]()

        let styleGray = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: AppFont.regular.size(15.0)]
        let styleTeal = [NSAttributedString.Key.foregroundColor: AppColor.teal_main, NSAttributedString.Key.font: AppFont.regular.size(15.0)]
        

        // Friends
        if friends > 0 {
            var text = ""
            if friends > 1 {
                text = "\(friends) friends"
            }else {
                text = "1 friend"
            }
            let attriText = NSMutableAttributedString(string: text, attributes: styleTeal)
            arrayAttri.append(attriText)
        }
        
        // Contacts
        if contacts > 0 {
            var text = ""
            if contacts > 1 {
                text = "\(contacts) contacts"
            }else {
                text = "1 contact"
            }
            let attriText = NSMutableAttributedString(string: text, attributes: styleTeal)
            arrayAttri.append(attriText)
        }

        // Emails
        if emails > 0 {
            var text = ""
            if emails > 1 {
                text = "\(emails) emails"
            }else {
                text = "1 email"
            }
            let attriText = NSMutableAttributedString(string: text, attributes: styleTeal)
            arrayAttri.append(attriText)
        }

        
        if arrayAttri.count > 0 {
            result = NSMutableAttributedString()
            let textSelected = NSMutableAttributedString(string: isSelected ? "Selected " : "Removed ", attributes: styleGray)
            let textAnd = NSMutableAttributedString(string: " and ", attributes: styleGray)
            let textComma = NSMutableAttributedString(string: ", ", attributes: styleGray)

            result?.append(textSelected)
            
            if arrayAttri.count == 1 {
                result?.append(arrayAttri[0])
            }else if arrayAttri.count == 2 {
                result?.append(arrayAttri[0])
                result?.append(textAnd)
                result?.append(arrayAttri[1])
            }else if arrayAttri.count == 3 {
                result?.append(arrayAttri[0])
                result?.append(textComma)
                result?.append(arrayAttri[1])
                result?.append(textAnd)
                result?.append(arrayAttri[2])
            }
        }
        
        return result
    }
    
    func getAttriString(emails: Int = 0, mobiles: Int = 0, links: Int = 0) -> NSMutableAttributedString? {
        var result: NSMutableAttributedString? = nil
        var arrayAttri = [NSMutableAttributedString]()
        
        let styleGray = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: AppFont.regular.size(15.0)]
        let styleTeal = [NSAttributedString.Key.foregroundColor: AppColor.teal_main, NSAttributedString.Key.font: AppFont.regular.size(15.0)]

        
        
        // Emails
        if emails > 0 {
            var text = ""
            if emails > 1 {
                text = "\(emails) emails"
            }else {
                text = "1 email"
            }
            let attriGuests = NSMutableAttributedString(string: text, attributes: styleTeal)
            arrayAttri.append(attriGuests)
        }

        // Contacts
        if mobiles > 0 {
            var text = ""
            if mobiles > 1 {
                text = "\(mobiles) contacts"
            }else {
                text = "1 contact"
            }
            let attriGuests = NSMutableAttributedString(string: text, attributes: styleTeal)
            arrayAttri.append(attriGuests)
        }

        if arrayAttri.count > 0 {
            result = NSMutableAttributedString()
            let textPending = NSMutableAttributedString(string: "Pending invite ", attributes: styleGray)
            let textAnd = NSMutableAttributedString(string: " and ", attributes: styleGray)

            result?.append(textPending)

            if arrayAttri.count == 1 {
                result?.append(arrayAttri[0])
            }else if arrayAttri.count == 2 {
                result?.append(arrayAttri[0])
                result?.append(textAnd)
                result?.append(arrayAttri[1])
            }
        }
        
        // Links
        if links > 0 {
            var text = ""
            if links > 1 {
                text = "\(links) guests"
            }else {
                text = "1 guest"
            }
            let attriGuests = NSMutableAttributedString(string: text, attributes: styleTeal)
            let textJoined = NSMutableAttributedString(string: " responded by link.", attributes: styleGray)
            
            if result == nil {
                result = NSMutableAttributedString()
            }
            
            if (arrayAttri.count > 0) {
                result?.append(NSMutableAttributedString(string: "\n", attributes: styleTeal))
            }
            result?.append(attriGuests)
            result?.append(textJoined)
        }

        
        return result
    }


}

// MARK: - Post
extension PlansContentBaseVC {
    
    func likeUnlikePost(postId: String?, eventId: String?, isLike: Bool = true) {
        
        guard let postId = postId, let eventId = eventId else { return }
    
        let dict = ["eventId": eventId,
                    "postId": postId,
                    "isLike": "\(isLike)"] as [String : Any]
        
        showLoader()
        POSTS_SERVICE.hitLikePost(dict).done { (response) -> Void in
            self.hideLoader()
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    func createPostWithText(eventModel: EventModel) {
        self.showLoader()
        POSTS_SERVICE.hitCreatePostWithText(eventModel.toJSON()).done { (response) -> Void in
            self.hideLoader()
            POPUP_MANAGER.makeToast(ConstantTexts.postedComment.localizedString)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            ANALYTICS_MANAGER.logEvent(.post_add)
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }
    
    // Create Post with media
    func createPostWithMedia(eventModel: EventModel, uploadImage: UIImage? , videoUrl: URL?) {
        POPUP_MANAGER.showLoadingToast(.posting)
        POSTS_SERVICE.hitCreatePost(eventModel.toJSON(), image: uploadImage, videoUrl: videoUrl).done { (response) -> Void in
            POPUP_MANAGER.hideLoadingToast(.posting)
            var notice = ConstantTexts.postedVideo.localizedString
            if eventModel.mediaType == "image" {
                notice = ConstantTexts.postedPhoto.localizedString
            }
            POPUP_MANAGER.makeToast(notice)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            ANALYTICS_MANAGER.logEvent(.post_add)
        }.catch { (error) in
            POPUP_MANAGER.hideLoadingToast(.posting)
            POPUP_MANAGER.handleError(error)
        }
    }

}



