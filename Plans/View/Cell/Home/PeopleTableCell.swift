//
//  PeopleTableCell.swift
//  Plans
//
//  Created by Star on 11/30/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

protocol PeopleTableCellDelegate {
    func likeUnlinkPost(postModel: PostModel?)
}

extension PeopleTableCellDelegate {
    func likeUnlinkPost(postModel: PostModel?){}
}


class PeopleTableCell: BaseTableViewCell {
    
    enum CellType {
        case homeFeed
        case eventDetails
        case postLike
    }
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var viewRightMargin: UIView!
    @IBOutlet weak var viewLeftMargin: UIView!
    @IBOutlet weak var viewCenter: UIView!
    @IBOutlet weak var viewTopSeparator: UIView!
    @IBOutlet weak var containerSeparator: UIView!
    @IBOutlet weak var viewBottomSeparator: UIView!
    @IBOutlet weak var viewTitle: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var collectviewList: UICollectionView!
    
    @IBOutlet weak var viewGuideContainter: UIView!
    @IBOutlet weak var imvGuide: UIImageView!
    @IBOutlet weak var constGuideImvLeft: NSLayoutConstraint!
    
    @IBOutlet weak var constHeightContainerSeparator: NSLayoutConstraint!
    
    // MARK: - Properities
    var cellType: CellType = CellType.homeFeed
    var delegate: PeopleTableCellDelegate?
    var model: Any?
    var eventModel: EventFeedModel?
    var postModel: PostModel?
    var arrInvitations = [InvitationModel]()
    var arrLikes = [UserModel]()
    var countItems = 8
    var widthItemCell : CGFloat {
        return (MAIN_SCREEN_WIDTH - 20.0) / CGFloat(countItems)
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        while widthItemCell < 50 {
            countItems -= 1
        }

        collectviewList.register(UINib(nibName: UserImageCell.className, bundle: nil), forCellWithReuseIdentifier: UserImageCell.className)
        collectviewList.register(UINib(nibName: CountLabelCell.className, bundle: nil), forCellWithReuseIdentifier: CountLabelCell.className)
        
        collectviewList.delegate = self
        collectviewList.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Action Handlers
    @IBAction func actionGuide(_ sender: Any) {
        USER_MANAGER.isSeenGuideGuestList = true
        APP_MANAGER.pushInvitedPeopleVC(eventModel: eventModel)
    }
    

    // MARK: - Public Meoths
    
    public func setupUI(model: Any?,
                        delegate: PeopleTableCellDelegate? = nil,
                        cellType: CellType = .homeFeed,
                        isHiddenSeparator: Bool = false) {
        self.cellType = cellType
        self.model = model
        self.delegate = delegate
        
        loadData()
        configureUI(isHiddenSeparator: isHiddenSeparator)
    }

    // MARK: - Private Meoths
    
    private func loadData() {
        switch cellType {
        case .homeFeed, .eventDetails :
            eventModel = model as? EventFeedModel
            arrInvitations.removeAll()
            eventModel?.invitationDetails?.forEach { (user) in
                if let status = user.status, status == 2 {
                    arrInvitations.append(user)
                }
            }
            break
        case .postLike :
            postModel = model as? PostModel
            arrLikes.removeAll()
            if let likes = postModel?.likes {
                arrLikes.append(contentsOf: likes)
            }
            break
        }
    }
    
    private func configureUI (isHiddenSeparator: Bool = false) {
        viewRightMargin.isHidden = false
        viewLeftMargin.isHidden = false
        viewTopSeparator.isHidden = true
        containerSeparator.isHidden = true
        constHeightContainerSeparator.constant = 3.0
        viewBottomSeparator.isHidden = isHiddenSeparator
        viewTitle.isHidden = true
        viewGuideContainter.isHidden = true
        
        switch cellType {
        case .homeFeed :
            break
        case .eventDetails :
            if let count = eventModel?.invitationDetails?.count, count > 0 {
                lblTitle.text = "People"
                viewTitle.isHidden = false
                containerSeparator.isHidden = false
                constHeightContainerSeparator.constant = 5.0
                viewRightMargin.backgroundColor = .white
                viewLeftMargin.backgroundColor = .white
            }
            
            if USER_MANAGER.isSeenGuideGuestList {
                viewGuideContainter.isHidden = true
            }else {
                let countCurrentItems = (arrInvitations.count > (countItems - 1) ? (countItems - 1) : arrInvitations.count) + 1
                var leftGuideImage = CGFloat(countCurrentItems) * widthItemCell - widthItemCell / 2.0
                let countHalf = Int((Double(countItems) / 2.0))
                
                if countCurrentItems > countHalf {
                    imvGuide.image = UIImage(named: "im_tap_to_view_guest_list_right")
                    leftGuideImage -= 125
                }else {
                    imvGuide.image = UIImage(named: "im_tap_to_view_guest_list_left")
                    leftGuideImage -= 24
                }
                constGuideImvLeft.constant = leftGuideImage
                viewGuideContainter.isHidden = false
            }
            break
        case .postLike :
            var title = "Like"
            if let count = postModel?.likes?.count {
                if count == 1 {
                    title = "1 Like"
                } else if count > 1 {
                    title = "\(count) Likes"
                }
            }
            lblTitle.text = title
            viewTitle.isHidden = false
            containerSeparator.isHidden = false
            viewBottomSeparator.isHidden = true
            break
        }
        
        collectviewList.reloadData()
    }
    
    private func getProfileImageCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserImageCell.className, for: indexPath) as? UserImageCell else { return nil }
        
        switch cellType {
        case .homeFeed, .eventDetails:
            cell.setupUI(invitationModel: arrInvitations[indexPath.row], eventModel: eventModel)
            break
        case .postLike :
            cell.setupUI(userModel: arrLikes[indexPath.row])
            break
        }
        
        return cell
    }
    
    private func getMoreCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CountLabelCell.className, for: indexPath) as? CountLabelCell else { return nil }
        
        switch cellType {
        case .homeFeed, .eventDetails:
            cell.setupUI(countTotal: arrInvitations.count, countIgnore: (countItems - 1), type: .people)
            break
        case .postLike :
            cell.setupUI(countTotal: arrLikes.count, countIgnore: (countItems - 2), type: .like)
            break
        }
        
        return cell
    }
    
    private func getLikeImageCell(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserImageCell.className, for: indexPath) as? UserImageCell else { return nil }
        cell.setupUILikeImage(isFull: arrLikes.contains(where: { $0._id == USER_MANAGER.userId }))
        return cell
    }

}


// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension PeopleTableCell : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var number = 1
        
        switch cellType {
        case .homeFeed, .eventDetails:
            number = 2
        case .postLike :
            number = 3
        }
        
        return number
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var number = 0
        switch cellType {
        case .homeFeed, .eventDetails:
            switch section {
            case 0:
                number = arrInvitations.count > (countItems - 1) ? (countItems - 1) : arrInvitations.count
            case 1:
                number = 1
            default:
                number = 0
            }
        case .postLike :
            switch section {
            case 0:
                number = 1
            case 1:
                number = arrLikes.count > (countItems - 1) ? (countItems - 2) : arrLikes.count
            case 2:
                number = arrLikes.count > (countItems - 1) ? 1 : 0
            default:
                number = 0
            }
        }
        
        return number
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell : UICollectionViewCell?
        
        switch cellType {
        case .homeFeed, .eventDetails:
            switch indexPath.section {
            case 0:
                cell = getProfileImageCell(collectionView, indexPath: indexPath)
                break
            case 1:
                cell = getMoreCell(collectionView, indexPath: indexPath)
                break
            default:
                break
            }
        case .postLike :
            switch indexPath.section {
            case 0:
                cell = getLikeImageCell(collectionView, indexPath: indexPath)
                break
            case 1:
                cell = getProfileImageCell(collectionView, indexPath: indexPath)
                break
            case 2:
                cell = getMoreCell(collectionView, indexPath: indexPath)
                break
            default:
                break
            }
        }

        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch cellType {
        case .homeFeed, .eventDetails:
            switch indexPath.section {
            case 0:
                let userId = arrInvitations[indexPath.row].userId
                APP_MANAGER.pushUserProfileVC(userId: userId)
                break
            case 1:
                if cellType == .eventDetails {
                    USER_MANAGER.isSeenGuideGuestList = true
                }
                APP_MANAGER.pushInvitedPeopleVC(eventModel: eventModel)
                break
            default:
                break
            }
        case .postLike :
            switch indexPath.section {
            case 0:
                delegate?.likeUnlinkPost(postModel: postModel)
                break
            case 1:
                let userId = arrLikes[indexPath.row]._id
                APP_MANAGER.pushUserProfileVC(userId: userId)
                break
            case 2:
                APP_MANAGER.pushLikesVC(post: postModel)
                break
            default:
                break
            }
        }

    
    }
    
}


// MARK: - UICollectionViewDelegateFlowLayout
extension PeopleTableCell : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{

        var size = CGSize(width: widthItemCell, height: 50)
        if cellType == .postLike, indexPath.section == 0 {
            size = CGSize(width: 45, height: 50)
        }
        
        return size
    }

}



