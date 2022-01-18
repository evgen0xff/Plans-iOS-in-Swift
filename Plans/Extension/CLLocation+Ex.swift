//
//  CLLocation+Ex.swift
//  Plans
//
//  Created by Star on 2/20/21.
//

import UIKit
import CoreLocation
import Foundation

extension CLLocation {
    
    func getDistance(other: CLLocation?, unit: UnitLength = .miles) -> Double {
        guard let other = other else { return 0}
        let distance = self.distance(from: other)
        let distanceMeters = Measurement(value: distance, unit: UnitLength.meters)
        let miles = distanceMeters.converted(to: unit).value
        return miles
    }
    
    func getDistance(coordinate: CLLocationCoordinate2D?, unit: UnitLength = .miles) -> Double {
        guard let coordinate = coordinate else { return 0}
        let other = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return getDistance(other: other, unit: unit)
    }

    func getDistance(lat: Double?, long: Double?, unit: UnitLength = .miles) -> Double {
        guard let lat = lat, let long = long else { return 0}
        let other = CLLocation(latitude: lat, longitude: long)
        return getDistance(other: other, unit: unit)
    }

}
