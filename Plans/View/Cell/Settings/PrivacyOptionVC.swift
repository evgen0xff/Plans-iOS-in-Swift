//
//  PrivacyOptionVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit

class PrivacyOptionVC: UserBaseVC {
    
    // MARK: - All IBOutlet
    @IBOutlet weak var switchPrivateAccount: UISwitch!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        switchPrivateAccount.isOn = USER_MANAGER.isPrivateAccount
    }

    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    // MARK: - Set Up View
    
    
    // Switch Button Selection
    @IBAction func actionChangedPrivateAccount(_ sender: UISwitch) {
        updatePrivateAccount(status: sender.isOn)
    }
    
    @IBAction func actionBlockedUsers(_ sender: Any) {
        guard let vc = STORY_MANAGER.viewController(BlockedUserVC.className) as? BlockedUserVC else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Hit api

extension PrivacyOptionVC {
    func updatePrivateAccount(status: Bool) {
        showLoader()
        USER_SERVICE.hitUpdatePrivateAccountApi(status: status).done { (newUser) in
            self.hideLoader()
            USER_MANAGER.isPrivateAccount = newUser.isPrivateAccount ?? true
            self.refreshAll()
        }.catch { (err) in
            self.hideLoader()
            POPUP_MANAGER.handleError(err)
        }
    }
}




