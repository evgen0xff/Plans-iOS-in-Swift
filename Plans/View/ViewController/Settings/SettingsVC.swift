//
//  SettingsVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit

class SettingsVC: UserBaseVC {

    // MARK: - All IBOutlet
    @IBOutlet weak var tblvSettings: UITableView!
    
    // MARK: - Properties
    override var screenName: String? { "Settings_Screen" }

    internal let settings: [[String:String]] = [["icon": "ic_user_black",        "title":"Edit Profile"],
                                                ["icon": "ic_key_black",         "title":"Change Password"],
                                                ["icon": "ic_like_black",        "title":"Posts You've Liked"],
                                                ["icon": "ic_bell_black",        "title":"Push Notifications"],
                                                ["icon": "ic_lock_black",        "title":"Privacy Options"],
                                                ["icon": "ic_message_black",     "title":"Send Feedback"],
                                                ["icon": "ic_help_circle_black", "title":"Help & Legal"],
                                                ["icon": "ic_logout_black",      "title":"Logout"]]
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func setupUI() {
        super.setupUI()
        tblvSettings.register(nib: ItemTableCell.className)
    }
    
    // MARK: - User Action Handlers
    
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - UITableViewDataSource
extension SettingsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItemTableCell.className, for: indexPath) as? ItemTableCell else {
             return UITableViewCell()
        }
        let item = settings[indexPath.row]
        cell.setupUI(icon: item["icon"], title: item["title"])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var vc: UIViewController?
        switch indexPath.row {
        case 0:
            vc = STORY_MANAGER.viewController(EditProfileVC.className) as? EditProfileVC
        case 1:
            vc = STORY_MANAGER.viewController(ChangePasswordVC.className) as? ChangePasswordVC
        case 2:
            vc = STORY_MANAGER.viewController(PostsLikedVC.className) as? PostsLikedVC
        case 3:
            vc = STORY_MANAGER.viewController(SettingPushNotifyVC.className) as? SettingPushNotifyVC
        case 4:
            vc = STORY_MANAGER.viewController(PrivacyOptionVC.className) as? PrivacyOptionVC
        case 5:
            vc = STORY_MANAGER.viewController(SendFeedbackVC.className) as? SendFeedbackVC
        case 6:
            vc = STORY_MANAGER.viewController(HelpLegalVC.className) as? HelpLegalVC
        case 7:
            logOut()
        default:
            break
        }
        
        if let vc = vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}



