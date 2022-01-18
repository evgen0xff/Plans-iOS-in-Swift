//
//  InviteByLinkVC.swift
//  Plans
//
//  Created by Star on 3/17/21.
//

import UIKit

class InviteByLinkVC: EventBaseVC {
    // MARK: - IBOutlets
    @IBOutlet weak var lblLinkUrl: UILabel!
    @IBOutlet weak var btnShareLink: UIButton!
    
    // MARK: - Properties
    
    // MARK: - ViewContorller Life Cycle.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func setupUI() {
        super.setupUI()
        lblLinkUrl.text = activeEvent?.eventLink?.invitation
        btnShareLink.addShadow(3.0, shadowOpacity: 0.3, shadowOffset: CGSize.zero)
    }

    // MARK: - User Action Handlers
    @IBAction func actionBack(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func actionCopyBtn(_ sender: Any) {
        UIPasteboard.general.string = lblLinkUrl.text
        POPUP_MANAGER.makeToast("Link copied")
    }
    
    @IBAction func actionShareLinkBtn(_ sender: Any) {
        APP_MANAGER.shareEvent(event: activeEvent, isInviting: true, sender: self)
    }
    
    // MARK: - Private Methods
    
    
}
