//
//  LocationSearchVC.swift
//  Plans
//
//  Created by Plans Collective LLC on 5/21/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import UIKit
import GooglePlaces

enum LocationSearchType {
    case editEvent
    case createEvent
    case locationDiscovery
}

protocol LocationSearchDelegate {
    func didSelectLocation(place: PlaceModel?)
}

extension LocationSearchDelegate {
    func didSelectLocation(place: PlaceModel?){}
}

class LocationSearchVC: PlansContentBaseVC{
    
    // MARK: - All IBOutlet
    @IBOutlet weak var viewFindPlaces: UIView!
    @IBOutlet weak var btnFindPlaces: UIButton!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var listData: UITableView!
    
    // MARK: - All Properties
    var delegate : LocationSearchDelegate?
    var arrPlaces = [GMSAutocompletePrediction]()
    var placeSelected: PlaceModel?
    var searchType = LocationSearchType.locationDiscovery

    // MARK: - View LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if searchType != .locationDiscovery {
            NOTIFICATION_CENTER.addObserver(self, selector: #selector(handleLocationSelected(_:)), name: Notification.Name(rawValue: kLocationSelected), object: nil)
        }
    }

    override func setupUI(){
        super.setupUI()
        
        setupSearchView()
        setupTableView()
        setupFindPlacesUI()
        updateFindPlacesUI()
     }
    
    // MARK: - Private Methods

    func setupSearchView() {
        searchField.attributedPlaceholder = NSAttributedString(string: "Search",
                                                               attributes: [NSAttributedString.Key.foregroundColor: AppColor.whiteOpacity60])
        searchField.delegate = self
    }

    
    private func setupTableView() {
        listData.register(nib: PlaceInfoTVCell.className)
        listData.dataSource = self
        listData.delegate = self
    }
    
    private func setupFindPlacesUI() {
        btnFindPlaces.layer.borderColor = AppColor.grey_button_border.cgColor
    }
    
    private func updateUI(list: [GMSAutocompletePrediction]?) {
        arrPlaces.removeAll()
        if let list = list {
            arrPlaces.append(contentsOf: list)
        }
        listData.reloadData()
        updateFindPlacesUI()
    }
    
    private func updateFindPlacesUI() {
        switch searchType {
        case .createEvent, .editEvent:
            viewFindPlaces.isHidden = arrPlaces.count != 0
        default:
            viewFindPlaces.isHidden = true
            break
        }
    }
    
    // MARK: - User Action Handlers

    @IBAction func actionBackBtn(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionFindPlacesBtn(_ sender: Any) {
        APP_MANAGER.pushLocationDiscoveryVC(searchType: searchType, sender: self)
    }
    @IBAction func actionCurrentLocation(_ sender: UIButton){
        let place = PlaceModel()
        place.latitude = LOCATION_MANAGER.currentLocation.coordinate.latitude
        place.longitude = LOCATION_MANAGER.currentLocation.coordinate.longitude
        place.location = LOCATION_MANAGER.currentLocation
        place.address = LOCATION_MANAGER.currentAddress
        
        selectLocation(place)
    }
    
    @IBAction func actionChangedSearchText(_ sender: Any) {
        forwardGeoCoding(searchText: searchField.text)
    }
    
    @objc func handleLocationSelected(_ notify: NSNotification?) {
        selectLocation(notify?.object as? PlaceModel)
    }
    
    func selectLocation(_ place: PlaceModel?) {
        guard let place = place else { return }
        placeSelected = place
        delegate?.didSelectLocation(place: self.placeSelected)
        
        if let index = navigationController?.viewControllers.lastIndex(of: self),
           (index - 1) >= 0,
           let preVC = navigationController?.viewControllers[index - 1]{
            navigationController?.popToViewController(preVC, animated: true)
        }
    }
}

extension LocationSearchVC {
    func forwardGeoCoding(searchText: String?) {
        PLACE_SERVICE.findAutocompletePredictions(searchText: searchText) { (result, success) in
            APP_CONFIG.defautMainQ.async(execute: {
                self.updateUI(list: result)
            })
        }
    }
    
    func getPlaceDetailsFrom(placeId : String?) {
        showLoader()
        PLACE_SERVICE.getPlaceDetailsFrom(placeId: placeId) { (gmPlace, success) in
            self.hideLoader()
            if success == true, let placeData = gmPlace {
                let place = PlaceModel(gmsPlace: placeData)
                self.selectLocation(place)
            }else {
                POPUP_MANAGER.makeToast("Can't get the place details")
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension LocationSearchVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = listData.dequeueReusableCell(withIdentifier: PlaceInfoTVCell.className, for: indexPath) as? PlaceInfoTVCell
        cell?.placeNameLbl.text = arrPlaces[indexPath.row].attributedFullText.string.removeOwnCountry()
        print("//////////////// - LocationSearch : ", arrPlaces[indexPath.row].attributedFullText.string)
        return cell ?? UITableViewCell()
    }
}

// MARK: - UITableViewDelegate
extension LocationSearchVC: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchField.text = arrPlaces[indexPath.row].attributedFullText.string.removeOwnCountry()
        getPlaceDetailsFrom(placeId: arrPlaces[indexPath.row].placeID)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate
extension LocationSearchVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return view.endEditing(true)
    }
}

