//
//  LocationDetailsCell.swift
//  Plans
//
//  Created by Star on 5/23/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

class LocationDetailsCell: UICollectionViewCell {
    
    @IBOutlet weak var imgviewCategoryIcon: UIImageView!
    @IBOutlet weak var lblCategoryName: UILabel!
    
    @IBOutlet weak var imgviewBackground: UIImageView!
    @IBOutlet weak var lblPlaceName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblDistanceMiles: UILabel!
    
    
    var place : PlaceModel?
    
    func setupUI(_ model: PlaceModel?, index: Int = 0) {
        self.place = model
        lblCategoryName.text = model?.category?.name
        imgviewCategoryIcon.image = model?.category?.iconImage != nil ? UIImage(named: model!.category!.iconImage!) : nil
        lblPlaceName.text = "\(index). " + (model?.name ?? "")
        lblAddress.text = model?.address?.removeOwnCountry()
        let distance = USER_MANAGER.myLocation.getDistance(other: model?.location)
        lblDistanceMiles.text = String(format:"%.2f ", distance)
        if distance >= 2 {
            lblDistanceMiles.text! += "Miles"
        }else {
            lblDistanceMiles.text! += "Mile"
        }
        
        imgviewBackground.isHidden = false
        if let image = model?.photoImage {
            imgviewBackground.image = image
        }else {
            imgviewBackground.image = UIImage(named: "im_placeholder_event_cover")
            PLACE_SERVICE.fetchPhotos(model?.place_id) { (image, error) in
                if error != nil {
                    self.imgviewBackground.isHidden = true
                }else {
                    self.place?.photoImage = image
                    self.imgviewBackground.image = image
                }
            }
        }
        
    }
}
