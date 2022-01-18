//
//  SearchEventCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/24/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class SearchEventCell: BaseTableViewCell {
    
    enum CellType {
        case search
        case saved
    }

    // MARK: - All IBOutlet
    
    @IBOutlet weak var eventImgVw: UIImageView!
    @IBOutlet weak var eventNameLbl: UILabel!
    @IBOutlet weak var viewMenu: UIView!
    @IBOutlet weak var eventTimeLbl: UILabel!
    @IBOutlet weak var eventHostedLbl: UILabel!
    @IBOutlet weak var viewSeparator: UIView!
    @IBOutlet weak var heightDateTime: NSLayoutConstraint!
    @IBOutlet weak var heightEventName: NSLayoutConstraint!
    
    var event: EventFeedModel?
    var cellType = CellType.search
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - User Actions
    @IBAction func actionMenuBtn(_ sender: Any) {
        var list: [String]?
        
        switch cellType {
        case .search:
            break
        case .saved:
            list = ["Unsave Event",
                    "Share Event"]
            break
        }
        OPTIONS_MANAGER.showMenu(list: list, data: event, delegate: (APP_MANAGER.topVC as? OptionsMenuManagerDelegate))
    }
    
    
    // MARK: - Public Methods
    func configureEventCell(eventFeed: EventFeedModel,
                            cellType: CellType = .search,
                            isHiddenSeparator: Bool = false) {
        event = eventFeed
        self.cellType = cellType
        
        switch cellType {
        case .search:
            viewMenu.isHidden = true
        case .saved:
            viewMenu.isHidden = false
        }
        
        // Event Image
        var url : URL?
        if eventFeed.mediaType == "video" {
            url = URL(string: eventFeed.thumbnail)
        }else {
            url = URL(string: eventFeed.imageOrVideo)
        }
        eventImgVw.setEventImage(url)

        // Event Name
        eventNameLbl.text = eventFeed.eventName
        let height = eventNameLbl.text?.height(withConstrainedWidth: MAIN_SCREEN_WIDTH - 15 - 80 - 8 - 28 - 4, font: AppFont.bold.size(15.0)) ?? 0
        heightEventName.constant = (height < 18.0) ? 28.0 : (height > 37.0 ? 37.0 : height)

        // Organized by
        eventHostedLbl.text = "Organized by \(eventFeed.eventCreatedBy?.firstName ?? "") \(eventFeed.eventCreatedBy?.lastName ?? "")"

        // Event Start/End Time
        eventTimeLbl.text = eventFeed.textStartEndTime()
        let height1 = eventTimeLbl.text?.height(withConstrainedWidth: MAIN_SCREEN_WIDTH - 15 - 80 - 8 - 20 - 4, font: AppFont.regular.size(15.0)) ?? 0
        heightDateTime.constant = height1 < 18.0 ? 18.0 : height1
        
        // Separator
        viewSeparator.isHidden = isHiddenSeparator
    }
}
