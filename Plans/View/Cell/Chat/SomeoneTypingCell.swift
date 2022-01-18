//
//  SomeoneTypingCell.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit

class SomeoneTypingCell: BaseTableViewCell {

    @IBOutlet weak var lblMessage: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
