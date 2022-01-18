//
//  String+Ex.swift
//  Plans
//
//  Created by Star on 5/12/20.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//


import Foundation

struct DateFormat
{
    static let shortDateFormat = "dd.MM.yyyy"
    static let fullDateFormat  = "HH:mm dd.MM.yyyy"
    static let onlyTimeFormat  = "HH a"
    static let exactTimeFormat = "HH:mm"
    static let hourMinuteWithAmPm = "h:mm a"
    static let onlyDay         = "EEEE"
    static let dayOfMonth      = "dd MMM"
    static let dayOfYear       = "dd MMM, yyyy"
    static let monthOfYear     = "MMMM yyyy"
    static let apiDate         = "yyyy-MM-dd"
    static let fbApiDate       = "MM/dd/yyyy"
    static let apiTime         = "HH:mm:ss"
    static let apiDateTime     = "yyyy-MM-dd HH:mm:ss"
    static let apiPostDateTime = "dd.MM.yyyy HH:mm:ss"
    static let apiDateTimeZone = "yyyy-MM-dd HH:mm:ss ZZZ"
}

extension Date {
    
    static func dateWithUtcOffsetMinutes(dateComponents: DateComponents, utcOffsetMinutes: Int? = nil) -> Date? {
        var targetCalendar = Calendar.current
        if let utcOffsetMinutes = utcOffsetMinutes,
            let timeZone = TimeZone(secondsFromGMT: utcOffsetMinutes * 60) {
            targetCalendar = Calendar(identifier: .gregorian)
            targetCalendar.timeZone = timeZone
        }
        
        return targetCalendar.date(from: dateComponents)
    }
    
    // MARK: - Instance Methods

    func dateCompoments (_ utcOffsetMinutes : Int? = nil) -> DateComponents {

        var targetCalendar = Calendar.current

        if let utcOffsetMinutes = utcOffsetMinutes,
            let timeZone = TimeZone(secondsFromGMT: utcOffsetMinutes * 60) {
            targetCalendar = Calendar(identifier: .gregorian)
            targetCalendar.timeZone = timeZone
        }

        return  targetCalendar.dateComponents([.second, .minute, .hour, .day, .weekday, .month, .year], from: self)
    }
    
    
    
    func userAge() -> Int? {
        
        let units:NSCalendar.Unit = [.year]
        
        let calendar = NSCalendar.current as NSCalendar
        calendar.timeZone = NSTimeZone.default
        calendar.locale = NSLocale.current
        let components = calendar.components(units, from: self, to: Date(), options: NSCalendar.Options.wrapComponents)

        return components.year
    }
    
    public func dateStringWith(strFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.dateFormat = strFormat
        return dateFormatter.string(from: self)
    }

    public func startTimeOfDay () -> Date? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let time = Calendar.current.date(from:components)
        return time
    }

    public func endTimeOfDay () -> Date? {
        var comps = DateComponents()
        comps.day = 1
        guard let startTime = self.startTimeOfDay() else { return nil }
        let endTime = Calendar.current.date(byAdding: comps, to: startTime)

        return endTime
    }
    
    public func getDateWith(time: Date) -> Date? {
        var componentsDate = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let componentsTime = Calendar.current.dateComponents([.hour, .minute, .second], from: time)
        componentsDate.hour = componentsTime.hour
        componentsDate.minute = componentsTime.minute
        componentsDate.second = componentsTime.second
        return Calendar.current.date(from:componentsDate)
    }

    public func dateWithoutSeconds() -> Date? {
        let componentsDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return Calendar.current.date(from:componentsDate)
    }

    public func addOneMin() -> Date {
        return Date(timeIntervalSince1970: self.timeIntervalSince1970 + 60)
    }

    public func addOneDay30min() -> Date {
        return Date(timeIntervalSince1970: self.timeIntervalSince1970 + (3600 * 24 + 60 * 30))
    }

    public func firstDayofMonth () -> Date? {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        let startOfMonth = Calendar.current.date(from:components)
        return startOfMonth
    }
    
    public func agoYears(years: Int) -> Date {
        let curCalender = Calendar.current
        var curDateComponet = curCalender.dateComponents([.year, .day, .month], from: self)
        if curDateComponet.year != nil {
            curDateComponet.year! -= years
        }
        return curCalender.date(from: curDateComponet) ?? Date()
    }
    
    public func date(month: Int? = nil, day: Int? = nil, year: Int? = nil) -> Date {
        let curCalender = Calendar.current
        var curDateComponet = curCalender.dateComponents([.year, .day, .month], from: self)
        if let month = month {
            curDateComponet.month = month
        }
        if let day = day {
            curDateComponet.day = day
        }
        if let year = year {
            curDateComponet.year = year
        }
        return curCalender.date(from: curDateComponet) ?? Date()
    }

    public func lastDayofMonth () -> Date? {
        var comps = DateComponents()
        comps.month = 1
        guard let startOfMonth = self.firstDayofMonth() else { return nil }
        let endOfMonth = Calendar.current.date(byAdding: comps, to: startOfMonth)

        return endOfMonth
    }

    func convertToLocalTime(fromTimeZone timeZoneAbbreviation: String) -> Date? {
        if let timeZone = TimeZone(abbreviation: timeZoneAbbreviation) {
            let targetOffset = TimeInterval(timeZone.secondsFromGMT(for: self))
            let localOffeset = TimeInterval(TimeZone.autoupdatingCurrent.secondsFromGMT(for: self))
            
            return self.addingTimeInterval(targetOffset - localOffeset)
        }
        
        return nil
    }
    
    
    public var calendar: Calendar {
        return Calendar.current
    }
    
    /// Era.
    public var era: Int {
        return calendar.component(.era, from: self)
    }
    
    /// Year.
    public var year: Int {
        get {
            return calendar.component(.year, from: self)
        }
    }
    
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        let minutes = 60
        let hour  = 60 * minutes
        let day = 24 * hour
        let week = 7 * day
        
        if secondsAgo < minutes {
            return "Now"
        } else if secondsAgo < hour {
            return "\(secondsAgo/minutes) m"
        } else if secondsAgo < day {
            return "\(secondsAgo/hour) h"
        } else if secondsAgo < week {
            return "\(secondsAgo/day) days ago"
        }
        
        return "\(secondsAgo/week) weeks ago"
    }

    public func timeAgoSince() -> String {
        
        let calendar = Calendar.current
        let now = Date()
        let unitFlags: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfYear, .month, .year]
        let components = (calendar as NSCalendar).components(unitFlags, from: self, to: now, options: [])
        
        if let year = components.year, year >= 2 {
            return getDateFromString(date: self)!
        }
        
        if let year = components.year, year >= 1 {
            return getDateFromString(date: self)!
        }
        
        if let month = components.month, month >= 2 {
            return getDateFromString(date: self)!
        }
        
        if let month = components.month, month >= 1 {
            return getDateFromString(date: self)!
        }
        
        if let week = components.weekOfYear, week >= 2 {
            return getDateFromString(date: self)!
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return getDateFromString(date: self)!
        }
        
        if let day = components.day, day >= 2 {
            return "\(day)d"
        }
        
        if let day = components.day, day >= 1 {
            return "1d"
        }
        
        if let hour = components.hour, hour >= 2 {
            return "\(hour)h"
        }
        
        if let hour = components.hour, hour >= 1 {
            return "1h"
        }
        
        if let minute = components.minute, minute >= 2 {
            return "\(minute)m"
        }
        
        if let minute = components.minute, minute >= 1 {
            return "1m"
        }
        
        return "Now"
        
    }
       
    func getStartedString (isStarted : Bool = true) -> String {
        var result = ""
        let now = Date()
        let calendar = Calendar.current
        let curYear = calendar.component(.year, from: now)
        let year = calendar.component(.year, from: self)

        
        if calendar.isDateInToday(self) { // Today
            if now > self {
                if isStarted == true {
                    result = "Started today at " + self.dateStringWith(strFormat: "h:mm a")
                }else if now.timeIntervalSince1970 > (self.timeIntervalSince1970 + 60){
                    result = "Running Late"
                }else {
                    result = "Today at " + self.dateStringWith(strFormat: "h:mm a")
                }
            }else {
                result = "Today at " + self.dateStringWith(strFormat: "h:mm a")
            }
        }else if calendar.isDateInTomorrow(self) { // Tomorrow
            result = "Tomorrow at " + self.dateStringWith(strFormat: "h:mm a")
        }else if now > self { // past
            if isStarted == true {
                if curYear == year {
                    result = "Started on " + self.dateStringWith(strFormat: "MMM d")
                }else {
                    result = "Started on " + self.dateStringWith(strFormat: "MMM d, yyyy")
                }
            }else {
                result = "Running Late"
            }
        }else { // future
            if curYear == year {
                result = self.dateStringWith(strFormat: "MMM d")
            }else {
                result = self.dateStringWith(strFormat: "MMM d, yyyy")
            }
        }

        return result
    }

    func getTodayTomorrowString (isStarted : Bool? = false) -> String {
        var result = ""
        let now = Date()
        let calendar = Calendar.current
        let curYear = calendar.component(.year, from: now)
        let year = calendar.component(.year, from: self)

        if calendar.isDateInToday(self) { // Today
            if now > self {
                if isStarted == true {
                    result = "Started today at " + self.dateStringWith(strFormat: "h:mm a")
                }else if now.timeIntervalSince1970 > (self.timeIntervalSince1970 + 60){
                    result = "Running Late"
                }else {
                    result = "Today at " + self.dateStringWith(strFormat: "h:mm a")
                }
            }else {
                result = "Today at " + self.dateStringWith(strFormat: "h:mm a")
            }
        }else if calendar.isDateInTomorrow(self) { // Tomorrow
            result = "Tomorrow at " + self.dateStringWith(strFormat: "h:mm a")
        }else if now > self { // past
            if isStarted == true {
                if curYear == year {
                    result = self.dateStringWith(strFormat: "MMM d")
                }else {
                    result = self.dateStringWith(strFormat: "MMM d, yyyy")
                }
            }else {
                result = "Running Late"
            }
        }else { // future
            if curYear == year {
                result = self.dateStringWith(strFormat: "MMM d")
            }else {
                result = self.dateStringWith(strFormat: "MMM d, yyyy")
            }
        }

        return result
    }
    
    func stringDate() -> String {
        var result = ""
        let now = Date()
        let calendar = Calendar.current
        let curYear = calendar.component(.year, from: now)
        let year = calendar.component(.year, from: self)

        if calendar.isDateInToday(self) { // Today
            result = "Today"
        }else if calendar.isDateInTomorrow(self) { // Tomorrow
            result = "Tomorrow"
        }else if calendar.isDateInYesterday(self) { // Yesterday
            result = "Yesterday"
        }else if curYear ==  year {
            result = self.dateStringWith(strFormat: "MMMM d")
        }else {
            result = self.dateStringWith(strFormat: "MMMM d, yyyy")
        }
        return result
    }

    func getDateFromString(date: Date) -> String? {
        let year = Calendar.current.component(.year, from: date)
        let curYear = Calendar.current.component(.year, from: Date())
        let dateFormatter = DateFormatter()

        if year == curYear {
            dateFormatter.dateFormat = "MMM d"
            let strDate = dateFormatter.string(from: date)
            return strDate
        } else {
            dateFormatter.dateFormat = "MMM d, yyyy"
            let strDate = dateFormatter.string(from: date)
            return strDate
        }
    }
    
    func getTimeFromString(date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.dateFormat = "h:mm a"
        let strDate = dateFormatter.string(from: date)
        return strDate
    }
    
    func localDate() -> Date {
        
        if let timeZone = TimeZone(abbreviation: "UTC") {
            let seconds = TimeInterval(timeZone.secondsFromGMT(for: self))
            return Date(timeInterval: seconds, since: self)
        }
        return self
    }
    // or GMT time
    func utcDate() -> Date {
        
        if let timeZone = TimeZone(abbreviation: "UTC") {
            let seconds = -TimeInterval(timeZone.secondsFromGMT(for: self))
            return Date(timeInterval: seconds, since: self)
        }
        return self
    }
}

extension Double {
    
    func toSecond() -> Double {
        return self / 1000
    }
    
    func getDateStringFromUTC() -> String {
        let date = Date(timeIntervalSince1970: self.toSecond())
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.local
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
    
    func getDateStringWithFomat(_ format: String) -> String {
        let date = Date(timeIntervalSince1970: self.toSecond())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func getDateFromUTC() -> Date? {
        let dateStr = self.getDateStringFromUTC()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.local
        dateFormatter.dateStyle = .medium
        return dateFormatter.date(from: dateStr)
    }
    
    func getTime24HourFromUTC() -> String {
        let date = Date(timeIntervalSince1970: self.toSecond())
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.local
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from: date)
    }
}
