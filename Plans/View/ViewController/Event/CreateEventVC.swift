//
//  CreateEventVC.swift
//  Plans
//
//  Created by Star on 2/8/21.
//

import UIKit
import MaterialComponents
import IQKeyboardManagerSwift

class CreateEventVC: PlansContentBaseVC {

    // MARK: - VC IBOutlets
    @IBOutlet weak var imgviewPhoto: UIImageView!
    @IBOutlet weak var viewVideoPlayer: PlansVideoPlayerView!
    @IBOutlet weak var nextButton: UIButton?
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var txtEventName: MDCTextField!
    @IBOutlet weak var txtEventDetails: MDCMultilineTextField!
    @IBOutlet weak var heightEventDetails: NSLayoutConstraint!
    @IBOutlet weak var constContinueViewBottom: NSLayoutConstraint!
    
    
    // MARK: - Properties
    override var screenName: String? { "CreateEvent_Screen_1" }

    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    var place: PlaceModel?
    var eventModel = EventModel()

    // MARK: - VC Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 100.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 10.0
    }

    override func initializeData() {
        super.initializeData()
        eventModel.userId = USER_MANAGER.userId
    }
    
    override func setupUI() {
        super.setupUI()
        progressBar.addPinkGradient(width: MAIN_SCREEN_WIDTH * 0.25, height: 8.0)
        setupTextFields()
        checkValidation()
        viewVideoPlayer.typeUI = .plansEvent
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
        if eventModel.videoUrl == nil, eventModel.imageData == nil,
            (eventModel.eventsName == nil || eventModel.eventsName! == ""),
            (eventModel.details == nil || eventModel.details! == ""){
            self.navigationController?.popViewController(animated: true)
        }else {
            showPlansAlertYesNo(message: ConstantTexts.discardEvent.localizedString, actionYes: {
                self.navigationController?.popViewController(animated: true)
            }, blurEnabled: true)
        }
        
    }
    
    @IBAction func actionPhotoVideo(_ sender: Any) {
        view.endEditing(true)
        MEDIA_PICKER.showCameraGalleryActionSheet(sender: self,
                                                  delegate: self,
                                                  action: .eventCover)
    }
    
    @IBAction func actionChangedValue(_ sender: UITextField) {
        eventModel.eventsName = sender.text?.trimmingCharacters(in: .whitespaces)
        checkValidation()
    }
    
    @IBAction func actionContinue(_ sender: Any) {
        view.endEditing(true)
        if isValidate(isShownAlert: true) == true {
            moveToNext(eventModel)
        }
    }
    
    @IBAction func actionTapBackground(_ sender: Any) {
        view.endEditing(true)
    }
    
    
    // MARK: - Private Methods
    
    func setupTextFields() {
        // Event Name
        txtEventName.delegate = self
        
        // Event Details TextView
        txtEventDetails.placeholder = "Details"
        txtEventDetails.textView?.delegate = self
        
        // Apply the app scheme to TextFields
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEventName))
        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: txtEventDetails))

        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            item.textInput?.addClearBtn(image: "ic_x_grey")
        }
        
    }
    
    func setupVideoView (_ videoUrl: URL?, previewImage: UIImage?) {
        guard let videoUrl = videoUrl else { return }

        eventModel.videoUrl = videoUrl
        imgviewPhoto.image = previewImage
        eventModel.imageData = nil
        eventModel.mediaType = "video"

        viewVideoPlayer.isHidden = false
        viewVideoPlayer.setVideo(videoUrl.absoluteString)
    }

    func updateEventDetailsTextView(_ text: String?) {
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
    }
    
    func checkValidation() {
        if isValidate() == true {
            self.nextButton?.backgroundColor = AppColor.purple_join
        }else {
            self.nextButton?.backgroundColor = AppColor.grey_button
        }
    }
    
    func isValidate(isShownAlert: Bool = false) -> Bool {
        var result = true
        var errMsg = ""
        
        if result == true, eventModel.videoUrl == nil, eventModel.imageData == nil {
            result = false
            errMsg = ConstantTexts.selectEventImageOrVideoAlert.localizedString
        }
        if result == true && (eventModel.eventsName == nil || eventModel.eventsName! == "") {
            result = false
            errMsg = ConstantTexts.eventNeedsName.localizedString
        }
        
        if result == false, isShownAlert == true {
            POPUP_MANAGER.makeToast(errMsg)
        }
        
        return result
    }

    
    func moveToNext(_ model : EventModel)
    {
        guard let vc = STORY_MANAGER.viewController(CreateEventProgress1VC.className) as? CreateEventProgress1VC else { return }
        vc.eventModel = model
        vc.place = place
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension CreateEventVC : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEventName {
            txtEventDetails.becomeFirstResponder()
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.textColor = AppColor.grey_text
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.textColor = .black
    }
}

// MARK: - UITextViewDelegate
extension CreateEventVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == txtEventDetails.textView {
            eventModel.details = textView.text?.trimmingCharacters(in: .whitespaces)
            updateEventDetailsTextView(txtEventDetails.text)
            checkValidation()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        txtEventDetails.textColor = .black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        txtEventDetails.textColor = AppColor.grey_text
    }

}

// MARK: - MediaPickerDelegate
extension CreateEventVC : MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        viewVideoPlayer.isHidden = true
        imgviewPhoto.image = image
        eventModel.imageData = image
        eventModel.videoUrl = nil
        eventModel.mediaType = "image"
        checkValidation()
    }
    
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenVideo outputFileURL: URL?, previewImage: UIImage?) {
        setupVideoView(outputFileURL, previewImage: previewImage)
        checkValidation()
    }
}
