//
//  CalendarEventCell.swift
//  Plans
//
//  Created by Plans Collective LLC on 30/05/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit

class CalendarEventCell: BaseTableViewCell{
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var lblDayOfEvent: UILabel!
    @IBOutlet weak var lblStartTime: UILabel!
    @IBOutlet weak var lblDash: UILabel!
    @IBOutlet weak var lblEndTime: UILabel!
    @IBOutlet weak var lblEventName: UILabel!
    @IBOutlet weak var lblEventLocation: UILabel!
    
    // MARK: - View LifeCycle
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCellWithData(_ calendarModel : EventCalendarModel, selectedDate: Date?)
    {
        lblDayOfEvent.text = ""
        lblStartTime.text = ""
        lblEndTime.text = ""
        lblEventName.text = ""
        lblEventLocation.text = ""
        
        // Location Name
        var placeName = "TBD"
        var name = ""
        var address = ""
        if let temp = calendarModel.address, temp != "" {
            address = temp
            placeName = address
        }
        
        if let temp = calendarModel.locationName, temp != "" {
            name = temp
            placeName = name
        }
        
        if address.substring(from: 0, length: name.count) == name {
            placeName = address
        }
        
        lblEventLocation.text = placeName.removeOwnCountry()

        guard let startTime = calendarModel.startTime, let endTime = calendarModel.endTime, let selectedDate = selectedDate else { return }
        let startDate = Date(timeIntervalSince1970: startTime)
        let endDate = Date(timeIntervalSince1970: endTime)
        guard let selectedDay = selectedDate.startTimeOfDay(), let startDay = startDate.startTimeOfDay(), let endDay = endDate.startTimeOfDay() else { return }
        guard let totalDays = Calendar.current.dateComponents([.day], from: startDay, to: endDay).day,
            let passedDays = Calendar.current.dateComponents([.day], from: startDay, to: selectedDay).day,
            let remainedDays = Calendar.current.dateComponents([.day], from: selectedDay, to: endDay).day else { return }
        
        // Day of Event
        if totalDays > 0 {
            lblDayOfEvent.text = String(format: "Day %d/%d", passedDays + 1, totalDays + 1)
        }

        // Start Time / End Time
        if totalDays == 0 {
            lblStartTime.text = startDate.dateStringWith(strFormat: "h:mm a")
            lblEndTime.text = endDate.dateStringWith(strFormat: "h:mm a")
        }else if passedDays == 0 { // First day
            lblStartTime.text = startDate.dateStringWith(strFormat: "h:mm a")
            lblEndTime.text = "12:00 AM"
        }else if remainedDays == 0 { // Last day
            lblStartTime.text = "12:00 AM"
            lblEndTime.text = endDate.dateStringWith(strFormat: "h:mm a")
        }else {
            lblStartTime.text = "All-day"
        }
        
        lblStartTime.isHidden = lblStartTime.text == ""
        lblEndTime.isHidden = lblEndTime.text == ""
        lblDash.isHidden = lblStartTime.isHidden || lblEndTime.isHidden

        // Event Name
        lblEventName.text = calendarModel.eventsName
    }
    
}
