//
//  AppManager.swift
//  Plans
//
//  Created by Star on 2/8/20.
//  Copyright © 2020 PlansCollective. All rights reserved.
//

import Foundation
import UIKit
import Reachability
import Alamofire
import Firebase
import FirebaseCrashlytics
import CoreLocation
import MapKit
import EventKitUI
import BMPlayer

let APP_MANAGER = AppManager.shared

class AppManager: NSObject {
    static let shared = AppManager()
    
    var reachability : Reachability?
    var noInternet : Bool = false

    var rootVC : UIViewController? {
        get {
            return APP_DELEGATE.window?.rootViewController
        }
        set {
            APP_DELEGATE.window?.rootViewController = newValue
            APP_DELEGATE.window?.makeKeyAndVisible()
        }
    }

    var rootNaviVC : UINavigationController? {
        return rootVC as? UINavigationController
    }

    var topVC: UIViewController? {
        return getTopMostVC()
    }
    
    var tabBarVC: MainTabBarVC?
    
    var selectedTabIndex : Int? {
        return tabBarVC?.selectedIndex
    }
    
    var selectedTabType : MainTabBarVC.TabType {
        return tabBarVC?.getTabType(selectedTabIndex ?? 0) ?? .home
    }
    
    var selectedTabNaviVC : UINavigationController? {
        return tabBarVC?.selectedViewController as? UINavigationController
    }
    
    var liveEvent: EventFeedModel? {
        didSet {
            if liveEvent != nil, USER_MANAGER.isSeenYouLiveAt == false {
                tabBarVC?.popUpEventLive(event: liveEvent)
                USER_MANAGER.isSeenYouLiveAt = true
            }else {
                tabBarVC?.hideOverLayer()
            }
        }
    }
    
    var hostedEvents = [EventFeedModel]()
    var popupAlert: UIViewController?
    
    // Get top most view controller
    func getTopMostVC(rootViewController: UIViewController? = APP_MANAGER.rootVC) -> UIViewController? {
        if let navigationController = rootViewController as? UINavigationController
        {
            return getTopMostVC(rootViewController: navigationController.visibleViewController!)
        }
        
        if let tabBarController = rootViewController as? UITabBarController
        {
            if let selectedTabBarController = tabBarController.selectedViewController
            {
                return getTopMostVC(rootViewController: selectedTabBarController)
            }
        }
        
        if let presentedViewController = rootViewController?.presentedViewController
        {
            return getTopMostVC(rootViewController: presentedViewController)
        }
        return rootViewController
    }
    
    func setRootVC<T: UIViewController>(_ typeVC : T.Type) {
        guard let vc = STORY_MANAGER.viewController(typeVC.className) as? T else { return }
        let navC = UINavigationController(rootViewController: vc)
        navC.navigationBar.isHidden = true
        rootVC = navC
    }

    func pushViewController(_ vc : UIViewController?, sender: UIViewController? = nil ) {
        guard let vc = vc else { return }
        vc.hidesBottomBarWhenPushed = true
        let topVC = sender ?? self.topVC
        
        if let eventVC = vc as? EventBaseVC {
            if eventVC.eventID == nil {
                eventVC.eventID = (topVC as? EventBaseVC)?.eventID
            }
            if eventVC.activeEvent == nil {
                eventVC.activeEvent = (topVC as? EventBaseVC)?.activeEvent
            }
        }
        
        topVC?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func pushViewControllers(_ listVCs : [UIViewController]?, sender: UIViewController? = nil ) {
        guard let list = listVCs, list.count > 0 else { return }

        let naviVC = (sender ?? topVC)?.navigationController
        var stackNavi = naviVC?.viewControllers
        list.forEach({
            $0.hidesBottomBarWhenPushed = true
            stackNavi?.append($0)
        })
        
        if let list = stackNavi {
            naviVC?.setViewControllers(list, animated: true)
        }
    }


    func presentViewController(_ vc : UIViewController?, sender: UIViewController? = nil ) {
        guard let vc = vc else { return }
        vc.modalPresentationStyle = .fullScreen
        vc.hidesBottomBarWhenPushed = true
        let topVC = sender ?? self.topVC

        if let eventVC = vc as? EventBaseVC {
            if eventVC.eventID == nil {
                eventVC.eventID = (topVC as? EventBaseVC)?.eventID
            }
            if eventVC.activeEvent == nil {
                eventVC.activeEvent = (topVC as? EventBaseVC)?.activeEvent
            }
        }

        topVC?.present(vc, animated: true, completion: nil)
    }

    func pushViewController<T: UIViewController>(_ typeVC : T.Type, sender: UIViewController? = nil ) {
        guard let vc = STORY_MANAGER.viewController(typeVC.className) as? T else { return }
        pushViewController(vc, sender: sender)
    }

    func presentViewController<T: UIViewController>(_ typeVC : T.Type, sender: UIViewController? = nil ) {
        guard let vc = STORY_MANAGER.viewController(typeVC.className) as? T else { return }
        presentViewController(vc, sender: sender)
    }
    
    func popViewContorller(sender: UIViewController? = nil, animated: Bool = true) {
        let topVC = sender ?? self.topVC
        topVC?.navigationController?.popViewController(animated: animated)
    }
    
}

// MARK: - Internet Connection
extension AppManager {
    // Start the internet connection notification
    func startReachable() {
        do {
            reachability = try? Reachability()
            reachability?.whenReachable = { reachability in
                print("Internet connection : ", reachability.connection.description)
                if reachability.connection == .wifi {
                    self.noInternet = false
                } else {
                    self.noInternet = false
                }
            }
            reachability?.whenUnreachable = { _ in
                print("Internet connection : No Internet")
                self.noInternet = true
            }
            try reachability?.startNotifier()
        } catch {
            noInternet = true
        }
    }
    
    // Stop the internet connection notification
    func stopReachable() {
        reachability?.stopNotifier()
    }
}

// MARK: - App Initialization
extension AppManager {
    // Set up App UI appearance globally.
    func setAppUIAppearance() {
        let imgNavBackground = UIImage(named: "im_background_pink")?.resizeImageUsingVImage(size: CGSize(width: MAIN_SCREEN_WIDTH, height: UIDevice.current.heightTopBar))
        
        // Navigation Bar
        UINavigationBar.appearance().setBackgroundImage(imgNavBackground, for: .default)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        // UISearchBar
        UISearchBar.appearance().backgroundImage = imgNavBackground

        // Background Color
        APP_DELEGATE.window?.backgroundColor = AppColor.grey_background
        
        // Video Player
        BMPlayerConf.allowLog = false
        BMPlayerConf.shouldAutoPlay = false
        BMPlayerConf.tintColor = .black
        BMPlayerConf.topBarShowInCase = .none
        BMPlayerConf.loaderType  = .blank
        BMPlayerConf.enableBrightnessGestures = false
        BMPlayerConf.enableVolumeGestures = false
        BMPlayerConf.enablePlaytimeGestures = false        
    }

    func initializeForLaunch() {
        // Check Internet status
        startReachable()

        // User default data
        USER_MANAGER.initializeForLaunch()

        // App UI Appearance
        setAppUIAppearance()
        
        // Go to First screen
        gotoFirstVC()
    }

    func initForNewHome(_ tabVC: MainTabBarVC? = nil) {
        tabBarVC = tabVC
        SOCKET_MANAGER.initialize()
        getLivedEventsForEnding()
        checkShareContents()
    }

    
    func initializeForLogout() {
        liveEvent = nil
        USER_MANAGER.initializeUserInfo()
        SOCKET_MANAGER.initializeForLogout()
        APPLICATION.applicationIconBadgeNumber = 0
        USER_MANAGER.countUnviewedNotify = 0
        USER_MANAGER.countUnviewedChatMsg = 0
    }
    
    func logOut(sender: UIViewController? = nil) {
        ((sender ?? topVC) as? PlansBaseVC)?.logOut()
    }
    
}

// MARK: - Go to Landing, Auth
extension AppManager {
    
    func gotoFirstVC() {
        // Go to First screen
        if let userId = USER_MANAGER.userId, userId != "" {
            startHomeVC()
        }else {
            gotoTutorialGuide()
        }
    }

    func gotoTutorialGuide() {
        print("APP_MANAGER ------ Tutorial Guide VC")
        initializeForLogout()
        setRootVC(TutorialVC.self)
   }
    
    func gotoLandingVC() {
        print("APP_MANAGER ------ LandingVC VC")
        initializeForLogout()
        setRootVC(LandingVC.self)
    }

    func pushLoginVC() {
        pushViewController(LoginVC.self)
    }

    func pushResetPassword() {
        pushViewController(ResetPasswordVC.self)
    }
    
    func pushPinCodeVC (delegate: PinCodeVCDelegate? = nil, sender : UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(PinCodeVC.className) as? PinCodeVC else { return }
        vc.delegate = delegate
        pushViewController(vc, sender: sender)
    }
    
    func pushConfirmCodeVC(userModel : UserModel?, sender : UIViewController? = nil) {
        guard let user = userModel else { return }
        guard let vc = STORY_MANAGER.viewController(ConfirmCodeVC.className) as? ConfirmCodeVC else { return }
        vc.userModel = user
        vc.isSkipMode = (sender as? AuthBaseVC)?.isSkipMode ?? false
        pushViewController(vc, sender: sender)
    }
    
    func pushNewPassVC(_ userModel : UserModel?, sender: UIViewController? = nil) {
        guard let user = userModel else { return }
        guard let vc = STORY_MANAGER.viewController(NewPasswordVC.className) as? NewPasswordVC else { return }
        vc.userModel = user
        pushViewController(vc, sender: sender)
    }
    
    func pushNextStepForSignUp(_ userModel : UserModel? = nil, skipMode: Bool = false, sender: UIViewController? = nil) {
        
        let userModel = userModel ?? UserModel()
        var authVC : AuthBaseVC?

        if skipMode == true {
            if userModel.mobile == nil || userModel.mobile == "" {
                authVC = STORY_MANAGER.viewController(SignUpNumVC.className) as? SignUpNumVC
            }else if userModel.firstName == nil || userModel.firstName == "" ||
                userModel.lastName == nil || userModel.lastName == "" {
                authVC = STORY_MANAGER.viewController(SignUpNameVC.className) as? SignUpNameVC
            }else if userModel.email == nil || userModel.email == "" {
                authVC = STORY_MANAGER.viewController(SignUpEmailVC.className) as? SignUpEmailVC
            }else if userModel.dob == nil || userModel.dob == 0 {
                authVC = STORY_MANAGER.viewController(SignUpBirthVC.className) as? SignUpBirthVC
            }else if userModel.password == nil || userModel.password == "" {
                authVC = STORY_MANAGER.viewController(SignUpPasswordVC.className) as? SignUpPasswordVC
            }else if userModel.profileImage == nil || userModel.profileImage == "" {
                authVC = STORY_MANAGER.viewController(SignUpProfilePictureVC.className) as? SignUpProfilePictureVC
            }else {
                startHomeVC()
            }
        }else {
            switch sender.self {
            case is LandingVC:
                authVC = STORY_MANAGER.viewController(SignUpNumVC.className) as? SignUpNumVC
                break
            case is SignUpNumVC, is ConfirmCodeVC:
                authVC = STORY_MANAGER.viewController(SignUpNameVC.className) as? SignUpNameVC
                break
            case is SignUpNameVC:
                authVC = STORY_MANAGER.viewController(SignUpEmailVC.className) as? SignUpEmailVC
                break
            case is SignUpEmailVC:
                authVC = STORY_MANAGER.viewController(SignUpBirthVC.className) as? SignUpBirthVC
                break
            case is SignUpBirthVC:
                authVC = STORY_MANAGER.viewController(SignUpPasswordVC.className) as? SignUpPasswordVC
                break
            case is SignUpPasswordVC:
                authVC = STORY_MANAGER.viewController(SignUpProfilePictureVC.className) as? SignUpProfilePictureVC
                break
            case is SignUpProfilePictureVC:
                startHomeVC()
                break
            default:
                break
            }
        }
        
        if let vc = authVC {
            vc.userModel = userModel
            vc.isSkipMode = skipMode
            pushViewController(vc, sender: sender)
        }
    }
    
}

// MARK: - Control Main Tab Bar
extension AppManager {
    func dismissAllPresentedVCs(tabIndex : Int? = nil) {
        guard let index = tabIndex, let tabNai = tabBarVC?.getTabItemVC(index) as? UINavigationController else { return }
        tabNai.presentedViewController?.dismiss(animated: false, completion: nil)
        tabNai.popToRootViewController(animated: false)
    }

    func gotoTabItemVC(tabIndex: Int) {
        rootNaviVC?.presentedViewController?.dismiss(animated: false, completion: nil)
        rootNaviVC?.popToRootViewController(animated: false)
        dismissAllPresentedVCs(tabIndex: selectedTabIndex)
        if tabIndex != selectedTabIndex {
            dismissAllPresentedVCs(tabIndex: tabIndex)
            tabBarVC?.selectTab(tabIndex)
        }
    }

    func gotoTabItemVC(tabType: MainTabBarVC.TabType) {
        guard let index = tabBarVC?.getTabIndex(tabType) else { return }
        gotoTabItemVC(tabIndex: index)
    }
    
    func updateTabBar(isHiddenCenterAction: Bool? = nil) {
        tabBarVC?.updateUI(isHiddenCenterAction: isHiddenCenterAction)
    }
    
    func updateBadges() {
        NOTIFI_SERVICE.getUnviewedNotifications().done { data in
            USER_MANAGER.countUnviewedChatMsg = data.listChatsUnviewed?.count ?? 0
            USER_MANAGER.countUnviewedNotify = data.listNotifyUnviewed?.count ?? 0
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshBadges), object: nil)
        }.catch { error in
            
        }
    }
}


// MARK: - Go to Home
extension AppManager {
    
    func startHomeVC() {
        print("APP_MANAGER ------ Start Home VC")
        setRootVC(MainTabBarVC.self)
    }
    
    func pushCalendarVC(event: EventFeedModel? = nil, sender: UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(CalendarVC.className) as? CalendarVC else { return }
        vc.selectedDate = event?.startDate != nil ? Date(timeIntervalSince1970: event!.startDate!) : nil
        vc.activeEvent = event
        pushViewController(vc, sender: sender)
    }
    
    func pushSearchEvents(_ sender: UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(SearchEventsVC.className) as? SearchEventsVC else { return }
        pushViewController(vc, sender: sender)
    }

    
    func pushHiddenEvents(_ sender: UIViewController? = nil) {
        pushViewController(HiddenEventsVC.self, sender: sender)
    }
    
}

// MARK: - Go to Profile
extension AppManager {
    func pushUserProfileVC(userId: String? = nil, userModel: UserModel? = nil, sender: UIViewController? = nil){
        guard let userId = (userId ?? userModel?._id ?? userModel?.userId ?? userModel?.friendId), userId != USER_MANAGER.userId else { return }
        guard let vc = STORY_MANAGER.viewController(UserProfileVC.className) as? UserProfileVC else { return }
        vc.userID = userId
        vc.activeUser = userModel
        pushViewController(vc, sender: sender)
    }
    
    func updateCoinNumber(new: Int?) {
        guard let new = new, USER_MANAGER.coinNumber != new else { return }
        tabBarVC?.popUpNewCoin(coin: new)
        USER_MANAGER.coinNumber = new
    }
    
    func pushSettingsVC(userModel: UserModel? = nil, sender: UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(SettingsVC.className) as? SettingsVC else { return }
        vc.activeUser = userModel
        pushViewController(vc, sender: sender)
    }
    
    func pushUserCoinVC(userId: String? = nil, user: UserModel? = nil, sender: UIViewController? = nil) {
        guard userId != nil || user != nil else { return }
        guard let vc = STORY_MANAGER.viewController(UserCoinVC.className) as? UserCoinVC else { return }
        vc.userID = userId
        vc.activeUser = user
        pushViewController(vc, sender: sender)
    }
    
}

// MARK: - User List
extension AppManager {
    func pushFriendListVC(userId: String? = nil,
                          user: UserModel? = nil,
                          sender: UIViewController? = nil) {
        
        guard let userId = userId ?? user?._id ?? user?.userId ?? user?.friendId else { return }
        guard let vc = STORY_MANAGER.viewController(FriendListVC.className) as? FriendListVC else {return}
        vc.userID = userId
        vc.activeUser = user
        pushViewController(vc, sender: sender)
    }
    
    func pushAddFriendsVC(userId: String? = nil,
                          user: UserModel? = nil,
                          sender: UIViewController? = nil) {
        
        guard let userId = userId ?? user?._id ?? user?.userId ?? user?.friendId else { return }
        guard let vc = STORY_MANAGER.viewController(AddFriendsVC.className) as? AddFriendsVC else {return}
        vc.userID = userId
        vc.activeUser = user
        pushViewController(vc, sender: sender)
    }

    
    func pushFriendsSelectionVC(typeSelect: FriendsSelectionVC.SelectType?,
                                delegate: FriendsSelectionVCDelegate? = nil,
                                selectedUsers: [UserModel]? = nil,
                                sender: UIViewController? = nil) {
        guard let typeSelect = typeSelect,
              let vc = STORY_MANAGER.viewController(FriendsSelectionVC.className) as? FriendsSelectionVC else { return }
        vc.typeSelect = typeSelect
        vc.delegate = delegate
        if let selectedUsers = selectedUsers {
            vc.listSelectedAlready.append(contentsOf: selectedUsers)
        }
        
        pushViewController(vc, sender: sender)
    }

}

// MARK: - Go to Event
extension AppManager {
    func pushCreateEventVC(place: PlaceModel? = nil, sender: UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(CreateEventVC.className) as? CreateEventVC else { return }
        vc.place = place
        pushViewController(vc, sender: sender)
    }
    
    func pushEventDetailsVC(eventId: String? = nil, event: EventFeedModel? = nil, sender:UIViewController? = nil) {
        guard eventId != nil || (event != nil && event?._id != nil && event?._id != "" ) else { return }
        guard let vc = STORY_MANAGER.viewController(EventDetailsVC.className) as? EventDetailsVC else { return }
        vc.eventID = eventId
        vc.activeEvent = event
        pushViewController(vc, sender: sender)
    }
    
    func pushInvitedPeopleVC(eventModel: EventFeedModel? = nil, eventId: String? = nil, sender:UIViewController? = nil) {
        guard eventModel != nil || eventId != nil else { return }
        guard let vc = STORY_MANAGER.viewController(InvitedPeopleVC.className) as? InvitedPeopleVC else { return }
        vc.eventID = eventId
        vc.activeEvent = eventModel
        pushViewController(vc, sender: sender)
    }
    
    func pushEditEventVC(event: EventFeedModel? = nil, isDuplicate: Bool = false, sender: UIViewController? = nil ) {
        guard let event = event else { return }
        guard let vc = STORY_MANAGER.viewController(EditEventVC.className) as? EditEventVC else { return }
        vc.isDuplicate = isDuplicate
        vc.activeEvent = event
        pushViewController(vc, sender: sender)
    }
    
    func pushEditInvitationVC(editMode: EditInvitationVC.EditMode, selectedUsers: [UserModel]? = nil, delegate: EditInvitationVCDelegate? = nil, sender: UIViewController? = nil) {
        
        guard let vc = STORY_MANAGER.viewController(EditInvitationVC.className) as? EditInvitationVC else { return }
        vc.editMode = editMode
        vc.delegate = delegate
        vc.selectedUsers = selectedUsers
        pushViewController(vc, sender: sender)
    }
    
    func pushDetailsOfEventVC(event: EventFeedModel? = nil, sender: UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(DetailsOfEventVC.className) as? DetailsOfEventVC else { return }
        vc.activeEvent = event
        pushViewController(vc, sender: sender)
    }

    
    func shareEvent(event: EventFeedModel?, isInviting: Bool = false, sender: UIViewController? = nil, complition: UIActivityViewController.CompletionWithItemsHandler? = nil) {

        guard let event = event, let eventName = event.eventName else { return }
        
        var url = ""
        var text = ""
        if isInviting == true {
            url = event.eventLink?.invitation ?? ""
            text = "Hi, I'm inviting you to \"\(eventName)\". Download the Plans app to attend and share now!\n\(url)"
        }else {
            url = event.eventLink?.share ?? ""
            text = "Check out the event \"\(eventName)\" on the Plans app!\n\(url)"
        }

        let type = event.mediaType
        let urlMeida = event.imageOrVideo

        shareContents(text: text,
                      typeMedia: type,
                      urlMedia: urlMeida,
                      sender: sender,
                      complition: complition)
    }
    
    func presentInviteByLinkVC (event: EventFeedModel? = nil, sender : UIViewController? = nil) {
        guard let event = event, let vc = STORY_MANAGER.viewController(InviteByLinkVC.className) as? InviteByLinkVC else { return }
        vc.activeEvent = event
        presentViewController(vc, sender: sender)
    }

    
}


// MARK: - Go to Chat
extension AppManager {
    func pushChatListVC(sender: UIViewController? = nil, notify: NotificationActivityModel? = nil) {
        guard let vc = STORY_MANAGER.viewController(ChatListVC.className) as? ChatListVC else { return }
        pushViewController(vc, sender: sender)
        
        guard let chatId = notify?.chatId, !chatId.isEmpty else { return }
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.3) {
            self.pushChatMessageVC(chatId: chatId, sender: vc)
        }
    }
    
    func pushChatMessageVC(chatModel:   ChatModel? = nil,
                           chatId:      String? = nil,
                           event:       EventFeedModel? = nil,
                           otherUser:   UserModel? = nil,
                           sender:      UIViewController? = nil) {
        
        let members: [UserModel]? = otherUser != nil ? [UserModel(userId: USER_MANAGER.userId), otherUser!] : nil

        guard let chatModel = chatModel ?? ChatModel(id: chatId, event: event, members: members) else { return }
        guard let vc = STORY_MANAGER.viewController(ChatMessageVC.className) as? ChatMessageVC else { return }
        vc.chatModel = chatModel
        vc.activeEvent = chatModel.event
        pushViewController(vc, sender: sender)
    }
    
    func pushChatSettings(chat: ChatModel? = nil, sender: UIViewController? = nil){
        guard let chat = chat,
              let vc = STORY_MANAGER.viewController(ChatSettingsVC.className) as? ChatSettingsVC else { return }
        vc.chatModel = chat
        pushViewController(vc, sender: sender)
    }
    
    func pushAssignAdminForGroupChat(chatId: String?, sender: UIViewController? = nil) {
        guard let chatId = chatId,
              let vc = STORY_MANAGER.viewController(AssignAdminForGroupChatVC.className) as? AssignAdminForGroupChatVC else { return }
        
        vc.chatId = chatId
        pushViewController(vc, sender: sender)
    }
    
    
}

// MARK: - Go to Post
extension AppManager {
    func pushEventAndPostVC(eventId: String?, postId: String?, sender: UIViewController? = nil) {
        guard let eventId = eventId, let postId = postId else { return }
        guard let vcEvent = STORY_MANAGER.viewController(EventDetailsVC.className) as? EventDetailsVC,
              let vcPopst = STORY_MANAGER.viewController(PostCommentVC.className) as? PostCommentVC else { return }

        vcEvent.eventID = eventId
        vcPopst.eventID = eventId
        vcPopst.postID = postId
        
        pushViewControllers([vcEvent, vcPopst], sender: sender)
    }
    
    func pushPostCommentVC(eventId: String?, postId: String?, sender: UIViewController? = nil) {
        guard let eventId = eventId, let postId = postId else { return }
        guard let vc = STORY_MANAGER.viewController(PostCommentVC.className) as? PostCommentVC else { return }
        vc.eventID = eventId
        vc.postID = postId
        pushViewController(vc, sender: sender)
    }
    
    func pushLikesVC(postId: String? = nil, post: PostModel? = nil, sender: UIViewController? = nil) {
        guard let postId = postId ?? post?._id else { return }
        guard let vc = STORY_MANAGER.viewController(LikesVC.className) as? LikesVC else { return }
        vc.postID = postId
        vc.postDetail = post
        pushViewController(vc, sender:  sender)
    }
    
    func likeContent(content: PostModel?, isLike: Bool = true, sender: UIViewController? = nil) {
        if content?.isComment == true {
            guard let vc = (sender ?? topVC) as? PostCommentBaseVC else { return }
            vc.likeComment(comment: content, isLike: isLike)
        }else {
            guard let vc = (sender ?? topVC) as? EventBaseVC else { return }
            vc.likeUnlikePost(postId: content?._id, eventId: vc.eventID, isLike: isLike)
        }
    }
    
    func likeUnlikePost(postId: String?, eventId: String?, isLike: Bool, sender: UIViewController? = nil) {
        guard let postId = postId, let eventId = eventId else { return }
        ((sender ?? topVC) as? PlansContentBaseVC)?.likeUnlikePost(postId: postId, eventId: eventId, isLike: isLike)
    }

    func sharePost(post: PostModel?, event: EventFeedModel? = nil, postParent: PostModel? = nil, sender: UIViewController? = nil, complition: UIActivityViewController.CompletionWithItemsHandler? = nil ) {
        guard let post = post else { return }

        let parentVC = (sender ?? topVC) as? BaseViewController
        parentVC?.showLoader()

        createShareLink(content: post, event: event, post: postParent) { (url) in
            parentVC?.hideLoader()
            guard let shareLink = url else { return }
            var text = ""
            var typeMedia, urlMedia : String?
            
            if post.isComment == true {
                if let commentText = post.commentText, commentText.count > 0 {
                    text = "\"\(commentText)\""
                }
                if text.count > 0 {
                    text += "\n"
                }
                text += "Check out this comment from the event \"\(event?.eventName ?? "")\" on the Plans app!"
                typeMedia = post.commentType
                urlMedia = post.commentMedia
            }else {
                if let postText = post.postText, postText.count > 0 {
                    text = "\"\(postText)\""
                }
                if text.count > 0 {
                    text += "\n"
                }
                text += "Check out this post from the event \"\(event?.eventName ?? "")\" on the Plans app!"
                typeMedia = post.postType
                urlMedia = post.postMedia
            }
            
            self.shareContents(text: text,
                          typeMedia: typeMedia,
                          urlMedia: urlMedia,
                          urlAdditional: shareLink,
                          sender: sender,
                          complition: complition)
        }
    }
    
}

// MARK: - Go to LiveMoment
extension AppManager {
    func pushLiveMomentCameraVC(event: EventFeedModel?, sender: UIViewController? = nil){
        guard let event = event else { return }
        guard let vc = STORY_MANAGER.viewController(LiveMomentCameraVC.className) as? LiveMomentCameraVC else { return }
        vc.activeEvent = event
        pushViewController(vc, sender: sender)
    }

    func pushLiveMomentsVC(event: EventFeedModel? = nil, eventId: String? = nil, sender: UIViewController? = nil) {
        guard event != nil || eventId != nil else { return }
        guard let vc = STORY_MANAGER.viewController(LiveMomentsVC.className) as? LiveMomentsVC else { return }
        vc.eventID = eventId
        vc.activeEvent = event
        pushViewController(vc, sender: sender)
    }
    
    func pushWatchLiveMomentsVC(eventId: String? = nil,
                                event: EventFeedModel? = nil,
                                userId: String? = nil,
                                user: UserModel? = nil,
                                liveMomentId: String? = nil,
                                liveMoment: LiveMomentModel? = nil,
                                sender: UIViewController? = nil) {

        let eventId = eventId ?? event?._id
        let userId = userId ?? user?._id ?? user?.userId
        let liveMomentId = liveMomentId ?? liveMoment?._id
        
        guard liveMomentId != nil || eventId != nil || (eventId != nil && userId != nil) else { return }
        guard let vc = STORY_MANAGER.viewController(WatchLiveMomentsVC.className) as? WatchLiveMomentsVC else { return }
        
        vc.eventID = eventId
        vc.activeEvent = event
        vc.userId = userId
        vc.user = user
        vc.liveMomentId = liveMomentId
        vc.liveMoment = liveMoment
        
        pushViewController(vc, sender: sender)
    }


}

// MARK: - Go to Location
extension AppManager {

    func pushSearchLocation(_ sender: UIViewController? = nil,
                            delegate: LocationSearchDelegate? = nil,
                            searchType: LocationSearchType = .locationDiscovery) {
        guard let vc = STORY_MANAGER.viewController(LocationSearchVC.className) as? LocationSearchVC else { return }
        vc.delegate = delegate
        vc.searchType = searchType
        pushViewController(vc, sender: sender)
    }

    func pushLocationDiscoveryVC(searchType: LocationSearchType = .locationDiscovery,
                            sender: UIViewController? = nil) {
        guard let vc = STORY_MANAGER.viewController(LocationDiscoveryVC.className) as? LocationDiscoveryVC else { return }
        vc.searchType = searchType
        pushViewController(vc, sender: sender)
    }

    func pushPlaceDetailsVC(place: PlaceModel?,
                            sender: UIViewController? = nil,
                            searchType: LocationSearchType = .locationDiscovery) {
        guard let place = place else { return }
        guard let vc = STORY_MANAGER.viewController(PlaceDetailsVC.className) as? PlaceDetailsVC else { return }
        vc.placeModel = place
        vc.searchType = searchType
        pushViewController(vc, sender: sender)
    }
    

    func openMap(eventModel: EventFeedModel? = nil, sender: UIViewController? = nil) {
        
        var latitude: Double = 45.536945
        var longitude: Double = -73.510712
        var placeName = "TBD"

        if let event = eventModel {
            if let latt = event.lat{
                latitude = Double(latt)
            }
            if let longg = event.long{
                longitude = Double(longg)
            }
            if let locationName = event.locationName,
                locationName != ""{
                placeName = locationName
            } else {
                if let address = event.address,
                    address != "" {
                    placeName = address
                }
            }
        }
     
        (sender ?? topVC)?.openMap(CLLocationCoordinate2D(latitude: latitude, longitude: longitude), name: placeName)
    }
    
    func openMapForDirections(event: EventFeedModel?, sender: UIViewController? = nil) {
        guard let lat = event?.lat, let long = event?.long else { return }
        
        let source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: USER_MANAGER.latitude, longitude: USER_MANAGER.longitude)))
        source.name = "Source"
        
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)))
        destination.name = event?.locationName

        (sender ?? topVC)?.openMapForDirections(sourcMapItem: source, destMapItem: destination)
    }

}

// MARK: - Notifications
extension AppManager {
    func pushEventInvitationsVC(_ sender: UIViewController? = nil) {
        pushViewController(EventInvitationsVC.self, sender: sender)
    }
    
    func pushFriendRequestsVC(_ sender: UIViewController? = nil) {
        pushViewController(FriendRequestsVC.self, sender: sender)
    }

}



// MARK: - Go to Help Legal
extension AppManager {
    func pushTermsOfServices() {
        pushViewController(TermsOfServices.self)
    }
    
    func pushPrivacyPolicy() {
        pushViewController(PrivacyPolicyVC.self)
    }

}

// MARK: - Go to Camera
extension AppManager {
    
    func presentPlansCamera(delegate: PlansCameraVCDelegate? = nil, maxVideoDuration: TimeInterval = 30, sender: UIViewController? = nil, mediaType: MediaPicker.MediaType = .allMedia) {
        guard let vc = STORY_MANAGER.viewController(PlansCameraVC.className) as? PlansCameraVC else { return }
        vc.delegate = delegate
        vc.maxVideoDuration = maxVideoDuration
        vc.mediaType = mediaType
        presentViewController(vc, sender: sender)
    }

}


// MARK: - Contents Shared
extension AppManager {
    func handleIncomingDynamicLink(_ link: URL?) {
        guard let dicParams = USER_MANAGER.addShareContent(link) else { return }
        guard USER_MANAGER.isLogined == true else { return }

        getShareContents(dicParams)
    }

    func checkShareContents() {
        let contents = USER_MANAGER.listShareContents
        contents.forEach { (dicItem) in
            getShareContents(dicItem)
        }
    }

    func getShareContents(_ params: [String: String]) {
        EVENT_SERVICE.getShareContent(params).done { (dicResult) in
            USER_MANAGER.removeShareContent(params)

            var shareContent = params
            if let statusCode = dicResult["statusCode"] as? Int {
                if let message = dicResult["message"] as? String, message.count > 0 {
                    POPUP_MANAGER.makeToast(message)
                }
                switch statusCode {
                case 0, 3, 5:
                    self.showShareContent(shareContent)
                    break
                case 9: // When the Post was already deleted
                    shareContent.removeValue(forKey: "postId")
                    self.showShareContent(shareContent)
                    break
                case 10: // When the Comment was already deleted
                    shareContent.removeValue(forKey: "commentId")
                    self.showShareContent(shareContent)
                    break
                case 201:
                    self.showShareContent(shareContent)
                    break
                case 202:
                    self.showShareContent(shareContent, isFriendRequest: true)
                    break
                default:
                    break
                }
            }
        }.catch { (error) in
            POPUP_MANAGER.handleError(error)
        }

    }
    
    func showShareContent(_ params: [String: String], isFriendRequest: Bool = false) {
        
        let eventId = params["eventId"]
        let postId = params["postId"]
        let hostId = params["hostId"]

        gotoTabItemVC(tabType: .home)
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.5) {
            if isFriendRequest == true {
                self.pushUserProfileVC(userId: hostId)
            }else if let eventId = eventId {
                self.pushEventDetailsVC(eventId: eventId)
                if let postId = postId {
                    APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.5) {
                        self.pushPostCommentVC(eventId: eventId, postId: postId)
                    }
                }
            }
        }

    }

}

// MARK: - Remove ViewControllers by force
extension AppManager {
    func removeAllEventScreens (eventId: String?) {
        guard let eventId = eventId else { return }
        tabBarVC?.viewControllers?.forEach({ (tabItemVC) in
            if let itemNavi = tabItemVC as? UINavigationController {
                itemNavi.viewControllers.removeAll { (itemVC) -> Bool in
                    if let basedVC = itemVC as? EventBaseVC {
                        if basedVC.activeEvent?._id == eventId {
                            return true
                        }
                        if basedVC.eventID == eventId {
                            return true
                        }
                    }
                    return false
                }
            }
        })
        
        if let topMostVC = topVC as? EventBaseVC {
            if topMostVC.activeEvent?._id == eventId {
                topMostVC.dismiss(animated: false)
            }
        }
    }
    
    func forceUserOutsideFromEvent (eventId: String?) {
        guard let eventId = eventId else { return }
        tabBarVC?.viewControllers?.forEach({ (tabItemVC) in
            if let itemNavi = tabItemVC as? UINavigationController {
                itemNavi.viewControllers.removeAll { (itemVC) -> Bool in
                    if let basedVC = itemVC as? EventBaseVC, let eventModel = basedVC.activeEvent {
                        if eventModel._id == eventId, eventModel.userId != USER_MANAGER.userId {
                            return true
                        }
                        if basedVC.eventID == eventId, eventModel.userId != USER_MANAGER.userId {
                            return true
                        }
                    }
                    return false
                }
            }
        })
        
        if let topMostVC = topVC as? EventBaseVC, let eventModel = topMostVC.activeEvent {
            if eventModel._id == eventId, eventModel.userId != USER_MANAGER.userId {
                topMostVC.dismiss(animated: false)
            }
        }
        
    }
    
    func forceUserOutsideFromUser(userId: String?) {
        guard let userId = userId else { return }
        tabBarVC?.viewControllers?.forEach({ (tabItemVC) in
            if let itemNavi = tabItemVC as? UINavigationController {
                itemNavi.viewControllers.removeAll { (itemVC) -> Bool in
                    return checkVCRelatedWithUser(userId: userId, vc: itemVC)
                }
            }
        })
        
        if let topVC = topVC, checkVCRelatedWithUser(userId: userId, vc: topVC) == true {
            if let naviVC = topVC.navigationController {
                naviVC.popViewController(animated: true)
            }else {
                topVC.dismiss(animated: false)
            }
        }
    }
    
    func checkVCRelatedWithUser(userId: String?, vc: UIViewController?) -> Bool {
        var result = false
        guard let userId = userId, let vc = vc else { return result }
        
        if let vc = vc as? EventBaseVC, vc.activeEvent?.userId == userId {
            result = true
        }else if let vc = vc as? ChatMessageVC, vc.chatModel?.isGroup == false, vc.chatModel?.profileUser?._id == userId  {
            result = true
        }else if let vc = vc as? UserProfileVC, vc.userID == userId {
            result = true
        }
        
        return result
    }

}

// MARK: - Control Hosted Events
extension AppManager {
    func getLivedEventsForEnding() {
        hostedEvents.removeAll()
        guard USER_MANAGER.isLogined == true else { return }
        EVENT_SERVICE.getLivedEventsForEnding().done { (hostedEvents) -> Void in
            self.hostedEvents.append(contentsOf: hostedEvents)
            APP_CONFIG.defautMainQ.async {
                self.showPopupEndEvent()
            }
        }.catch { (error) in
            POPUP_MANAGER.handleError(error)
        }
    }

    func showPopupEndEvent( index : Int = 0) {
        guard index < hostedEvents.count else {
            popupAlert?.dismiss(animated: false)
            hostedEvents.removeAll()
            return
        }
        let event = hostedEvents[index]
        let message = "All guests left your event! Do you want to end \(event.eventName ?? "")?"
        let attributedMsg = "All guests left your event! Do you want to end <bold>\(event.eventName ?? "")</bold>?"
        popupAlert = topVC?.showPlansAlertYesNo(message: message, attributedMsg: attributedMsg, titleYes: "Keep Live", colorYesBtn: AppColor.teal_main, titleNo: "End",
        actionYes: {
            EVENT_SERVICE.keepLivedEvent(["eventId": event._id ?? ""]).done { ( newEvent) in
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            }.catch { (error) in
                POPUP_MANAGER.handleError(error)
            }
        },
        actionNo: {
            let dict = ["eventId": event._id ?? "",
                        "isEnded": "1" ] as [String : Any]
            EVENT_SERVICE.hitEndEvent(dict).done { (response) -> Void in
                if let msg = response.message,
                    msg != "" {
                    NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                    POPUP_MANAGER.makeToast(msg)
                }
            }.catch { (error) in
                POPUP_MANAGER.handleError(error)
            }
            
        }, complete: {
            self.showPopupEndEvent(index: index + 1)
        }, blurEnabled: true )

    }

}

// MARK: - Share Contents
extension AppManager {
    
    func createShareLink(content: Any?, event: EventFeedModel? = nil, post: PostModel? = nil, complete: ((URL?) -> Void)? = nil) {
        var dicParams : [String: String]? = nil
        var title: String? = nil
        var text: String? = nil
        var description: String? = nil
        var imageUrl : String? = nil

        if let content = content as? EventFeedModel {
            dicParams = [String: String]()
            dicParams?["type"] = "event_share"
            dicParams?["eventId"] = content._id ?? ""
            text = content.eventName
            description = "Check out the event \"\(content.eventName ?? "")\" on the Plans app!"
            imageUrl = content.mediaType == "video" ? content.thumbnail : content.imageOrVideo
        }else if let content = content as? PostModel, let event = event {
            dicParams = [String: String]()
            if content.isComment == true, let post = post {
                dicParams?["type"] = "comment_share"
                dicParams?["eventId"] = event._id ?? ""
                dicParams?["postId"] = post._id ?? ""
                dicParams?["commentId"] = content._id ?? ""
                text = content.commentText
                description = "Check out this comment from the event \"\(event.eventName ?? "")\" on the Plans app!"
            }else {
                dicParams?["type"] = "post_share"
                dicParams?["eventId"] = event._id ?? ""
                dicParams?["postId"] = content._id ?? ""
                text = content.postText
                description = "Check out this post from the event \"\(event.eventName ?? "")\" on the Plans app!"
                if content.postType == "video" {
                    imageUrl = content.postThumbnail
                }else if content.postType == "image" {
                    imageUrl = content.postMedia
                }
            }
        }
        
        if let text = text, text.count > 0 {
            title = "\"\(text)\""
        }
        
        guard let queryString = dicParams?.queryString, let link = URL(string: AppLinks.webSite_base + queryString) else {
            complete?(nil)
            return }
        var domainURIPrefix = AppLinks.dynamic_link_prefix_share
        if dicParams?["type"] == "event_invitation" {
            domainURIPrefix = AppLinks.dynamic_link_prefix_invite
        }
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: domainURIPrefix)

        // General Settings
        // Title, Description and Image
        linkBuilder?.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        linkBuilder?.socialMetaTagParameters?.title = title ?? description
        linkBuilder?.socialMetaTagParameters?.descriptionText = (title != nil ? description : nil)
        linkBuilder?.socialMetaTagParameters?.imageURL = URL(string: imageUrl)

        // Navigation Settings
        linkBuilder?.navigationInfoParameters = DynamicLinkNavigationInfoParameters()
        linkBuilder?.navigationInfoParameters?.isForcedRedirectEnabled = true
        
        // Short path settings for this link
        linkBuilder?.options = DynamicLinkComponentsOptions()
        linkBuilder?.options?.pathLength = .short

        // iOS settings
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: Bundle.main.bundleIdentifier ?? "")
        linkBuilder?.iOSParameters?.appStoreID = APP_CONFIG.ID_APPSTORE
        linkBuilder?.iOSParameters?.minimumAppVersion = "1.0"
        
        // iTunesconnect Settings
//        linkBuilder?.iTunesConnectParameters = DynamicLinkItunesConnectAnalyticsParameters()
//        linkBuilder?.iTunesConnectParameters?.providerToken = "123456"
//        linkBuilder?.iTunesConnectParameters?.campaignToken = "example-promo"

        // Android Settings
        linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: Android.packageName)
        linkBuilder?.androidParameters?.minimumVersion = 1
//        linkBuilder?.analyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: "orkut",
//                                                                               medium: "social",
//                                                                               campaign: "example-promo")

        guard let longDynamicLink = linkBuilder?.url else {
            complete?(nil)
            return
        }
        print("The long URL is: \(longDynamicLink)")
        linkBuilder?.shorten(completion: { (url, warnings, error) in
            guard let url = url, error == nil else {
                complete?(nil)
                return
            }
            complete?(url)
        })
    }

    
    func shareContents(text: String? = nil,
                       typeMedia: String? = nil,
                       urlMedia: String? = nil,
                       urlAdditional: URL? = nil,
                       sender: UIViewController? = nil,
                       complition: UIActivityViewController.CompletionWithItemsHandler? = nil ) {

        guard text != nil || (typeMedia != nil && urlMedia != nil) || urlAdditional != nil else { return }

        var items = [Any]()
        var itemText: String = ""
        var type = "text"
        var urlDownload: String = ""
        
        // Detect media type and Url for downloading
        if typeMedia == nil || typeMedia! == "text" || typeMedia! == "" {
            type = "text"
        }else if let media = urlMedia, let _ = URL(string: media) {
            if typeMedia == "image" {
                type = "image"
            }else if typeMedia == "video" {
                type = "video"
            }
            urlDownload = media
        }

        // Text
        if let text = text, text != "" {
            itemText = text
        }

        if let shareLink = urlAdditional?.absoluteString, shareLink != "" {
            if itemText.count > 0 {
                itemText += "\n"
            }
            itemText += "\(shareLink)"
        }

        if itemText.count > 0 {
            items.append(itemText as Any)
        }
        

        if type == "text" { //////////////////// TEXT //////////////////
            // Show the default share activity viewcontroller of iOS.
            showShareActivity(items: items, sender: sender, complition: complition)
            
        }else { //////////////////// Image/Video //////////////////
            // Download the media file from the server.
            let parentVC = (sender ?? topVC) as? BaseViewController
            parentVC?.showLoader("Loading...")
            FILE_CENTER.downloadMediaToLocal(url: urlDownload, type: type) { (localFile, error) in
                parentVC?.hideLoader()
                if error == nil, let fileUrl = localFile {
                    if type == "image" {
                        items.append(UIImage(contentsOfFile: fileUrl.path) as Any)
                    }else {
                        items.append(fileUrl as Any)
                    }
                    // Show the default share activity viewcontroller of iOS.
                    self.showShareActivity(items: items, sender: sender, complition: complition)
                }
            }
        }

    }
    
    func showShareActivity(items: [Any]?, sender: UIViewController? = nil, complition: UIActivityViewController.CompletionWithItemsHandler? = nil ) {
        guard let items = items, items.count > 0 else { return }
        let parentVC = sender ?? topVC
        parentVC?.navigationController?.visibleViewController?.dismiss(animated: false)
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = complition ?? complitionShareActivity
        parentVC?.present(activityViewController, animated: true, completion: nil)
    }
    
    func complitionShareActivity(typeActvity: UIActivity.ActivityType?, success: Bool, items: [Any]?, error: Error?) {
        if success == true {
        }
    }

}


// MARK: - Common Function
extension AppManager {
    
    func playVideo(_ urlStr : String?, sender: UIViewController? = nil) {
        (sender ?? topVC)?.playVideo(urlStr)
    }
    
    func openImageVC(imgStr: String? = nil, image: UIImage? = nil, title : String? = nil, activeEvent: EventFeedModel? = nil, sender: UIViewController? = nil) {
        guard (imgStr != nil && imgStr != "") || image != nil else { return }
        guard let vc = STORY_MANAGER.viewController(OpenImageVC.className) as? OpenImageVC else { return }
        vc.eventName = title
        vc.imageStr = imgStr
        vc.image = image
        vc.activeEvent = activeEvent
        pushViewController(vc, sender: sender)
    }

    
}
