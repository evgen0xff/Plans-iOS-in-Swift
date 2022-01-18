//
//  MyMessageTextCell.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit
import ActiveLabel

class MyMessageTextCell: MessageBaseCell {

    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var lblMessage: ActiveLabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var viewSendImage: UIView!
    @IBOutlet weak var widthTimeLbl: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        APP_MANAGER.topVC?.setupActiveLabel(label: lblMessage, color: .white)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    // MARK: - Public Methods
    override func setupUI(message: MessageModel?, chat: ChatModel? = nil) {
        super.setupUI(message: message, chat: chat)

        viewRounding = viewBackground

        lblMessage.text = message?.message
        if let createdAt = message?.createdAt {
            viewSendImage.isHidden = true
            lblTime.text = Date(timeIntervalSince1970: createdAt).dateStringWith(strFormat: "h:mm a")
        }else {
            viewSendImage.isHidden = false
            lblTime.text = ""
        }
        widthTimeLbl.constant = lblTime.text?.width(withConstraintedHeight: 18.0, font: AppFont.regular.size(13.0)) ?? 0

        setNeedsDisplay()
    }
    
}
