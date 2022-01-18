//
//  HiddenEventsCell.swift
//  Plans
//
//  Created by Star on 9/23/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

class HiddenEventsCell: UITableViewCell {

    @IBOutlet weak var btnHiddenEvents: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        btnHiddenEvents.layer.borderColor = AppColor.grey_button_border.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionHiddenEvents(_ sender: Any) {
        APP_MANAGER.pushHiddenEvents()
    }
    
    func setupUI(listHiddenEvents: [EventFeedModel]?) {
        let count = listHiddenEvents?.count ?? 0
        btnHiddenEvents.setTitle("Hidden Events (\(count))", for: .normal)
    }
}
