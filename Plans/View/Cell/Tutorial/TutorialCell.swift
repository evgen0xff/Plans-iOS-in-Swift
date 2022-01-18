//
//  TutorialCell.swift
//  Plans
//
//  Created by BrainMobi on 4/23/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class TutorialCell: UICollectionViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgviewTutorial: UIImageView!
    @IBOutlet weak var lblDescription: UILabel!
    
    
    func setupUI(dic : [String:String]?) {
        if let imageName = dic?["image"] {
            imgviewTutorial.image = UIImage(named: imageName)
        }
        if let title = dic?["title"] {
            lblTitle.text = title
        }
        if let detail = dic?["detail"] {
            lblDescription.text = detail
        }
    }
}
