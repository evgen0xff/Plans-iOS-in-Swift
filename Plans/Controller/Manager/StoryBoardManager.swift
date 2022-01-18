//
//  StoryBoardManager.swift
//  Plans
//
//  Created by Star on 7/7/20.
//  Copyright © 2020 PlansCollective. All rights reserved.
//

import UIKit

let STORY_MANAGER = StoryBoardManager.share

class StoryBoardManager : NSObject {
    
    static let share = StoryBoardManager()
    
    enum StoryboardIdentifier : String {
        case auth               = "Auth"
        case signUp             = "SignUp"
        case helpLegal          = "HelpLegal"
        case camera             = "Camera"
        case main               = "Main"
        case home               = "Home"
        case location           = "Location"
        case notification       = "Notification"
        case chat               = "Chat"
        case profile            = "Profile"
        case event              = "Event"
        case liveMoment         = "LiveMoment"
        case post               = "Post"
        case users              = "Users"
        case settings           = "Settings"
    }

    enum ViewControllerIdentifier : String {
        // Main storyboard
        case tutorialVC             = "TutorialVC"
        case landingVC              = "LandingVC"
        case mainTabBarVC           = "MainTabBarVC"

        // Auth
        case loginVC                = "LoginVC"
        case resetPasswordVC        = "ResetPasswordVC"
        case pinCodeVC              = "PinCodeVC"
        case confirmCodeVC          = "ConfirmCodeVC"
        case newPasswordVC          = "NewPasswordVC"
        
        // SignUp
        case signUpNumVC            = "SignUpNumVC"
        case signUpNameVC           = "SignUpNameVC"
        case signUpEmailVC          = "SignUpEmailVC"
        case signUpBirthVC          = "SignUpBirthVC"
        case signUpPasswordVC       = "SignUpPasswordVC"
        case signUpProfilePictureVC = "SignUpProfilePictureVC"

        // Help Legal
        case helpLegalVC            = "HelpLegalVC"
        case termsOfServicesVC      = "TermsOfServices"
        case privacyPolicyVC        = "PrivacyPolicyVC"
        
        // Camera
        case plansCameraVC          = "PlansCameraVC"
        case liveMomentCameraVC     = "LiveMomentCameraVC"
        case openImageVC            = "OpenImageVC"
        
        // Home
        case homeVC                 = "HomeVC"
        case calendarVC             = "CalendarVC"
        case searchEventsVC         = "SearchEventsVC"
        case hiddenEventsVC         = "HiddenEventsVC"
        
        // Event
        case eventDetailsVC         = "EventDetailsVC"
        case createEventVC          = "CreateEventVC"
        case createEventProgress1VC = "CreateEventProgress1VC"
        case createEventProgress2VC = "CreateEventProgress2VC"
        case createEventProgress3VC = "CreateEventProgress3VC"
        case detailsOfEventVC       = "DetailsOfEventVC"
        case editEventVC            = "EditEventVC"
        case editInvitationVC       = "EditInvitationVC"
        case invitedPeopleVC        = "InvitedPeopleVC"
        case inviteByLinkVC         = "InviteByLinkVC"
        
        // Live Moment
        case watchLiveMomentsVC     = "WatchLiveMomentsVC"
        case liveMomentsVC          = "LiveMomentsVC"
        
        // Post
        case postCommentVC          = "PostCommentVC"
        case likesVC                = "LikesVC"
        
        // Location
        case locationDiscoveryVC    = "LocationDiscoveryVC"
        case locationSearchVC       = "LocationSearchVC"
        case placeDetailsVC         = "PlaceDetailsVC"
        
        // Notification
        case notificationListVC     = "NotificationListVC"
        case friendRequestsVC       = "FriendRequestsVC"
        case eventInvitationsVC     = "EventInvitationsVC"
        
        // Chat
        case chatListVC             = "ChatListVC"
        case chatMessageVC          = "ChatMessageVC"
        case chatSettingsVC         = "ChatSettingsVC"
        
        // Profile
        case myProfileVC            = "MyProfileVC"
        case userCoinVC             = "UserCoinVC"
        case userProfileVC          = "UserProfileVC"
        case editProfileVC          = "EditProfileVC"
        case editBioVC              = "EditBioVC"
        
        // User list
        case friendListVC           = "FriendListVC"
        case addFriendsVC           = "AddFriendsVC"
        case blockedUserVC          = "BlockedUserVC"
        case friendsSelectionVC     = "FriendsSelectionVC"
        case assignAdminForGroupChatVC = "AssignAdminForGroupChatVC"
        
        // Settings
        case settingsVC             = "SettingsVC"
        case changePasswordVC       = "ChangePasswordVC"
        case postsLikedVC           = "PostsLikedVC"
        case settingPushNotifyVC    = "SettingPushNotifyVC"
        case privacyOptionVC        = "PrivacyOptionVC"
        case sendFeedbackVC         = "SendFeedbackVC"

        var storyboard : StoryboardIdentifier? {
            switch self {
            // Main
            case .tutorialVC,
                 .landingVC,
                 .mainTabBarVC:
                
                return .main
                
            // Auth
            case .loginVC,
                 .resetPasswordVC,
                 .pinCodeVC,
                 .confirmCodeVC,
                 .newPasswordVC:
                
                return .auth
                
            // SignUp
            case .signUpNumVC,
                 .signUpNameVC,
                 .signUpEmailVC,
                 .signUpBirthVC,
                 .signUpPasswordVC,
                 .signUpProfilePictureVC:
                
                return .signUp
                
            // Help Legals
            case .termsOfServicesVC,
                 .privacyPolicyVC,
                 .helpLegalVC:
                
                return .helpLegal
                
            // Camera
            case .plansCameraVC,
                 .liveMomentCameraVC,
                 .openImageVC :
                
                return .camera
            
            // Home
            case .homeVC,
                 .calendarVC,
                 .searchEventsVC,
                 .hiddenEventsVC:
                
                return .home
            
            // Event
            case .eventDetailsVC,
                 .createEventVC,
                 .detailsOfEventVC,
                 .editEventVC,
                 .editInvitationVC,
                 .invitedPeopleVC,
                 .createEventProgress1VC,
                 .createEventProgress2VC,
                 .createEventProgress3VC,
                 .inviteByLinkVC:
                
                return .event
            
            // Live Moments
            case .watchLiveMomentsVC,
                 .liveMomentsVC :
                
                return .liveMoment
            
            // Post Comment
            case .postCommentVC,
                 .likesVC:
                
                return .post
                
            // Location
            case .locationDiscoveryVC,
                 .locationSearchVC,
                 .placeDetailsVC:
                
                return .location
                
            // Notification
            case .notificationListVC,
                .friendRequestsVC,
                .eventInvitationsVC:
                
                return .notification
                
            // Chat
            case .chatListVC,
                 .chatMessageVC,
                 .chatSettingsVC:
                
                return .chat
                
            // Profile
            case .myProfileVC,
                 .userCoinVC,
                 .userProfileVC,
                 .editProfileVC,
                 .editBioVC:

                return .profile

            // User List
            case .friendListVC,
                 .addFriendsVC,
                 .blockedUserVC,
                 .friendsSelectionVC,
                 .assignAdminForGroupChatVC:

                return .users
                
            // Settings
            case .settingsVC,
                 .changePasswordVC,
                 .postsLikedVC,
                 .settingPushNotifyVC,
                 .privacyOptionVC,
                 .sendFeedbackVC:
                
                return .settings

            }
        }
    }
    
    

    // Create a UIStoryboard with the storyboard identifier
    func storyboard (_ identifier : StoryboardIdentifier) -> UIStoryboard {
       return UIStoryboard.init(name: identifier.rawValue, bundle: nil)
    }
    func storyboard (_ identifier : String) -> UIStoryboard {
       return UIStoryboard.init(name: identifier, bundle: nil)
    }

    // Create the root UIViewController in a specified UIStoryboard with the storyboard identifier
    func rootViewcontroller (storyboardIdentifier : StoryboardIdentifier) -> UIViewController? {
        let board = storyboard(storyboardIdentifier)
        return board.instantiateInitialViewController()
    }

    func rootViewcontroller (storyboardIdentifier : String) -> UIViewController? {
        let board = storyboard(storyboardIdentifier)
        return board.instantiateInitialViewController()
    }

    // Create a UIViewController with the viewcontroller identifier
    func viewController (_ vcIdentifier : ViewControllerIdentifier?) -> UIViewController? {
        guard let vcIdentifier = vcIdentifier, let storyIdentifier = vcIdentifier.storyboard else { return nil }
        return storyboard(storyIdentifier).instantiateViewController(withIdentifier: vcIdentifier.rawValue)
    }
    
    func viewController (_ vcIdentifier : String?) -> UIViewController? {
        guard let vcIdentifier = vcIdentifier, let identifier = ViewControllerIdentifier(rawValue: vcIdentifier) else { return nil }
        return viewController(identifier)
    }

}
