//
//  PlaceModel.swift
//  Plans
//
//  Created by Star on 5/23/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import CoreLocation
import ObjectMapper
import GooglePlaces
import GoogleMaps

class PlaceModel: BaseModel {
    
    var latitude: Double?
    var longitude: Double?
    var icon: String?
    var name: String?
    var place_id: String?
    var types: [String]?
    var address: String?
    var formattedAddress: String?
    var phoneNumber: String?
    var rating: Float?
    var website: String?
    
    var photoImage: UIImage?
    var location: CLLocation?
    var marker: GMSMarker?
    var category: CateoryModel?
    var gmsPlace: GMSPlace?

    init(lat: Double? = nil, long: Double? = nil, marker: GMSMarker? = nil){
        super.init()
        
        self.latitude = lat
        self.longitude = long
        self.marker = marker
        
        if latitude != nil, longitude != nil {
            self.location = CLLocation(latitude: latitude!, longitude: longitude!)
        }
    }
    
    init(gmsPlace: GMSPlace?) {
        super.init()

        self.gmsPlace = gmsPlace
        name = gmsPlace?.name
        address = gmsPlace?.formattedAddress
        formattedAddress = gmsPlace?.formattedAddress
        phoneNumber = gmsPlace?.phoneNumber
        latitude = gmsPlace?.coordinate.latitude
        longitude = gmsPlace?.coordinate.longitude
        place_id = gmsPlace?.placeID
        rating = gmsPlace?.rating
        
        if latitude != nil , longitude != nil {
            location = CLLocation(latitude: latitude!, longitude: longitude!)
        }

    }
    
    required init?(map: Map) {
        super.init(map: map)
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        icon            <- map["icon"]
        name            <- map["name"]
        place_id        <- map["place_id"]
        types           <- map["types"]
        address         <- map["vicinity"]
        formattedAddress <- map["formatted_address"]
        rating           <- map["rating"]
        phoneNumber      <- map["formatted_phone_number"]
        website          <- map["website"]

        var geometry : [String:Any]?
        geometry <- map["geometry"]
        if geometry != nil, let location = geometry!["location"] as? [String: Any]  {
            latitude = location["lat"] as? Double
            longitude = location["lng"] as? Double
            if latitude != nil, longitude != nil {
                self.location = CLLocation(latitude: latitude!, longitude: longitude!)
            }
        }
    }
    
    func getFormatedTypes() -> String {
        var types = [String]()
        self.types?.forEach({ (item) in
            if item.contains("_") == false, item != "food", item != "establishment" {
                types.append(item.capitalized)
            }
        })
        return types.joined(separator: " • ")
    }
    
    func getOpenString() -> String? {
        return gmsPlace?.getOpenNowString()
    }
    
    func isVaildPlace() -> Bool {
        var result = true
        if let restricts = category?.typesRestricted, restricts.count > 0 {
            restricts.forEach { (item) in
                if types?.contains(item) == true {
                    result = false
                }
            }
        }
        return result
    }
}
