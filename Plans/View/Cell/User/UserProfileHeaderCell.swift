//
//  UserProfileHeaderCell.swift
//  Plans
//
//  Created by Star on 2/21/21.
//

import UIKit
import ActiveLabel

protocol UserProfileHeaderCellDelegate {
    func didSelect(titleItem: String?, user: UserModel?)
}

extension UserProfileHeaderCellDelegate {
    func didSelect(titleItem: String?, user: UserModel?){}
}

class UserProfileHeaderCell: BaseTableViewCell {
    // MARK: - Types
    enum CellType {
        case myProfile
        case otherProfile
    }
    
    enum TabType : Int {
        case organized = 0
        case attending = 1
        case saved = 2
        
        var keyValue : String {
            switch self {
            case .organized: return "hosting"
            case .attending: return "attending"
            case .saved: return "saved"
            }
        }
    }


    // MARK: - IBOutlets
    @IBOutlet weak var heightTopMargin: NSLayoutConstraint!
    
    @IBOutlet weak var viewBack: UIView!
    @IBOutlet weak var viewMenu: UIView!
    @IBOutlet weak var viewSettings: UIView!
    
    @IBOutlet weak var imgvUserImage: UIImageView!
    @IBOutlet weak var viewStar: UIView!
    @IBOutlet weak var btnStar: UIButton!
    @IBOutlet weak var viewStarRounding: UIView!
    @IBOutlet weak var imgvStar: UIImageView!
    @IBOutlet weak var lblStarLevel: UILabel!
    
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblUserAddress: UILabel!
    
    @IBOutlet weak var lblEventCount: UILabel!
    @IBOutlet weak var btnEventCount: UIButton!
    
    @IBOutlet weak var lblFriendsCount: UILabel!
    @IBOutlet weak var btnFriendsCount: UIButton!
    
    @IBOutlet weak var viewAboutUser: UIView!
    @IBOutlet weak var lblAboutUser: ActiveLabel!

    @IBOutlet weak var viewFooter: UIView!

    @IBOutlet weak var viewFriendShip: UIView!
    @IBOutlet weak var btnFriendShip: UIButton!
    
    @IBOutlet weak var viewTabs: UIView!
    @IBOutlet var collectTabItems: [UIView]!
    @IBOutlet var collectItemBtns: [UIButton]!
    @IBOutlet var collectItemUnderLines: [UIView]!
    
    @IBOutlet weak var viewTapFriendsGuide: UIView!

    // MARK: Properties
    var userModel: UserModel?
    var delegate: UserProfileHeaderCellDelegate?
    var typeCell: CellType = .myProfile
    var selectedTab: TabType = .attending

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        layer.zPosition = 1
        APP_MANAGER.topVC?.setupActiveLabel(label: lblAboutUser)
    }
    
    // MARK: - User Actions
    
    @IBAction func actionBackbtn(_ sender: Any) {
        APP_MANAGER.popViewContorller()
    }
    
    @IBAction func actionMenuBtn(_ sender: Any) {
        OPTIONS_MANAGER.showMenu(data: userModel, menuType: .userProfile, delegate: (APP_MANAGER.topVC as? OptionsMenuManagerDelegate))
    }
    
    @IBAction func actionSettingsBtn(_ sender: Any) {
        APP_MANAGER.pushSettingsVC(userModel: userModel)
    }
    
    @IBAction func actionUserImagBtn(_ sender: Any) {
        APP_MANAGER.openImageVC(imgStr: userModel?.profileImage)
    }
    
    @IBAction func actionStarBtn(_ sender: Any) {
        APP_MANAGER.pushUserCoinVC(user: userModel)
    }
    
    @IBAction func actionEventsBtn(_ sender: Any) {
        
    }
    
    @IBAction func actionFriendsBtn(_ sender: Any) {
        switch typeCell {
        case .myProfile:
            USER_MANAGER.isShownTutorialFriends = true
            viewTapFriendsGuide.isHidden = true
            break
        case .otherProfile:
            break
        }

        APP_MANAGER.pushFriendListVC(user: userModel)
    }
    
    @IBAction func actionFriendShipBtn(_ sender: UIButton) {
        delegate?.didSelect(titleItem: sender.title(for: .normal), user: userModel)
    }
    
    @IBAction func actionTabItems(_ sender: UIButton) {
        selectedTab = TabType(rawValue: sender.tag) ?? .organized
        updateTabItems(itemSelected: selectedTab)
        delegate?.didSelect(titleItem: sender.title(for: .normal), user: userModel)
    }
    
    // MARK: - Private Methods
    private func configureUI(typeCell: CellType, selectedTab: TabType) {
        layer.zPosition = 1
        heightTopMargin.constant = UIDevice.current.heightTopNotch
        viewStarRounding.layer.borderColor = AppColor.grey_button_border.cgColor
        viewStarRounding.addShadow()
        addShadow()

        switch typeCell {
        case .myProfile:
            viewBack.isHidden = true
            viewMenu.isHidden = true
            viewSettings.isHidden = false
            viewFriendShip.isHidden = true
            updateTabItems(itemSelected: selectedTab)
            viewTapFriendsGuide.isHidden = USER_MANAGER.isShownTutorialFriends
            break
        case .otherProfile:
            viewBack.isHidden = false
            viewMenu.isHidden = false
            viewSettings.isHidden = true
            viewFriendShip.isHidden = false
            viewTapFriendsGuide.isHidden = true
            updateTabItems(itemSelected: selectedTab, itemHidden: .saved)
            updateFriendShipUI()
            break
        }
    }
    
    private func updateTabItems(itemSelected: TabType? = nil, itemHidden: TabType? = nil) {
        if let itemHidden = itemHidden {
            collectTabItems.forEach { (item) in
                item.isHidden = item.tag == itemHidden.rawValue ? true : false
            }
        }
        
        if let itemSelected = itemSelected {
            collectItemBtns.forEach { (item) in
                let color = item.tag == itemSelected.rawValue ? AppColor.purple_join : .black
                item.setTitleColor(color, for: .normal)
            }
            
            collectItemUnderLines.forEach { (item) in
                item.isHidden = item.tag == itemSelected.rawValue ? false : true
            }

        }
    }
    
    private func updateUI(user: UserModel?) {
        // User Image
        if let user = user {
            imgvUserImage.setUserImage(user.profileImage)
        }
        
        // Star Image
        if let coinNumber = user?.coinNumber, coinNumber > 0 {
            viewStar.isHidden = false
            imgvStar.image = UIImage(named: "ic_star_\(coinNumber)")
            lblStarLevel.text = user?.getCountLiveEvents()
        }else {
            viewStar.isHidden = true
        }
        
        // User Name
        lblUserName.text = "\(user?.firstName ?? "")"
        lblUserName.text! += user?.lastName != nil ? " \(user?.lastName ?? "")" : ""

        // User Address
        lblUserAddress.isHidden = (user?.location == nil || user?.location == "") ? true : false
        lblUserAddress.text = user?.location?.removeOwnCountry()
        
        // Live Events and Friends Count
        lblEventCount.text = "\(user?.eventCount ?? 0)"
        lblFriendsCount.text = "\(user?.friendsCount ?? 0)"
        
        // User Bio
        viewAboutUser.isHidden = (user?.bio == nil || user?.bio == "") ? true: false
        lblAboutUser.text = user?.bio
    }
    
    func updateFriendShipUI() {
        
        if let friendShipStatus = userModel?.friendShipStatus {
            var text: String?
            var color: UIColor?
            
            if friendShipStatus == 0 {
                if let friendRequestSender = userModel?.friendRequestSender,
                    friendRequestSender == USER_MANAGER.userId {
                    text = ConstantTexts.requested.localizedString
                    color = AppColor.teal_main
                } else {
                    text = ConstantTexts.confirmRequest.localizedString
                    color = AppColor.purple_join
                }
            } else if friendShipStatus == 1 {
                text = ConstantTexts.isFriend.localizedString
                color = AppColor.pink_done
            } else if friendShipStatus == 5 {
                text = ConstantTexts.blockedUser.localizedString
                color = AppColor.grey_button
            } else if friendShipStatus == 10 {
                text = ConstantTexts.addFriend.localizedString
                color = AppColor.purple_join
            }
            
            if let text = text {
                btnFriendShip.setTitle(text, for: .normal)
            }
            if let color = color {
                btnFriendShip.backgroundColor = color
            }
        }
        
        let isAccess = userModel?.getAccessForMe().isAccess ?? false
        btnFriendsCount.isEnabled = isAccess
        btnStar.isEnabled = isAccess
        viewTabs.isHidden = !isAccess
    }
    
    // MARK: - Public Meothds
    func setupUI(user: UserModel?,
                 delegate: UserProfileHeaderCellDelegate? = nil,
                 typeCell: CellType = .myProfile,
                 selectedTab: TabType = .organized){
        
        userModel = user
        self.delegate = delegate
        self.typeCell = typeCell
        self.selectedTab = selectedTab
        
        configureUI(typeCell: typeCell, selectedTab: selectedTab)
        updateUI(user: user)
    }
    
    
}
