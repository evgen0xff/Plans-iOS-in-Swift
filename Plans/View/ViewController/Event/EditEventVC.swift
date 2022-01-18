//
//  EditEventVC.swift
//  Plans
//
//  Created by Star on 7/2/20.
//  Copyright © 2021 Plans Collective. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents
import Photos
import MapKit
import GoogleMaps


class EditEventVC: EventBaseVC {

    // MARK: - IBOutlets
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgviewPhoto: UIImageView!
    @IBOutlet weak var viewVideoPlayer: PlansVideoPlayerView!
    @IBOutlet weak var txtEventName : MDCTextField!
    @IBOutlet weak var txtEventDetails: MDCMultilineTextField!
    @IBOutlet weak var heightEventDetails: NSLayoutConstraint!
    @IBOutlet weak var txtStartDate: MDCTextField!
    @IBOutlet weak var txtEndDate: MDCTextField!
    @IBOutlet weak var txtStartTime: MDCTextField!
    @IBOutlet weak var txtEndTime: MDCTextField!
    @IBOutlet weak var txtLocation: MDCTextField!
    @IBOutlet weak var txtvCaption: MDCMultilineTextField!
    @IBOutlet weak var heightCaptionTxtv: NSLayoutConstraint!
    
    @IBOutlet weak var colviewLocationBoundaries: UICollectionView!
    @IBOutlet weak var viewMap: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var viewInvitePeople: UIView!
    @IBOutlet var viewsInvitedFriends: [UIView]!
    @IBOutlet var imgviewsInvitedFriends: [UIImageView]!
    @IBOutlet weak var lblSelectedCounts: UILabel!
    @IBOutlet weak var lblRemovedCounts: UILabel!
    
    @IBOutlet weak var btnPublicEvent: UIButton!
    @IBOutlet weak var btnPrivateEvent: UIButton!
    @IBOutlet weak var btnGroupChatOn: UIButton!
    @IBOutlet weak var btnGroupChatOff: UIButton!
    @IBOutlet weak var btnUpdateEvent: UIButton!
    
    var viewDatePicker = DATE_PICKER
    
    // MARK: - Properties
    var isDuplicate = false
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    var txtFieldEditing : UITextField?
    var boundaries = ["300", "400", "500", "600", "700", "800", "900", "1000", "1100", "1200", "1300", "1400", "1500"]
    var imageSelected : UIImage?
    var uploadVideoUrl : URL?

    
    
    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        colviewLocationBoundaries.reloadData()
    }

    
    // MARK: - User Action Handlers
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionPhotoVideo(_ sender: Any) {
        MEDIA_PICKER.showCameraGalleryActionSheet(sender: self,
                                                  delegate: self,
                                                  action: .eventCover)
    }
    
    @IBAction func actionInvitedFriends(_ sender: Any) {
        var editMode = EditInvitationVC.EditMode.edit
        if isDuplicate == true {
            editMode = .create
        }
        APP_MANAGER.pushEditInvitationVC(editMode: editMode, selectedUsers: activeEvent?.getInvitedPeople(), delegate: self, sender: self)
    }
    
    @IBAction func actionUpdateEvent(_ sender: Any) {
        guard validateEventData(isAlert: true) == true else { return }
        if isDuplicate == true {
            hitCreateEventApi()
        }else {
            hitUpdateEventApi()
        }
    }
    
    @IBAction func actionChangedPublicPrivateEvent(_ sender: UIButton) {
        if sender == btnPublicEvent {
            activeEvent?.isPublic = true
        }else if sender == btnPrivateEvent {
            activeEvent?.isPublic = false
        }
        updateUI()
    }
    
    @IBAction func actionChangedGroupChatOnOff(_ sender: UIButton) {
        if sender == btnGroupChatOn {
            activeEvent?.isGroupChatOn = 1
        }else if sender == btnGroupChatOff {
            activeEvent?.isGroupChatOn = 0
        }
        updateUI()
    }
    
    @IBAction func actionChangedEventName(_ sender: Any) {
        guard let event = activeEvent else { return }
        event.eventName = txtEventName.text?.trimmingCharacters(in: .whitespaces)
        updateDoneBtn()
    }
    
    // MARK: - Private Methods
    override func initializeData() {
        super.initializeData()
        activeEvent?.invitationDetails = activeEvent?.invitationDetails?.filter{ $0.isFriend == true }
        if activeEvent?.checkInRange == nil || boundaries.contains(activeEvent!.checkInRange!) == false {
            activeEvent?.checkInRange = boundaries.first
        }
    }
    
    override func setupUI() {
        super.setupUI()
        setupPhotoVideoView(activeEvent)
        setupTextFields()
        setupBoundaries()
        if isDuplicate == true {
            lblTitle.text = "Duplicate Event"
            btnUpdateEvent.setTitle("Duplicate Event", for: .normal)
        }else {
            lblTitle.text = "Edit Event"
            btnUpdateEvent.setTitle("Update Event", for: .normal)
        }
        updateUI(activeEvent)
    }
    
    func setupTextFields() {
        // Event Name
        txtEventName.delegate = self
        
        // Event Details TextView
        txtEventDetails.placeholder = "Details"
        txtEventDetails.textView?.delegate = self
        
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
        
        viewDatePicker.delegate = self
        
        // Location
        txtLocation.delegate = self
        
        // Caption
        txtvCaption.placeholder = "Caption"
        txtvCaption.textView?.delegate = self


        // Apply the app scheme to TextFields
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEventName))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEventDetails))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtStartDate))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEndDate))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtStartTime))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEndTime))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtLocation))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtvCaption))
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
        
        viewMap.layer.borderColor = AppColor.grey_button_border.cgColor
    }
    
    func setupPhotoVideoView(_ event: EventFeedModel? = nil) {

        guard let event = event ?? activeEvent else { return }

        viewVideoPlayer.typeUI = .plansEvent

        if let mediaType = event.mediaType {
            if mediaType == "video" {
                imgviewPhoto.setEventImage(event.thumbnail)
                setupVideoView(URL(string: event.imageOrVideo), previewImage: imgviewPhoto.image, thumbImageUrl: event.thumbnail)
            } else {
                uploadVideoUrl = nil
                viewVideoPlayer.isHidden = true
                imgviewPhoto.setEventImage(event.imageOrVideo)
            }
        }
    }
    
    func setupVideoView (_ videoUrl: URL?, previewImage: UIImage?, thumbImageUrl: String? = nil) {
        guard let videoUrl = videoUrl else { return }

        uploadVideoUrl = videoUrl
        imageSelected = nil
        imgviewPhoto?.image = previewImage


        viewVideoPlayer.isHidden = false
        viewVideoPlayer.setVideo(videoUrl.absoluteString, thumbImageUrl)
    }


    
    func updateUI(_ event: EventFeedModel? = nil) {
        guard let event = event ?? activeEvent else { return }
        
        // Event Name
        txtEventName.text = event.eventName
        
        // Event Details
        updateEventDetailsTextView(event.detail)
        
        // Start/End Date/Time
        updateDateTimeUI(event)
        
        // Location
        updateLocationUI(event: event)
        
        // Caption
        updateCaptionTextView(event.caption)
        
        // Invited Firends
        updateInvitedFriends(event: event)
        
        // Options
        if let isPublic = event.isPublic {
            btnPublicEvent.isSelected = isPublic
            btnPrivateEvent.isSelected = !isPublic
        }
        if let isGroupChat = event.isGroupChatOn == 1 ? true : false {
            btnGroupChatOn.isSelected = isGroupChat
            btnGroupChatOff.isSelected = !isGroupChat
        }
        
        // Done Button
        updateDoneBtn()
    }
    
    func updateDateTimeUI(_ event: EventFeedModel? = nil) {
        guard let event = event ?? activeEvent else { return }

        // Start Date
        if let date = event.startDate {
            txtStartDate.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "MMMM dd, yyyy")
        }

        // End Date
        if let date = event.endDate {
            txtEndDate.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "MMMM dd, yyyy")
        }

        // Start Time
        if let date = event.startTime {
            txtStartTime.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "hh:mm a")
        }

        // End Time
        if let date = event.endTime {
            txtEndTime.text = Date(timeIntervalSince1970: date).dateStringWith(strFormat: "hh:mm a")
        }
    }
    
    func updateLocationUI(event: EventFeedModel?) {
        guard let event = event ?? activeEvent else { return }

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

        let regionRadius = CLLocationDistance(event.checkInRange ?? "")
        mapView.setRadius(radius: regionRadius, location: location)

        // Location
        if let locationName = event.locationName, locationName != "" {
            txtLocation.text = locationName
        } else {
            txtLocation.text = event.address
        }
    }

    
    func updateInvitedFriends(event: EventFeedModel?, eventNew: EventFeedModel? = nil) {
        viewInvitePeople.isHidden = !isDuplicate
        
        viewsInvitedFriends.forEach { (view) in
            view.isHidden = true
        }
        
        // Invited People
        let removedCounts = event?.getRemovedUserCounts(friensNew: eventNew?.invitationDetails, peopleNew: eventNew?.invitedPeople) ?? (0, 0, 0)
        if let new = eventNew?.invitationDetails { event?.invitationDetails = new }
        if let new = eventNew?.invitedPeople { event?.invitedPeople = new }
        let selectedCounts = event?.getInvitedUserCounts() ?? (0, 0, 0)
        
        lblSelectedCounts.text = ""
        lblRemovedCounts.text = ""
        lblSelectedCounts.isHidden = true
        lblRemovedCounts.isHidden = true

        if let attriText = getAttriString(friends: selectedCounts.0, contacts: selectedCounts.1, emails: selectedCounts.2, isSelected: true) {
            lblSelectedCounts.attributedText = attriText
            lblSelectedCounts.isHidden = false
        }

        // Invited Friends
        if let invitation = event?.invitationDetails, invitation.count > 0 {
            for i in 0...invitation.count-1 {
                viewsInvitedFriends.first{ $0.tag == i }?.isHidden = false
                let profile = imgviewsInvitedFriends.first{ $0.tag == i }
                if i < 3 {
                    if let imageData = invitation[i].imageData {
                        profile?.image = UIImage(data: imageData)
                    }else {
                        profile?.setUserImage(invitation[i].profileImage)
                    }
                }
            }
        }

    }
    
    func updateEventDetailsTextView(_ text: String?) {
        txtEventDetails.text = text
        txtEventDetails.sizeToFit()
        let width = txtEventDetails.frame.size.width - txtEventDetails.clearButton.bounds.width
        if var height = text?.height(withConstrainedWidth: width, font: AppFont.regular.size(17)) {
            height += 40
            if height > 60.0 {
                heightEventDetails.constant = height
            }else {
                heightEventDetails.constant = 60.0
            }
        }
        
        guard let event = activeEvent else { return }
        event.detail = text?.trimmingCharacters(in: .whitespaces)
    }
    
    func updateCaptionTextView(_ text: String?) {
        txtvCaption.text = text
        txtvCaption.sizeToFit()
        let width = txtvCaption.frame.size.width - txtvCaption.clearButton.bounds.width
        if var height = text?.height(withConstrainedWidth: width, font: AppFont.regular.size(17)) {
            height += 40
            if height > 60.0 {
                heightCaptionTxtv.constant = height
            }else {
                heightCaptionTxtv.constant = 60.0
            }
        }
        
        guard let event = activeEvent else { return }
        event.caption = text?.trimmingCharacters(in: .whitespaces)
    }
    
    func updateDoneBtn() {
        let isVaild = validateEventData(isAlert: false)
        btnUpdateEvent.backgroundColor = isVaild == true ? AppColor.purple_join : AppColor.grey_button
    }
    
    func sycDatePickerWith(textField: UITextField) {
        switch textField {
        case txtStartDate, txtStartTime:
            var date : Double?
            if textField == txtStartDate {
                viewDatePicker.datePickerMode = .date
                date = activeEvent?.startDate
            }else {
                viewDatePicker.datePickerMode = .time
                date = activeEvent?.startTime
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
                date = activeEvent?.endDate
                starDate = activeEvent?.startDate
            }else {
                viewDatePicker.datePickerMode = .time
                date = activeEvent?.endTime
                starDate = activeEvent?.startTime
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
    
    func updateStartEndDateTime(date : Date, txtField: UITextField? = nil) {
        let txtField = txtField ?? txtFieldEditing

        switch txtField {
        case txtStartDate:
            if let startTime = activeEvent?.startTime {
                activeEvent?.startDate = date.getDateWith(time: Date(timeIntervalSince1970: startTime))?.dateWithoutSeconds()?.timeIntervalSince1970
                activeEvent?.startTime = activeEvent?.startDate
            }
            break
        case txtStartTime:
            if let startDate = activeEvent?.startDate {
                activeEvent?.startTime = Date(timeIntervalSince1970: startDate).getDateWith(time: date)?.dateWithoutSeconds()?.timeIntervalSince1970
                activeEvent?.startDate = activeEvent?.startTime
            }
            break
        case txtEndDate:
            if let endTime = activeEvent?.endTime {
                activeEvent?.endDate = date.getDateWith(time: Date(timeIntervalSince1970: endTime))?.dateWithoutSeconds()?.timeIntervalSince1970
                activeEvent?.endTime = activeEvent?.endDate
            }
            break
        case txtEndTime:
            if let endDate = activeEvent?.endDate {
                activeEvent?.endTime = Date(timeIntervalSince1970: endDate).getDateWith(time: date)?.dateWithoutSeconds()?.timeIntervalSince1970
                activeEvent?.endDate = activeEvent?.endTime
            }
            break
        default:
            break
        }
        
        if let start = activeEvent?.startTime {
            if activeEvent?.endTime == nil || ((activeEvent!.endTime! - start) < 30 * 60) {
                activeEvent?.endTime = start + 30 * 60
                activeEvent?.endDate = activeEvent?.endTime
            }
        }
        
        updateUI()
    }
    
    func validateEventData (isAlert: Bool = false) -> Bool {
        guard let event = activeEvent else {return false}
        var result = true
        var msg : String?
        if result == true && (event.eventName == nil || event.eventName == "") {
            result = false
            msg = ConstantTexts.eventNeedsName.localizedString
        }else {
            // Start Time
            if (isDuplicate || activeEvent?.eventStatus == .ended || activeEvent?.eventStatus == .cancelled || activeEvent?.eventStatus == .expired) {
                let now = Date().timeIntervalSince1970
                let start = activeEvent?.startTime ?? 0
                let end = activeEvent?.endTime ?? 0
                if  start < now, end < now {
                    result = false
                    msg = ConstantTexts.eventCannotInPast.localizedString
                }else if start < now {
                    result = false
                    msg = ConstantTexts.startDateGreaterToday.localizedString
                }
            }

        }

        if result == false, isAlert == true{
            POPUP_MANAGER.makeToast(msg)
        }
        return result
    }
    
    // MARK: - Backend APIs
    func hitUpdateEventApi() {
        guard let event = getEventModelWith(activeEvent) else { return }

        showLoader()
        EVENT_SERVICE.hitUpdateEventApi(event.toJSON(), image: imageSelected, videoUrl: uploadVideoUrl).done { (userResponse) -> Void in
            self.hideLoader()
            APP_MANAGER.gotoTabItemVC(tabType: .home)
            POPUP_MANAGER.makeToast(ConstantTexts.updatedEvent.localizedString)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
    func hitCreateEventApi() {
        guard let event = getEventModelWith(activeEvent) else { return }
        
        if event.mediaType == "image" {
            imageSelected = imgviewPhoto.image
        }
        
        showLoader()
        EVENT_SERVICE.hitCreateEventApi(event.toJSON(), image: imageSelected, videoUrl: uploadVideoUrl).done { (userResponse) -> Void in
            self.hideLoader()
            ANALYTICS_MANAGER.logEvent(.create_event)
            APP_MANAGER.gotoTabItemVC(tabType: .home)
            POPUP_MANAGER.makeToast(ConstantTexts.duplicatedEvent.localizedString)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
        }
    }
    
    func getEventModelWith(_ eventFeed: EventFeedModel? = nil) -> EventModel? {
        guard let eventFeed = eventFeed ?? activeEvent else { return nil }
        
        let event = EventModel()
        event.eventsName = eventFeed.eventName
        event.details = eventFeed.detail
        event.userId = USER_MANAGER.userId
        event.address = eventFeed.address
        event.locationName = eventFeed.locationName
        event.long = eventFeed.long ?? 0
        event.lat = eventFeed.lat ?? 0
        event.caption = eventFeed.caption
        event.eventID = eventFeed._id
        event.startDate = eventFeed.startDate ?? 0
        event.startTime = eventFeed.startTime ?? 0
        event.endDate = eventFeed.endDate ?? 0
        event.endTime = eventFeed.endTime ?? 0
        event.checkInRange = eventFeed.checkInRange
        event.isPublic = eventFeed.isPublic
        event.isGroupChatOn = eventFeed.isGroupChatOn == 1 ? true : false
        event.invitesOnly = eventFeed.invitesOnly
        event.invitedPeople = eventFeed.invitedPeople
        event.isCancel = "0"

        var arrPeople = [String]()
        eventFeed.invitationDetails?.forEach({ (model) in
            if let mobNumVar = model.mobile {
                arrPeople.append(mobNumVar)
            }
        })
        event.friendsContactNumbers = arrPeople.joined(separator: ",")
        
        if uploadVideoUrl != nil {
            event.mediaType = "video"
        } else {
            event.mediaType = "image"
        }
        
        return event
    }
}

// MARK: - UITextViewDelegate
extension EditEventVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == txtEventDetails.textView {
            updateEventDetailsTextView(txtEventDetails.text)
        }else if textView == txtvCaption.textView {
            updateCaptionTextView(txtvCaption.text)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == txtEventDetails.textView {
            txtEventDetails.textColor = .black
        }else if textView == txtvCaption.textView {
            txtvCaption.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == txtEventDetails.textView {
            txtEventDetails.textColor = AppColor.grey_text
        }else if textView == txtvCaption.textView {
            txtvCaption.textColor = AppColor.grey_text
        }
    }
}

// MARK: - UITextFieldDelegate
extension EditEventVC : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = AppColor.grey_text
    }
    
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
            APP_MANAGER.pushSearchLocation(self, delegate: self, searchType: .editEvent)
            break
        default:
            break
        }
        
        return isBegin
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

// MARK: - LocationSearchDelegate
extension EditEventVC : LocationSearchDelegate {
    func didSelectLocation(place: PlaceModel?) {
        activeEvent?.locationName = place?.name
        activeEvent?.address = place?.address
        activeEvent?.lat = place?.latitude
        activeEvent?.long = place?.longitude
        updateUI(activeEvent)
    }
}

// MARK: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension EditEventVC : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return boundaries.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RangeButtonCell.className, for: indexPath) as? RangeButtonCell else { return UICollectionViewCell() }
        
        let range = boundaries[indexPath.row]
        cell.setupUI(range: range, isSelected: activeEvent?.checkInRange == range )
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        activeEvent?.checkInRange = boundaries[indexPath.row]
        collectionView.reloadData()
        updateLocationUI(event: activeEvent)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return CGSize(width: 90, height: 37)
    }
    
}

// MARK: - EditInvitationVCDelegate
extension EditEventVC : EditInvitationVCDelegate {
    func didSelectedUsers(users: [UserModel]?) {
        let eventNew = EventFeedModel()
        eventNew.invitationDetails = users?.filter({$0.inviteType == .friend}).map({InvitationModel(user: $0)})
        eventNew.invitedPeople = users?.filter({$0.inviteType == .mobile || $0.inviteType == .email })

        updateInvitedFriends(event: activeEvent, eventNew: eventNew)
    }
}

// MARK: - MediaPickerDelegate
extension EditEventVC : MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        viewVideoPlayer.isHidden = true
        imgviewPhoto?.image = image
        imageSelected = image
        uploadVideoUrl = nil
    }
    
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenVideo outputFileURL: URL?, previewImage: UIImage?) {
        setupVideoView(outputFileURL, previewImage: previewImage)
    }
}

extension EditEventVC: DatePickerViewDelegate {
    func datePickerView(_ pickerView: UIView, didDone selectedDate: Date) {
        view.endEditing(true)
        updateStartEndDateTime(date: viewDatePicker.date)

    }
    
    func datePickerView(_ pickerView: UIView, didCancel selectedDate: Date) {
        view.endEditing(true)
    }

}
