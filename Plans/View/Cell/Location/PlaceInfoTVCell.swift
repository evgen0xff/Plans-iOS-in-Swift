//
//  PlaceInfoTVCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/21/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class PlaceInfoTVCell: BaseTableViewCell {

    // MARK: - All IBOutlet
    
    @IBOutlet weak var placeImgVw: UIImageView!
    @IBOutlet weak var placeNameLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }    
}
