//
//  ItemTableCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/15/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class ItemTableCell: BaseTableViewCell {

    // MARK: - All IBOutlet
    @IBOutlet weak var imgviewIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    public func setupUI(icon: String? = nil, title: String? = nil) {
        // Icon
        imgviewIcon.image = icon != nil ? UIImage(named: icon!) : nil
        lblTitle.text = title
    }
    
}
