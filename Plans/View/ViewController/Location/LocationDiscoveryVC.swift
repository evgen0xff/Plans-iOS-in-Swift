//
//  LocationDiscoveryVC.swift
//  Plans
//
//  Created by Star on 2/20/21.
//

import UIKit
import GoogleMaps
import GooglePlaces

class LocationDiscoveryVC: DashBoardBaseVC {
    
    @IBOutlet weak var viewBack: UIView!
    @IBOutlet weak var lblCityName: UILabel!
    @IBOutlet weak var btnSearch: UIButton!
    @IBOutlet weak var btnSearchThisArea: UIButton!
    @IBOutlet weak var viewMap: UIView!
    @IBOutlet weak var btnMyLocation: UIButton!
    @IBOutlet weak var cvPlaces: UICollectionView!
    @IBOutlet weak var cvCategories: UICollectionView!
    @IBOutlet weak var viewGuide: UIView!
    
    override var screenName: String? { "Location_Screen" }

    var mapView : GMSMapView!
    var zoomLevel: Float = 15.0
    var categories = CateoryModel.plansCateories
    var places = [PlaceModel]()
    var selectedCategory : CateoryModel?
    var selectedPlace : PlaceModel?
    var searchedPlace: PlaceModel?
    var canMoveCamera : Bool = true
    var searchType = LocationSearchType.locationDiscovery
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBar()
    }
    
    override func setupUI() {
        super.setupUI()
        
        // Set up Search This Area
        btnSearchThisArea.layer.borderColor = AppColor.grey_button_border.cgColor
        btnSearchThisArea.addShadow()
        
        // Map View by Google Map
        setupMapView()
        
        // Category collection views
        cvPlaces.delegate = self
        cvPlaces.dataSource = self
        cvCategories.delegate = self
        cvCategories.dataSource = self
        cvCategories.isHidden = false
        cvPlaces.isHidden = true
        
        // Guide View
        updateGuideView()

        updateSearchedPlace(lat: USER_MANAGER.latitude, long: USER_MANAGER.longitude, isAddPinForSearchedPlace: false)
    }

    // MAKR: - Private Methods
    private func updateNavigationBar() {
        var isHiddenCenterBtn = false
        switch searchType {
        case .locationDiscovery:
            isHiddenCenterBtn = false
            viewBack.isHidden = true
            break
        default:
            isHiddenCenterBtn = true
            viewBack.isHidden = false
            break
        }
        
        APP_MANAGER.updateTabBar(isHiddenCenterAction: isHiddenCenterBtn)
    }
    
    private func setupMapView(){
        mapView?.removeFromSuperview()
        
        var lat = USER_MANAGER.latitude
        var long = USER_MANAGER.longitude
        
        if lat == 0, long == 0  {
            lat = APP_CONFIG.MAP_DEFAULT_LAT
            long = APP_CONFIG.MAP_DEFAULT_LONG
        }

        let camerPoistion = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: viewMap.bounds, camera: camerPoistion)
        viewMap.addSubview(mapView)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
    }
    
    // MAKR: - Public Methods
    public func updateSearchedPlace(lat: Double?, long: Double?, isAddPinForSearchedPlace: Bool = true) {
        guard let lat = lat, let long = long else { return }
        guard lat != 0 || long != 0 else { return }

        // remove all places searched in past
        removeAllPlaces()

        // set SearchedPlace infor
        searchedPlace = PlaceModel(lat: lat, long: long)

        // add a Pin at the searched place on Map
        if isAddPinForSearchedPlace == true {
            let coordinat = CLLocationCoordinate2D(latitude: lat, longitude: long)
            addPin(coordinate: coordinat, place: searchedPlace, iconMarker: "ic_pin_map_purple_filled")
        }
        
        // move Map Camera to the searched place
        moveCameraTo(lat: lat, long: long)
               
        // fetch City Name of the searched place
        PLACE_SERVICE.reverseGeocoding(lat: lat, long: long, typeAddress: .cityName) { (gmsAddress, result, error) in
            self.lblCityName.text = result as? String ?? gmsAddress?.administrativeArea
        }

        // fetch Places matched in the search area
        if selectedCategory != nil {
            canMoveCamera = false
            fetchPlaces(category: selectedCategory){
                self.canMoveCamera = true
            }
        }
        
        // Update Search This Area Button
        updateSearchThisAreaBtn(lat: searchedPlace?.latitude, long: searchedPlace?.longitude)
    }
    
    func updateSearchThisAreaBtn(lat: Double?, long: Double?){
        guard let lat = lat, let long = long else { return }
        let detlaLat = fabs(lat - (searchedPlace?.latitude ?? 0.0))
        let detlaLong = fabs(long - (searchedPlace?.longitude ?? 0.0))
        if (detlaLat > 0.001 || detlaLong > 0.001) && selectedCategory != nil {
            btnSearchThisArea.isHidden = false
        }else {
            btnSearchThisArea.isHidden = true
        }
    }
    
    private func updateGuideView() {
        viewGuide.isHidden = USER_MANAGER.isSeenGuideLocationDiscovery
    }
    
    public func moveCameraTo(lat: Double?, long: Double?) {
        guard let lat = lat, let long = long, canMoveCamera == true else { return }
        let camerPoistion = GMSCameraPosition.camera(withLatitude: lat,
                                              longitude: long,
                                              zoom: mapView.camera.zoom)
        mapView.animate(to: camerPoistion)
    }

    public func fetchPlaces (category: CateoryModel?, complete: (() -> Void)? = nil) {
        guard let model = category else { return }
        showLoader()
        PLACE_SERVICE.fetchPlacesNear(lat: searchedPlace?.latitude, long: searchedPlace?.longitude, radius: 2000, types: model.types) {
            ( places, error) in
            
            self.hideLoader()
            if error != nil {
                POPUP_MANAGER.handleError(error)
            }else {
                self.addPlaces(places)
                if (places?.count ?? 0) == 0 {
                    POPUP_MANAGER.makeToast("No results found")
                }
            }
            APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + 0.5) {
                complete?()
            }
        }
        
    }
    
    func removeAllPlaces () {
        self.mapView?.clear()

        searchedPlace?.marker?.map = nil
        
        self.places.forEach { place in
            place.marker?.map = nil
        }
        self.places.removeAll()

        self.cvPlaces.reloadData()
        self.cvPlaces.isHidden = true

        self.cvCategories.isHidden = false
    }
    
    func addPlaces (_ places : [PlaceModel]?){
        removeAllPlaces()
        searchedPlace?.marker?.map = mapView
        
        places?.forEach({ (place) in
            place.category = self.selectedCategory
            if place.isVaildPlace() == true {
                self.addPin(coordinate: place.location?.coordinate, place: place, iconMarker: "ic_pin_map_green_filled")
                self.places.append(place)
            }
        })

        if self.places.count > 0 {
            self.cvPlaces.isHidden = false
            self.cvCategories.isHidden = true
        }else {
            self.cvPlaces.isHidden = true
            self.cvCategories.isHidden = false
        }
        
        self.cvPlaces.reloadData()
        
        if self.places.count > 0 {
            self.cvPlaces.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        }
    }
    
    func addPin (coordinate: CLLocationCoordinate2D?, place: PlaceModel? = nil, iconMarker: String? = nil) {
        guard let coordinate = coordinate else { return }
        let marker = GMSMarker(position: coordinate)
        marker.title = place?.name
        if let iconName = iconMarker {
            marker.icon = UIImage(named: iconName)
        }
        marker.map = mapView
        place?.marker = marker
    }
    
    // MARK: - User action handlers
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionMyLocation(_ sender: Any) {
        var lat = USER_MANAGER.latitude
        var long = USER_MANAGER.longitude
        
        if lat == 0, long == 0,
           let latMapview = mapView?.myLocation?.coordinate.latitude,
           let longMapview = mapView?.myLocation?.coordinate.longitude {
            lat = latMapview
            long = longMapview
        }
        
        updateSearchedPlace(lat: lat, long: long)
    }
    
    @IBAction func actionSearchThisArea(_ sender: Any) {
        updateSearchedPlace(lat: mapView.camera.target.latitude, long: mapView.camera.target.longitude)
    }
    
    @IBAction func actionSwipeDownCategoryDetailCV(_ sender: Any) {
        cvPlaces.isHidden = true
        cvCategories.isHidden = false
        selectedCategory = nil
        btnSearchThisArea.isHidden = true
    }
    
    @IBAction func actionSearchLocation(_ sender: Any) {
        APP_MANAGER.pushSearchLocation(self, delegate: self, searchType: .locationDiscovery)
    }
    @IBAction func actionTapGuideView(_ sender: Any) {
        USER_MANAGER.isSeenGuideLocationDiscovery = true
        updateGuideView()
    }
}

// MARK: - Collection View Delegate
extension LocationDiscoveryVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
            case cvPlaces :
                return places.count
            case cvCategories :
                return categories.count
            default :
                return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var cell : UICollectionViewCell?
        switch collectionView {
            case cvPlaces :
                if let locationCell = collectionView.dequeueReusableCell(withReuseIdentifier: LocationDetailsCell.className, for: indexPath) as? LocationDetailsCell {
                    locationCell.setupUI(places[indexPath.row], index: indexPath.row + 1)
                    cell = locationCell
                }
                break
            case cvCategories :
                if let categoryCell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.className, for: indexPath) as? CategoryCell {
                    categoryCell.setupUI(model: categories[indexPath.row])
                    cell = categoryCell
                }
                break
            default :
                break
        }
        
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch collectionView {
            case cvPlaces :
                let place = places[indexPath.row]
                mapView.selectedMarker = place.marker
                moveCameraTo(lat: place.latitude, long: place.longitude)
                break
            case cvCategories :
                selectedCategory = nil
                break
            default :
                break
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
            case cvPlaces :
                selectedPlace = places[indexPath.row]
                APP_MANAGER.pushPlaceDetailsVC(place: selectedPlace, sender: self, searchType: searchType)
                break
            case cvCategories :
                selectedCategory = categories[indexPath.row]
                fetchPlaces(category: selectedCategory)
                break
            default :
                break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
                
        return collectionView.bounds.size
    }
    
}

// MARK: - GMSMapViewDelegate
extension LocationDiscoveryVC : GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let index = self.places.firstIndex(where: { (place) -> Bool in
            return place.marker == marker
        }) {
            cvPlaces.scrollToItem(at: IndexPath(row: index, section: 0), at: .right, animated: false)
        }
        return true
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        updateSearchThisAreaBtn(lat: position.target.latitude, long: position.target.longitude)
    }
}

// MARK: - LocationSearchDelegate

extension LocationDiscoveryVC : LocationSearchDelegate {
    func didSelectLocation(place: PlaceModel?) {
//        let index = cvCategories.indexPathsForVisibleItems.first?.row ?? 0
//        selectedCategory = selectedCategory ?? categories[index]
        updateSearchedPlace(lat: place?.latitude, long: place?.longitude)
    }
}
