//
//  DateMessageCell.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit

class DateMessageCell: MessageBaseCell {

    @IBOutlet weak var lblDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setupUI(message: MessageModel?, chat: ChatModel? = nil) {
        super.setupUI(message: message, chat: chat)
        
        lblDate.text = message?.message
    }
    
}
