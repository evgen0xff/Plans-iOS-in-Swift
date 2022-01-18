//
//  RangeButtonCell.swift
//  Plans
//
//  Created by Admin on 07/06/19.
//  Copyright © 2019 PlansCollective. All rights reserved.
//

import UIKit

class RangeButtonCell: UICollectionViewCell {

    @IBOutlet weak var lblRange: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupUI(range: String?, isSelected: Bool = false) {
        lblRange.backgroundColor = isSelected == true ? AppColor.purple_join : AppColor.grey_button
        lblRange.text = (range ?? "") + "ft"
    }
    
    

}
