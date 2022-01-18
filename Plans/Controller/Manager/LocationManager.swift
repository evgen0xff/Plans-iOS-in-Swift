//
//  LocationManager.swift
//  Plans
//
//  Created by Plans Collective LLC on 6/13/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//


import UIKit
import CoreLocation
import Foundation
import MapKit


let LOCATION_MANAGER = LocationManager.sharedInstance

class LocationManager: NSObject {
    static let sharedInstance = LocationManager()
    
    var currentLocation = CLLocation()
    var currentAddress = ""
    var city_CounAddress = ""
    var deviceToken = "12345"
    var isLive: Bool = false
    var timerLocation : Timer?

    let geocoder: CLGeocoder =  CLGeocoder()
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    
    deinit {
        NOTIFICATION_CENTER.removeObserver(self)
    }
        
    // MARK: ------------------------------------- Private Methods ------------------------
    // MARK: - Location Update
    private func stopUpdatingLocation () {
        timerLocation?.invalidate()
        timerLocation = nil
        locationManager.stopUpdatingLocation()
    }

    private func postCurrentLocation (complete: ((_ success: Bool) -> Void)? = nil) {
        guard USER_MANAGER.isLogined == true else { return }
        APP_CONFIG.backgrountQ.asyncAfter(deadline: .now() + 1) {
            print("------- LocationManager postCurrentLocation --------")
            let userInfo = ["lat" : USER_MANAGER.latitude, "long" :  USER_MANAGER.longitude]
            USER_SERVICE.hitUpdateCurrentLocation(userInfo).done { (response) -> Void in
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                self.monitorRegions()
                complete?(true)
            }.catch { (error) in
                complete?(false)
            }
        }
    }

    private func updateMyLocation(){
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
            case .restricted, .denied:
                APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.5) {
                    POPUP_MANAGER.showAlertWithAction(title: APP_CONFIG.APP_NAME, message: ConstantTexts.enableLocation.localizedString, style: .alert, actionTitles: ["Settings","Cancel"], action: { (action) in
                        if let title = action.title {
                            switch title {
                            case "Settings":
                                if let url = URL(string:UIApplication.openSettingsURLString) {
                                    if #available(iOS 10.0, *) {
                                        APPLICATION.open(url, options: APP_DELEGATE.convertToDictionary([:]), completionHandler: { (true) in
                                            
                                        })
                                    }
                                }
                            default:
                                break
                            }
                        }
                    })
                }
             default:
                break
            }
        }
    }

    // MARK: - Monitoring Regions
    private func monitorRegionAtLocation(center: CLLocationCoordinate2D,
                                 identifier: String,
                                 radius: CLLocationDistance? = nil,
                                 isStart: Bool = true ) -> CLCircularRegion? {
        // Make sure the devices supports region monitoring.
        var region: CLCircularRegion? = nil
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            region = generateRegion(center: center, identifier: identifier, radius: radius)

            if isStart == true {
                locationManager.startMonitoring(for: region!)
            }else {
                locationManager.stopMonitoring(for: region!)
            }
        }
        
        return region
    }
    
    private func generateRegion(center: CLLocationCoordinate2D,
                        identifier: String,
                        radius: CLLocationDistance? = nil) -> CLCircularRegion {
        
        let distance = (radius == nil || radius! > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius!
        let region = CLCircularRegion(center: center,
             radius: distance, identifier: identifier)
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        return region
    }
    
    private func monitorRegionAtEvent(event: EventFeedModel?, isStart: Bool = true) -> CLCircularRegion? {
        guard let eventId = event?._id, let lat = event?.lat, let long = event?.long else { return nil }
        
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let radius = event?.checkInRange != nil ? CLLocationDistance(event!.checkInRange!) : nil
        
        return monitorRegionAtLocation(center: center, identifier: eventId, radius: radius, isStart: isStart)
    }
    
    private func updateMonitering() {
        EVENT_SERVICE.getAllEventsAttended().done { list in
            self.stopMonitering()
            let events = list.filter { $0._id != nil && !$0._id!.isEmpty && $0.lat != nil && $0.long != nil }
            self.startMonitering(events: events)
        }.catch { (error) in
            
        }
    }
    
    private func stopMonitering() {
        USER_MANAGER.listMonitorRegions.forEach {
            locationManager.stopMonitoring(for: $0)
        }
        
        USER_MANAGER.listMonitorRegions = [CLCircularRegion]()
    }
    
    private func startMonitering(events: [EventFeedModel]?) {
        var listRegions = [CLCircularRegion]()

        events?.forEach({ event in
            if let region = monitorRegionAtEvent(event: event) {
                listRegions.append(region)
            }
        })
        
        USER_MANAGER.listMonitorRegions = listRegions
        
        if events?.contains(where: {$0.isLiveUser(USER_MANAGER.userId)}) == true {
            ANALYTICS_MANAGER.logEvent(.live_user)
        }
    }
    
    // MARK: -------------------------------- Public Method -------------------------------
   
    //MARK: - Update Location
    func startUpdatingLocation (complete: ((_ success: Bool) -> Void)? = nil) {
        if timerLocation != nil {
            timerLocation?.invalidate()
            timerLocation = nil
        }
        
        timerLocation = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { (timer) in
            guard USER_MANAGER.isLogined == true else { return }
            self.updateMyLocation()
            self.postCurrentLocation()
        })
        timerLocation?.tolerance = 0.2
        RunLoop.current.add(timerLocation!, forMode: .common)
        
        self.updateMyLocation()
        self.postCurrentLocation(complete: complete)
    }

    func updateLocation() {
        timerLocation?.fire()
    }

    //MARK: - Monitoring Regions
    func monitorRegions() {
        if USER_MANAGER.isLogined == true, USER_MANAGER.userId != nil, !USER_MANAGER.userId!.isEmpty {
            updateMonitering()
        }else {
            stopMonitering()
        }
    }
    
    // MARK: - Utility
    func reverseGeocoding(locationn: CLLocation, success : @escaping (CLPlacemark?) -> ()) {
        self.geocoder.reverseGeocodeLocation(locationn) { (placeMarks, error) in
            guard error == nil, let place = placeMarks?.first else {
                success(nil)
                return
            }
            
            print ("thoroughfare : ", place.thoroughfare ?? "")
            print ("subThoroughfare : ", place.subThoroughfare ?? "")
            print ("subLocality : ", place.subLocality ?? "")
            print ("locality : ", place.locality ?? "")
            print ("administrativeArea : ", place.administrativeArea ?? "")
            print ("subAdministrativeArea : ", place.subAdministrativeArea ?? "")
            print ("country : ", place.country ?? "")
            
            success(place)
        }
    }
    
    func translateCoordinate(coordinate: CLLocationCoordinate2D, metersLat: Double,metersLong: Double) -> (CLLocationCoordinate2D) {
        var tempCoord = coordinate
        
        let tempRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: metersLat, longitudinalMeters: metersLong)
        let tempSpan = tempRegion.span
        
        tempCoord.latitude = coordinate.latitude + tempSpan.latitudeDelta
        tempCoord.longitude = coordinate.longitude + tempSpan.longitudeDelta
        
        return tempCoord
    }




}

// MARK: ----------------------------------- CLLocationManagerDelegate --------------------------------

extension LocationManager: CLLocationManagerDelegate
{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        guard let lastLocation = locations.last else { return }

        currentLocation = lastLocation
        USER_MANAGER.latitude = lastLocation.coordinate.latitude
        USER_MANAGER.longitude = lastLocation.coordinate.longitude

        PLACE_SERVICE.reverseGeocoding(coordinate: lastLocation.coordinate){
            (gmsAddress, result, error) in
            if let city = gmsAddress?.locality {
                self.city_CounAddress = city
            }
            if let state = gmsAddress?.administrativeArea {
                self.city_CounAddress += ", \(state)"
            }
            if let formated = gmsAddress?.lines?.first {
                self.currentAddress = formated
            }
            USER_MANAGER.countryOwn = self.currentAddress.getCountryNameFromAddress()
        }

        locationManager.stopUpdatingLocation()
    }
    

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let _ = region as? CLCircularRegion {
            print("didEnterRegion region: \(region.identifier)")
            guard USER_MANAGER.isLogined == true else { return }
            self.updateMyLocation()
            self.postCurrentLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let _ = region as? CLCircularRegion {
            print("didExitRegion region: \(region.identifier)")
            guard USER_MANAGER.isLogined == true else { return }
            self.updateMyLocation()
            self.postCurrentLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let _ = region as? CLCircularRegion {
            print("monitoringDidFailFor region: \(region!.identifier)")
        }
        print("monitoringDidFailFor error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("didStartMonitoringFor region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("didDetermineState state: \(state.rawValue), region: \(region.identifier)")
    }
    
}
