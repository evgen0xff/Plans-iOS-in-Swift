//
//  SectionHeaderCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/17/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class SectionHeaderCell: BaseTableViewCell {

    enum CellType {
        case eventDetails
        case postComment
        case notiActivityHeader
        case notiNewHeader
        case spaceEmpty
        case inviteContacts
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewMarginLeft: UIView!
    @IBOutlet weak var viewTopSeparator: UIView!
    @IBOutlet weak var viewBottomSeparator: UIView!
    @IBOutlet weak var viewTopSpace: UIView!
    @IBOutlet weak var viewBottomSpace: UIView!
    
    
    // MARK: - Properties
    var cellType = CellType.eventDetails
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupUI(title: String? = nil, cellType: CellType = .eventDetails) {
        lblTitle.text = title
        self.cellType = cellType

        lblTitle.isHidden = false
        viewTopSeparator.isHidden = true
        viewBottomSeparator.isHidden = true
        viewTopSpace.isHidden = false
        viewBottomSpace.isHidden = false

        lblTitle.font = AppFont.bold.size(15.0)
        lblTitle.textColor = .black
        backgroundColor = .white
        
        switch cellType {
        case .eventDetails, .postComment:
            viewBottomSpace.isHidden = true
            
        case .notiActivityHeader, .inviteContacts:
            lblTitle.font = AppFont.bold.size(17.0)
            
        case .notiNewHeader:
            lblTitle.textColor = AppColor.teal_main
            viewBottomSeparator.isHidden = false
            
        case .spaceEmpty:
            backgroundColor = .clear
            lblTitle.isHidden = true
            viewBottomSpace.isHidden = true
        }
        
    }
    
}
