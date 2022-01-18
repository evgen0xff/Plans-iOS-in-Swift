//
//  CountLabelCell.swift
//  Plans
//
//  Created by Admin on 30/04/19.
//  Copyright © 2019 PlansCollective. All rights reserved.
//

import UIKit

class CountLabelCell: UICollectionViewCell {
    
    enum CellType {
        case people
        case like
    }

    @IBOutlet weak var backgroundImgView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    
    var cellType = CellType.people
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func setupUI(countTotal: Int = 0, countIgnore: Int = 0, type: CellType = .people) {
        cellType = type
        countLabel.text = ""
        countLabel.isHidden = true
        backgroundImgView.isHidden = false

        switch cellType {
        case .people :
            if countTotal > 99 {
                backgroundImgView.image = UIImage(named: "ic_dots_3_circle_green")
            }else if countTotal > countIgnore {
                countLabel.text = "+\(countTotal - countIgnore)"
                countLabel.isHidden = false
                backgroundImgView.image = nil
            }else {
                backgroundImgView.image = UIImage(named: "ic_users_circle_green")
            }
            break
        case .like :
            if countTotal > countIgnore {
                countLabel.isHidden = false
                backgroundImgView.image = UIImage(named: "ic_dots_3_circle_green")
            }
            break
        }
    }
    

}
