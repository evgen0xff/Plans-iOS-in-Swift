//
//  DetailsOfEventVC.swift
//  Plans
//
//  Created by Star on 2/13/21.
//

import UIKit
import MapKit
import GoogleMaps
import ActiveLabel

class DetailsOfEventVC: EventBaseVC {

    @IBOutlet weak var viewContent: UIView!

    @IBOutlet weak var viewDetailsInfo: UIView!
    @IBOutlet weak var stackvDetailsInfo: UIStackView!

    @IBOutlet weak var viewCaption: UIView!
    @IBOutlet weak var lblCaption: ActiveLabel!
    
    @IBOutlet weak var viewDescription: UIView!
    @IBOutlet weak var lblDescription: ActiveLabel!
    
    @IBOutlet weak var viewLocationName: UIView!
    @IBOutlet weak var lblLocationName: UILabel!
    
    @IBOutlet weak var viewLocationAddress: UIView!
    @IBOutlet weak var lblLocationAddress: UILabel!
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var btnMyLocation: UIButton!
    @IBOutlet weak var btnDirections: UIButton!
    
    @IBOutlet weak var constMapViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeData() {
        super.initializeData()
    }
    
    override func setupUI() {
        super.setupUI()
        
        viewDetailsInfo.addShadow()
        mapView.isMyLocationEnabled = true
        setupActiveLabel(label: lblCaption)
        setupActiveLabel(label: lblDescription)
    }
    
    override func refreshAll(isShowLoader: Bool = false) {
        super.refreshAll(isShowLoader: isShowLoader)
        
        updateUI()
    }
    
    // MARK: - Private Methods
    
    private func updateUI() {
        updateDetailsInfo(event: activeEvent)
        updateLocationUI(event: activeEvent)
        adjustHeights()
    }
    
    private func adjustHeights() {
        view.layoutIfNeeded()
        
        var heightMapView = viewContent.bounds.height - viewDetailsInfo.bounds.height
        if heightMapView < MAIN_SCREEN_WIDTH {
            heightMapView = MAIN_SCREEN_WIDTH
        }
        constMapViewHeight.constant = heightMapView
    }
    
    private func updateDetailsInfo(event: EventFeedModel?) {
        guard let event = event else {
            viewDetailsInfo.isHidden = true
            return
        }
        
        viewDetailsInfo.isHidden = false
        
        // Cation of Event
        if let caption = event.caption, caption != "" {
            viewCaption.isHidden = false
            lblCaption.text = caption
        }else {
            viewCaption.isHidden = true
        }

        // Event Detials
        if let detail = event.detail, detail != "" {
            viewDescription.isHidden = false
            lblDescription.text = detail
        }else {
            viewDescription.isHidden = true
        }

        var name = ""
        var address = ""
        if let temp = event.address, temp != "" {
            address = temp
        }
        if let temp = event.locationName, temp != "" {
            name = temp
        }
        
        // Event Location Name
        if name != "", address.substring(from: 0, length: name.count) != name {
            viewLocationName.isHidden = false
            lblLocationName.text = name.removeOwnCountry()
        }else {
            viewLocationName.isHidden = true
        }

        // Event Location Address
        viewLocationAddress.isHidden = false
        if name == "", address == "" {
            lblLocationAddress.text = "TBD"
        }else if address != ""{
            lblLocationAddress.text = address.removeOwnCountry()
        }
        

        stackvDetailsInfo.arrangedSubviews.forEach({$0.viewWithTag(1)?.isHidden = false})
        stackvDetailsInfo.arrangedSubviews.last(where: {$0.isHidden == false})?.viewWithTag(1)?.isHidden = true
        
    }
    
    func updateLocationUI(event: EventFeedModel?) {
        guard let event = event ?? activeEvent, let lat = event.lat, let long = event.long, lat != 0.0, long != 0.0 else {
            mapView.isHidden = true
            btnMyLocation.isHidden = true
            btnDirections.isHidden = true
            mapView.clear()
            return
        }
        
        // Map view
        mapView.isHidden = false
        btnMyLocation.isHidden = false
        btnDirections.isHidden = false
        mapView.clear()

        let location = CLLocationCoordinate2DMake(lat,  long)
        let camera = GMSCameraPosition(latitude: location.latitude, longitude: location.longitude, zoom: 15.0)
        mapView.animate(to: camera)

        let regionRadius = CLLocationDistance(event.checkInRange ?? "")
        mapView.setRadius(radius: regionRadius, location: location)
    }

    func moveCameraTo(lat: Double?, long: Double?) {
        guard let lat = lat, let long = long else { return }
        let camera = GMSCameraPosition.camera(withLatitude: lat,
                                              longitude: long,
                                              zoom: mapView.camera.zoom)
        mapView.animate(to: camera)
    }

    // MARK: - User Actions
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func actionDirectionsBtn(_ sender: Any) {
        APP_MANAGER.openMapForDirections(event: activeEvent, sender: self)
    }
    
    @IBAction func actionMyLocation(_ sender: Any) {
        moveCameraTo(lat: USER_MANAGER.latitude, long: USER_MANAGER.longitude)
    }
    
}
