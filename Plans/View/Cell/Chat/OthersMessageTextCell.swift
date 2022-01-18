//
//  OthersMessageTextCell.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit
import ActiveLabel

class OthersMessageTextCell: MessageBaseCell {

    @IBOutlet weak var viewUserProfile: UIView!
    @IBOutlet weak var imgvUserProfile: UIImageView!
    
    @IBOutlet weak var viewBackground: UIView!
    
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var heightUserNameLbl: NSLayoutConstraint!
    @IBOutlet weak var widthUserNameLbl: NSLayoutConstraint!
    
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var widthTimeLbl: NSLayoutConstraint!

    @IBOutlet weak var lblMessage: ActiveLabel!
    @IBOutlet weak var widthMessageLbl: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        APP_MANAGER.topVC?.setupActiveLabel(label: lblMessage)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionUserProfile(_ sender: Any) {
        APP_MANAGER.pushUserProfileVC(userId: message?.userId)
    }
    
    override func setupUI(message: MessageModel?, chat: ChatModel? = nil) {
        super.setupUI(message: message, chat: chat)

        viewRounding = viewBackground
        
        // User Profile Image
        viewUserProfile.isHidden = message?.viewModel?.isHiddenProfileImage ?? false
        imgvUserProfile.setUserImage(message?.user?.profileImage)
        
        // User Name and Organizer Mark
        let widthUserName = updateHeader()

        // Message
        lblMessage.text = message?.message
        let widthMessage = lblMessage.text?.width(withConstraintedHeight: 18.0, font: AppFont.regular.size(15.0)) ?? 0
        let widthAvailable = MAIN_SCREEN_WIDTH - 15 - 44 - 8 - 16 - 16 - 62
        widthMessageLbl.constant = max(widthMessage > widthAvailable ? widthAvailable : widthMessage, widthUserName)
        
        setNeedsDisplay()
    }
    
    func updateHeader() -> CGFloat{
        // Time
        if let createdAt = message?.createdAt {
            lblTime.text = Date(timeIntervalSince1970: createdAt).dateStringWith(strFormat: "h:mm a")
        }else {
            lblTime.text = ""
        }
        widthTimeLbl.constant = lblTime.text?.width(withConstraintedHeight: 18.0, font: AppFont.regular.size(13.0)) ?? 0

        // User Name
        lblUserName.isHidden = message?.viewModel?.isHiddenOwnerName ?? false
        
        guard lblUserName.isHidden == false else {
            widthUserNameLbl.constant = 0.0
            heightUserNameLbl.constant = 18.0
            return widthTimeLbl.constant
        }

        let name = "\(message?.user?.firstName ?? "") \(message?.user?.lastName ?? "")"
        let widthAvailabl = MAIN_SCREEN_WIDTH - 15 - 44 - 8 - 16 - 4 - widthTimeLbl.constant - 16 - 62

        let attriName = name.colored(color: .black, font: AppFont.bold.size(15.0))
        var widthName = attriName.width(containerHeight: 18.0)

        // Organizer Mark
        if message?.userId == chat?.organizer?._id,
           chat?.isEventChat == true {
            let attriNameWithMark = NSMutableAttributedString(attributedString: attriName)
            attriNameWithMark.append(" • ".colored(color: .black, font: AppFont.bold.size(15.0)))
            attriNameWithMark.append("Organizer".colored(color: AppColor.teal_main, font: AppFont.regular.size(13.0)))
            let widthNameWithMark = attriNameWithMark.width(containerHeight: 18.0)

            if widthName <= widthAvailabl, widthNameWithMark > widthAvailabl {
                attriName.append("\n".colored(color: .black, font: AppFont.bold.size(15.0)))
            }else {
                attriName.append(" • ".colored(color: .black, font: AppFont.bold.size(15.0)))
            }
            attriName.append("Organizer".colored(color: AppColor.teal_main, font: AppFont.regular.size(13.0)))
        }
        widthName = attriName.width(containerHeight: 18.0)

        // User Name - Width and Height
        widthUserNameLbl.constant = widthName > widthAvailabl ? widthAvailabl : widthName

        let height = attriName.height(containerWidth: widthUserNameLbl.constant)
        heightUserNameLbl.constant = height < 18.0 ? 18.0 : (height > 37.0 ? 37.0 : height)
        
        // User Name - Text
        lblUserName.attributedText = attriName

        return widthUserNameLbl.constant + widthTimeLbl.constant + 4.0

    }
    
}
