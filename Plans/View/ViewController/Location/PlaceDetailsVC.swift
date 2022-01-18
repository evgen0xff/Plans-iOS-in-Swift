//
//  PlaceDetailsVC.swift
//  Plans
//
//  Created by Star on 2/20/21.
//

import UIKit

class PlaceDetailsVC: PlansContentBaseVC {
    @IBOutlet weak var btnCreateEvent: UIButton!

    @IBOutlet weak var imgvwPhoto: UIImageView!
    @IBOutlet weak var lblMiles: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblPlaceTypes: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var viewLocation: UIView!
    @IBOutlet weak var lblLocationAddress: UILabel!
    
    @IBOutlet weak var viewPhoneNumber: UIView!
    @IBOutlet weak var lblPhoneNumber: UILabel!
    
    @IBOutlet weak var viewOpenTime: UIView!
    @IBOutlet weak var lblOpenTime: UILabel!
    
    @IBOutlet weak var viewRating: UIView!
    @IBOutlet weak var lblRating: UILabel!
    
    @IBOutlet weak var viewWebSite: UIView!
    @IBOutlet weak var lblWebSite: UILabel!
    
    var placeModel : PlaceModel?
    var searchType = LocationSearchType.locationDiscovery
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func initializeData() {
        super.initializeData()
        fetchPlaceDetails()
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Create Event Button
        setupCreateEventUI()
        
        // Photo
        updatePhoto()
        
        // Others
        updateUI()
    }
    
    
    // MAKR: - Private Methods
    
    private func setupCreateEventUI() {
        btnCreateEvent.setTitle(searchType == .locationDiscovery ? "Create Event" : "Select", for: .normal)
    }
    
    private func updatePhoto () {
        imgvwPhoto.isHidden = false
        if let image = placeModel?.photoImage {
            imgvwPhoto.image = image
        }else {
            imgvwPhoto.image = UIImage(named: "im_placeholder_event_cover")
            PLACE_SERVICE.fetchPhotos(placeModel?.place_id) { (image, error) in
                if error != nil {
                    self.imgvwPhoto.isHidden = true
                }else {
                    self.placeModel?.photoImage = image
                    self.imgvwPhoto.image = image
                }
            }
        }
    }
    
    private func updateUI() {
        
        lblName.text = placeModel?.name
        let distance = USER_MANAGER.myLocation.getDistance(other: placeModel?.location)
        lblMiles.text = String(format:"%.2f ", distance)
        if distance >= 2 {
            lblMiles.text! += "Miles"
        }else {
            lblMiles.text! += "Mile"
        }
        lblPlaceTypes.text = placeModel?.getFormatedTypes()
        
        if let formattedAddress = placeModel?.gmsPlace?.formattedAddress ?? placeModel?.address {
            lblLocationAddress.text = formattedAddress.removeOwnCountry()
            placeModel?.formattedAddress = formattedAddress
            viewLocation.isHidden = false
        }else {
            viewLocation.isHidden = true
        }
        
        if let phoneNumber = placeModel?.gmsPlace?.phoneNumber {
            lblPhoneNumber.text = phoneNumber
            placeModel?.phoneNumber = phoneNumber
            viewPhoneNumber.isHidden = false
        }else {
            viewPhoneNumber.isHidden = true
        }
        
        if let openingHours = placeModel?.getOpenString() {
            lblOpenTime.text = openingHours
            viewOpenTime.isHidden = false
        }else {
            viewOpenTime.isHidden = true
        }
        
        if let rating = placeModel?.gmsPlace?.rating, rating != 0 {
            lblRating.text = String(format: "%.1f", rating)
            placeModel?.rating = rating
            viewRating.isHidden = false
        }else {
            viewRating.isHidden = true
        }
        
        if let website = placeModel?.gmsPlace?.website?.host {
            lblWebSite.text = website
            placeModel?.website = placeModel?.gmsPlace?.website?.absoluteString
            viewWebSite.isHidden = false
        }else {
            viewWebSite.isHidden = true
        }
        
        stackView.arrangedSubviews.forEach({$0.viewWithTag(1)?.isHidden = false})
        stackView.arrangedSubviews.last(where: {$0.isHidden == false})?.viewWithTag(1)?.isHidden = true

    }
    
    func fetchPlaceDetails () {
        showLoader()
        PLACE_SERVICE.fetchPlaceDetails(placeModel?.place_id){
            (place, error) in
            self.hideLoader()
            if error != nil {
                POPUP_MANAGER.handleError(error)
            }else {
                self.placeModel?.gmsPlace = place
                self.updateUI()
            }
        }
    }
    
    
    // MARK: - User action handler
    
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionCreateEvent(_ sender: Any) {
        switch searchType {
        case .locationDiscovery:
            APP_MANAGER.pushCreateEventVC(place: placeModel, sender: self)
            break
        default :
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kLocationSelected), object: placeModel)
            break
        }
    }
    
    @IBAction func actionAbout(_ sender: Any) {
        
    }
    
    @IBAction func actionLocation(_ sender: Any) {
        openMap(placeModel?.location?.coordinate, name: placeModel?.gmsPlace?.formattedAddress)
    }
    
    @IBAction func actionPhoneNumber(_ sender: Any) {
        callPhoneNumber(placeModel?.gmsPlace?.phoneNumber)
    }
    
    @IBAction func actionOpentTime(_ sender: Any) {
    }
    
    @IBAction func actionRating(_ sender: Any) {
    }
    
    @IBAction func actionWebSite(_ sender: Any) {
        openUrl(urlString: placeModel?.gmsPlace?.website?.absoluteString)
    }
    
}
