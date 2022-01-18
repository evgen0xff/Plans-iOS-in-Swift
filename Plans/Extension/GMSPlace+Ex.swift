//
//  GMSPlace+Additions.swift
//  Plans
//
//  Created by Star on 5/27/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

extension GMSPlace {
    
    func getOpenNowString() -> String? {
        guard let utcOffsetMinutes = utcOffsetMinutes?.intValue else { return nil }
        guard let weekdayText = openingHours?.weekdayText else { return nil }

        print ("place_id : ", placeID ?? "No place Id")
        print ("utcOffsetMinutes : ", utcOffsetMinutes)

        var result : String?
        let curDate = Date()
        if let targetWeekday = curDate.dateCompoments(utcOffsetMinutes).weekday {
            let dayText = targetWeekday.getDayofWeek()
            print ("targetWeekday, dayText : ", targetWeekday, dayText)
            
            switch isOpen() {
            case .open:
                result = "Open now"
                if var periodText = weekdayText.first(where: { (item) -> Bool in
                    return item.contains(dayText)
                }) {
                    periodText = periodText.replacingOccurrences(of: dayText, with: "")
                    periodText = periodText.replacingOccurrences(of: "Open ", with: "")
                    result! += periodText
                }
            case .closed:
                result = "Closed now: " + (firstNextOpenTimeString(curDate) ?? "")
            default:
                break
            }
        }

        return result
    }
    
    func firstNextOpenTimeString(_ date: Date) -> String? {
        
        guard let utcOffsetMinutes = utcOffsetMinutes?.intValue else { return nil }
        guard let periods = openingHours?.periods else { return nil }
        guard let weekday = date.dateCompoments(utcOffsetMinutes).weekday else { return nil}
        guard let hour = date.dateCompoments(utcOffsetMinutes).hour else { return nil}
        guard let minute = date.dateCompoments(utcOffsetMinutes).minute else { return nil}
        
        var result = ""
        let currentTime = hour * 60 + minute
        if let period = periods.first(where: { (item) -> Bool in
            let start = item.openEvent.time.hour * 60 + item.openEvent.time.minute
            if item.closeEvent != nil {
                return item.openEvent.day.rawValue == weekday && start > currentTime
            }else {
                return true
            }
        }){
            result = "Opens " + period.getString(utcOffsetMinutes, isStartOnly: true) + " Today"
        }else {
            for i in 1...6 {
                let nextWeekday = ((weekday + i) - 1 ) % 7 + 1
                if let period = periods.first(where: { (item) -> Bool in
                    return item.openEvent.day.rawValue == nextWeekday
                }){
                    result = "Opens " + period.getString(utcOffsetMinutes, isStartOnly: true)
                    if abs(nextWeekday - weekday) > 1 {
                        result += " " + nextWeekday.getDayofWeek()
                    }else {
                        result += " Tomorrow"
                    }
                    break
                }
            }
        }

        return result
    }
}

extension GMSPeriod {
    
    func getString(_ utcOffsetMinutes: Int? = nil, isStartOnly: Bool = false) -> String {
        var result = ""
        if let closeEvent = closeEvent {
            result = openEvent.getString(utcOffsetMinutes)
            if isStartOnly == false {
                result += " - " + closeEvent.getString(utcOffsetMinutes)
            }
        }else {
            result = "24 hours"
        }
        return result
    }

}

extension GMSEvent {
    func getString(_ utcOffsetMinutes: Int? = nil) -> String {
        var result = ""
        var dateComponents = DateComponents()
        dateComponents.hour = Int(time.hour)
        dateComponents.minute = Int(time.minute)
        let date = Date.dateWithUtcOffsetMinutes(dateComponents: dateComponents)
        result = date?.dateStringWith(strFormat: "h:mm a") ?? ""
        return result
    }
}

extension GMSCircle {
    func bounds () -> GMSCoordinateBounds {
        func locationMinMax(positive : Bool) -> CLLocationCoordinate2D {
            let sign:Double = positive ? 1 : -1
            let dx = sign * self.radius  / 6378000 * (180/Double.pi)
            let lat = position.latitude + dx
            let lon = position.longitude + dx / cos(position.latitude * Double.pi/180)
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        return GMSCoordinateBounds(coordinate: locationMinMax(positive: true),
                                   coordinate: locationMinMax(positive: false))
    }
}

// Animate GMS Circle on selection of range
extension GMSMapView {
    
    func setRadius(radius: Double?, location: CLLocationCoordinate2D?) {
        guard let radius = radius, let location = location else { return }

        let range = LOCATION_MANAGER.translateCoordinate(coordinate: location, metersLat: radius * 2, metersLong: radius * 2)
        let bounds = GMSCoordinateBounds(coordinate: location, coordinate: range)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 5.0)    // padding set to 5.0
        
        animate(with: update)
        
        // location
        let marker = GMSMarker(position: location)
        marker.icon = UIImage(named: "ic_pin_map_purple_filled")
        marker.map = self
        marker.appearAnimation = GMSMarkerAnimation.pop
        
        // draw circle
        let circ = GMSCircle(position: location, radius: radius)
        circ.fillColor = AppColor.teal_map_circle
        circ.strokeWidth = 0;
        circ.map = self
        
        animate(toLocation: location) // animate to center
    }
    
}


