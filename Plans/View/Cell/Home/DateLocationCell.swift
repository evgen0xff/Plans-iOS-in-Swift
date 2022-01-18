//
//  DateLocationCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/1/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
protocol DateLocationCellDelegate {
    func didTappedCalendar(eventModel: EventFeedModel?, cell: DateLocationCell?)
    func didTappedLocation(eventModel: EventFeedModel?, cell: DateLocationCell?)
}

extension DateLocationCellDelegate {
    func didTappedCalendar(eventModel: EventFeedModel?, cell: DateLocationCell?){}
    func didTappedLocation(eventModel: EventFeedModel?, cell: DateLocationCell?){}
}

class DateLocationCell: BaseTableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var calendarImgView: UIImageView!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var imgViewPeople: UIImageView!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var viewTopSeparator: UIView!
    @IBOutlet weak var viewBottomSeparator: UIView!
    @IBOutlet weak var viewBottomSpace: UIView!
    
    @IBOutlet weak var heightLocationLbl: NSLayoutConstraint!
    @IBOutlet weak var heightDateLbl: NSLayoutConstraint!
    
    var eventModel: EventFeedModel? = nil
    var delegate: DateLocationCellDelegate? = nil
    var cellType: CellType = CellType.homeFeed

    enum CellType {
        case homeFeed
        case eventDetails
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    // MARK: - User Action Handlers
    
    @IBAction func actionCalenderBtn(_ sender: Any) {
        if let delegate = delegate {
            delegate.didTappedCalendar(eventModel: eventModel, cell: self)
        }else {
            APP_MANAGER.pushCalendarVC(event: eventModel)
        }
    }
    
    @IBAction func actionLocationBtn(_ sender: Any) {
        if let delegate = delegate {
            delegate.didTappedLocation(eventModel: eventModel, cell: self)
        }else {
            APP_MANAGER.openMap(eventModel: eventModel)
        }

    }
    
    // MARK: - Public Methods
    public func setupUI(eventModel: EventFeedModel?, delegate: DateLocationCellDelegate? = nil, cellType: CellType = .homeFeed ) {
        self.cellType = cellType
        self.eventModel = eventModel
        self.delegate = delegate
        
        loadData()
        configureUI()
    }
    
    // MARK: - Private Meoths
    
    private func loadData() {
        // Date - Start, End
        lblDate.text = eventModel?.textStartEndTime()
        var height2 = lblDate.text?.height(withConstrainedWidth: MAIN_SCREEN_WIDTH - 30 - 20, font: AppFont.regular.size(15.0)) ?? 18.0
        if height2 < 18.0 {
            height2 = 18.0
        }
        heightDateLbl.constant = height2

        // Location
        var name = ""
        var address = ""
        locationLbl.text = "TBD"
        if let temp = eventModel?.address, temp != "" {
            address = temp
            locationLbl.text = address
        }
        if let temp = eventModel?.locationName, temp != "" {
            name = temp
            locationLbl.text = name
        }
        if address.substring(from: 0, length: name.count) == name {
            locationLbl.text = address
        }
        locationLbl.text = locationLbl.text?.removeOwnCountry()
        var height1 = locationLbl.text?.height(withConstrainedWidth: MAIN_SCREEN_WIDTH - 30 - 20, font: AppFont.regular.size(15.0)) ?? 18.0
        if height1 < 18.0 {
            height1 = 18.0
        }
        heightLocationLbl.constant = height1
    }
    
    private func configureUI () {
        viewTopSeparator.isHidden = true
        viewBottomSeparator.isHidden = true
        viewBottomSpace.isHidden = true

        switch cellType {
        case .homeFeed :
            viewBottomSpace.isHidden = false
            break
        case .eventDetails :
            viewTopSeparator.isHidden = false
            break
        }
    }
    
}
