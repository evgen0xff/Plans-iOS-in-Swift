//
//  CategoryCell.swift
//  Plans
//
//  Created by Star on 5/23/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var imgviewBackground: UIImageView!
    @IBOutlet weak var imgviewIcon: UIImageView!
    @IBOutlet weak var lblName: UILabel!


    var category : CateoryModel?
    
    func setupUI(model: CateoryModel?) {
        self.category = model
        imgviewIcon.image = model?.defaultImage != nil ? UIImage(named: model!.defaultImage!) : nil
        lblName.text = model?.name
    }
    
}
