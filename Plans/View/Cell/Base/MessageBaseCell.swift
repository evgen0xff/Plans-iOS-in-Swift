//
//  MessageBaseCell.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit

class MessageBaseCell: BaseTableViewCell {
    
    var message: MessageModel?
    var chat: ChatModel?
    
    var viewRounding: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        applyBoundaryEffect()
    }
    
    // MARK: - Public Methods
    func setupUI(message: MessageModel?, chat: ChatModel? = nil) {
        self.message = message
        self.chat = chat
    }
    
    func applyBoundaryEffect(viewBound: UIView? = nil, isShadow: Bool? = nil) {
        guard let viewBound = viewBound ?? viewRounding, let message = message else { return }

        viewRounding = viewBound

        // Rounding corners
        viewBound.maskRoundCorners(cornerRadius: 20.0,
                                   cornersNonRound: message.viewModel?.cornersNonRounding)

        // Shadow
        let isShadow = isShadow ?? (message.viewModel?.ownerType == .other)
        if isShadow == true {
            viewBound.addShadow()
        }
    }
    
    

}
