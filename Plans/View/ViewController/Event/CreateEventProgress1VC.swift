//
//  CreateEventProgress1VC.swift
//  Plans
//
//  Created by Star on 2/18/21.
//


import Foundation
import UIKit
import MaterialComponents
import MapKit
import GoogleMaps

class CreateEventProgress1VC: PlansContentBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var txtStartDate: MDCTextField!
    @IBOutlet weak var txtEndDate: MDCTextField!
    @IBOutlet weak var txtStartTime: MDCTextField!
    @IBOutlet weak var txtEndTime: MDCTextField!
    @IBOutlet weak var txtLocation: MDCTextField!
    @IBOutlet weak var colviewLocationBoundaries: UICollectionView!
    @IBOutlet weak var viewMapView: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var contiButton: UIButton?
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var constContinueViewBottom: NSLayoutConstraint!

    
    // MARK: - Properties
    override var screenName: String? { "CreateEvent_Screen_2" }

    var eventModel: EventModel?
    var place: PlaceModel?
    var boundaries = ["300", "400", "500", "600", "700", "800", "900", "1000", "1100", "1200", "1300", "1400", "1500"]
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    var viewDatePicker = DATE_PICKER
    var txtFieldEditing : UITextField?

    
    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        colviewLocationBoundaries.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    
    override func initializeData() {
        super.initializeData()
        
        eventModel = eventModel ?? EventModel()

        if eventModel?.lat == nil || eventModel?.long == nil || (eventModel?.lat! == 0.0 && eventModel?.long! == 0.0 ) {
            eventModel?.lat = place?.latitude
            eventModel?.long = place?.longitude
            eventModel?.locationName = place?.name
            eventModel?.address = place?.formattedAddress ?? place?.address
        }

        if eventModel?.checkInRange == nil || boundaries.contains(eventModel!.checkInRange!) == false {
            eventModel?.checkInRange = boundaries.first
        }

    }
    
    override func setupUI() {
        super.setupUI()
        progressView.addPinkGradient(width: MAIN_SCREEN_WIDTH * 0.5, height: 8.0)
        setupTextFields()
        setupBoundaries()
        updateDateTimeUI(event: eventModel)
        updateLocationUI(event: eventModel)
        checkValidation()
    }

    override func willShowKeyboard(frame: CGRect) {
        super.willShowKeyboard(frame: frame)
        constContinueViewBottom.constant = frame.height - UIDevice.current.heightBottomNotch
    }
    
    override func willHideKeyboard() {
        super.willHideKeyboard()
        constContinueViewBottom.constant = 0
    }


    // MARK: - User Action Handlers
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionContinue(_ sender: Any) {
        if isValidate(isShownAlert: true) == true {
            moveToNext(eventModel)
        }
    }


    // MARK: - Private Methods
    func setupTextFields() {
        viewDatePicker.delegate = self

        // Start Date
        txtStartDate.inputView = viewDatePicker
        txtStartDate.clearButtonMode = .never
        txtStartDate.delegate = self
        
        // End Date
        txtEndDate.inputView = viewDatePicker
        txtEndDate.clearButtonMode = .never
        txtEndDate.delegate = self

        // Start Time
        txtStartTime.inputView = viewDatePicker
        txtStartTime.clearButtonMode = .never
        txtStartTime.delegate = self
        
        // End Time
        txtEndTime.inputView = viewDatePicker
        txtEndTime.clearButtonMode = .never
        txtEndTime.delegate = self
        
        // Location
        txtLocation.delegate = self
        
        // Apply the app scheme to TextFields
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtStartDate))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEndDate))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtStartTime))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEndTime))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtLocation))
        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            item.textInput?.addClearBtn(image: "ic_x_grey")
        }
    }
    
    func setupBoundaries() {
        colviewLocationBoundaries.register(UINib(nibName: RangeButtonCell.className, bundle: nil), forCellWithReuseIdentifier: RangeButtonCell.className)

        colviewLocationBoundaries.delegate = self
        colviewLocationBoundaries.dataSource = self
        colviewLocationBoundaries.reloadData()
        
        viewMapView.layer.borderColor = AppColor.grey_button_border.cgColor
    }
    
    func updateLocationUI(event: EventModel?) {
        guard let event = event ?? eventModel else { return }

        guard let lat = event.lat, let long = event.long, lat != 0.0, long != 0.0 else {
            mapView.isHidden = true
            mapView.clear()
            return
        }
        
        // Map view
        mapView.isHidden = false
        mapView.clear()

        let location = CLLocationCoordinate2DMake(lat,  long)
        let camera = GMSCameraPosition(latitude: location.latitude, longitude: location.longitude, zoom: 15.0)
        mapView.animate(to: camera)

        let regionRadius = CLLocationDistance(eventModel?.checkInRange ?? "")
        mapView.setRadius(radius: regionRadius, location: location)

        // Location
        if let locationName = event.locationName, locationName != "" {
            txtLocation.text = locationName
        } else {
            txtLocation.text = event.address
        }
    }

    func updateDateTimeUI(event: EventModel?) {
        if let date = eventModel?.startDate  {
            txtStartDate.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "MMMM dd, yyyy")
        }
        if let date = eventModel?.endDate {
            txtEndDate.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "MMMM dd, yyyy")
        }
        if let date = eventModel?.startTime  {
            txtStartTime.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "hh:mm a")
        }
        if let date = eventModel?.endTime {
            txtEndTime.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "hh:mm a")
        }
    }

    
    func sycDatePickerWith(textField: UITextField) {
        switch textField {
        case txtStartDate, txtStartTime:
            var date : Double?
            if textField == txtStartDate {
                viewDatePicker.datePickerMode = .date
                date = eventModel?.startDate
            }else {
                viewDatePicker.datePickerMode = .time
                date = eventModel?.startTime
            }
            
            let minDate = Date().addOneMin()
            viewDatePicker.minimumDate = minDate
            if let date = date, date > minDate.timeIntervalSince1970  {
                viewDatePicker.date = Date(timeIntervalSince1970: date)
            }else {
                viewDatePicker.date = minDate
            }
            break
        case txtEndDate, txtEndTime:
            var date : Double?
            var starDate : Double?
            if textField == txtEndDate {
                viewDatePicker.datePickerMode = .date
                date = eventModel?.endDate
                starDate = eventModel?.startDate
            }else {
                viewDatePicker.datePickerMode = .time
                date = eventModel?.endTime
                starDate = eventModel?.startTime
            }

            if let startDate = starDate {
                let minEndDate = Date(timeIntervalSince1970: Double(startDate) + 60 * 30)
                viewDatePicker.minimumDate = minEndDate
                if let endDate = date, endDate > minEndDate.timeIntervalSince1970 {
                    viewDatePicker.date = Date(timeIntervalSince1970: endDate)
                }else {
                    viewDatePicker.date = minEndDate
                }
            }else {
                viewDatePicker.minimumDate = Date().addingTimeInterval(60 * 30)
                viewDatePicker.date = Date().addingTimeInterval(60 * 30)
            }
            break
        default:
            break
        }

    }
    
    func checkValidation() {
        if isValidate() == true {
            contiButton?.backgroundColor = AppColor.purple_join
        }else {
            contiButton?.backgroundColor = AppColor.grey_button
        }
    }

    func isValidate(isShownAlert: Bool = false) -> Bool {
        var result = true
        var errMsg = ""
        
        if eventModel?.startDate == nil || eventModel?.startDate == 0 {
            errMsg = ConstantTexts.eventNeedsStartDate.localizedString
            result = false
        }
        
        if result == true && (eventModel?.startTime == nil || eventModel?.startTime == 0) {
            errMsg = ConstantTexts.eventNeedsStartTime.localizedString
            result = false
        }
        
        if result == true && (eventModel?.endDate == nil || eventModel?.endDate == 0) {
            errMsg = ConstantTexts.eventNeedsEndDate.localizedString
            result = false
        }
        
        if result == true && (eventModel?.endTime == nil || eventModel?.endTime == 0) {
            errMsg = ConstantTexts.eventNeedsEndTime.localizedString
            result = false
        }
        let delta = (eventModel?.endTime ?? 0.0) - (eventModel?.startTime ?? 0.0)
        if result == true && delta < 30 * 60 {
            errMsg = ConstantTexts.endDate30minGreaterAlert.localizedString
            result = false
        }
        
        if result == false, isShownAlert == true {
            POPUP_MANAGER.makeToast(errMsg)
        }
        
        return result
    }

    func moveToNext(_ event: EventModel?) {
        guard let vc = STORY_MANAGER.viewController(CreateEventProgress2VC.className) as? CreateEventProgress2VC else{ return }
        vc.eventModel = event
        self.navigationController?.pushViewController(vc, animated: true)
    }


}

// MARK: - UITextFieldDelegate
extension CreateEventProgress1VC : UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        txtFieldEditing = textField
        var isBegin = true
        switch textField {
        case txtStartDate, txtStartTime, txtEndDate, txtEndTime:
            sycDatePickerWith(textField: textField)
            break
        case txtLocation:
            isBegin = false
            view.endEditing(true)
            APP_MANAGER.pushSearchLocation(self, delegate: self, searchType: .createEvent)
            break
        default:
            break
        }
        
        return isBegin
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = AppColor.grey_text
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CreateEventProgress1VC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return boundaries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RangeButtonCell.className, for: indexPath) as? RangeButtonCell else { return UICollectionViewCell() }
        let range = boundaries[indexPath.row]
        cell.setupUI(range: range, isSelected: eventModel?.checkInRange == range )
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        eventModel?.checkInRange = boundaries[indexPath.row]
        collectionView.reloadData()
        updateLocationUI(event: eventModel)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return CGSize(width: 90, height: 37)
    }
    
}

// MARK: - LocationSearchDelegate
extension CreateEventProgress1VC : LocationSearchDelegate {
    
    func didSelectLocation(place: PlaceModel?) {
        eventModel?.locationName = place?.name
        eventModel?.address = place?.formattedAddress ?? place?.address
        eventModel?.lat = place?.latitude
        eventModel?.long = place?.longitude
        updateLocationUI(event: eventModel)
    }

}

// MARK: - DatePicker delegate

extension CreateEventProgress1VC: DatePickerViewDelegate {
    func datePickerView(_ pickerView: UIView, didDone selectedDate: Date) {
        view.endEditing(true)
        switch txtFieldEditing {
        case txtStartDate: //////////////////// Start Date
            if let timeInterval = eventModel?.startTime  {
                eventModel?.startDate = selectedDate.getDateWith(time: Date(timeIntervalSince1970: timeInterval))?.dateWithoutSeconds()?.timeIntervalSince1970
            }else {
                eventModel?.startDate = selectedDate.dateWithoutSeconds()?.timeIntervalSince1970
            }
            eventModel?.startTime = eventModel?.startDate
            break
        case txtEndDate: //////////////////// End Date
            if let timeInterval = eventModel?.endTime {
                eventModel?.endDate = selectedDate.getDateWith(time: Date(timeIntervalSince1970: timeInterval))?.dateWithoutSeconds()?.timeIntervalSince1970
            }else {
                eventModel?.endDate = selectedDate.dateWithoutSeconds()?.timeIntervalSince1970
            }
            eventModel?.endTime = eventModel?.endDate
            break
        case txtStartTime: //////////////////// Start Time
            if let timeInterval = eventModel?.startDate {
                eventModel?.startTime = Date(timeIntervalSince1970: timeInterval).getDateWith(time: selectedDate)?.dateWithoutSeconds()?.timeIntervalSince1970
            }else {
                eventModel?.startTime = selectedDate.dateWithoutSeconds()?.timeIntervalSince1970
            }
            eventModel?.startDate = eventModel?.startTime
            break
        case txtEndTime: //////////////////// End Time
            if let timeInterval = eventModel?.endDate {
                eventModel?.endTime = Date(timeIntervalSince1970: timeInterval).getDateWith(time: selectedDate)?.dateWithoutSeconds()?.timeIntervalSince1970
            }else {
                eventModel?.endTime = selectedDate.dateWithoutSeconds()?.timeIntervalSince1970
            }
            eventModel?.endDate = eventModel?.endTime
            break
        default:
            break
        }
                
        if let startTime = eventModel?.startTime {
            if eventModel?.endTime == nil || (eventModel!.endTime! - startTime) < 30 * 60 {
                eventModel?.endTime = startTime + 30 * 60
                eventModel?.endDate = eventModel?.endTime
            }
        }
        updateDateTimeUI(event: eventModel)
        checkValidation()
    }
    
    func datePickerView(_ pickerView: UIView, didCancel selectedDate: Date) {
        view.endEditing(true)
    }
}


