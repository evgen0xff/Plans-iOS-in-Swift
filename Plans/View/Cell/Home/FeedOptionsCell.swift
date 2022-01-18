//
//  FeedOptionsCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/17/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit


class FeedOptionsCell: BaseTableViewCell {

    // MARK: - IBOutlets
    
    @IBOutlet weak var imgViewOption: UIImageView!
    @IBOutlet weak var lblOptionName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureFeedCellWithDict(_ dict : [String : Any])
    {
        if let image = dict["image"] as? String
        {
            imgViewOption.image = UIImage(named: image)
        }
        if let name = dict["name"] as? String
        {
            lblOptionName.text = name
        }
    }
}
