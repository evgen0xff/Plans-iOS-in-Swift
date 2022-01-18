//
//  SettingOptionCell.swift
//  Plans
//
//  Created by Star on 4/28/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit

protocol SettingOptionCellDelegate {
    func didValueChanged (optionModel: SettingOptionModel?, status: Bool)
}

extension SettingOptionCellDelegate {
    func didValueChanged (optionModel: SettingOptionModel?, status: Bool){}
}

class SettingOptionCell: BaseTableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var switchOnOff: UISwitch!
    
    
    var optionModel : SettingOptionModel?
    var delegate : SettingOptionCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupUI(model: SettingOptionModel?, delegate: SettingOptionCellDelegate? = nil, isActive: Bool = true) {
        self.optionModel = model
        self.delegate = delegate
        lblTitle.text = optionModel?.name ?? ""
        switchOnOff.isOn = optionModel?.status ?? false
        switchOnOff.isEnabled = isActive
    }
    
    @IBAction func actionChangedOnOff(_ sender: UISwitch) {
        delegate?.didValueChanged(optionModel: optionModel, status: sender.isOn)
    }
    
}
