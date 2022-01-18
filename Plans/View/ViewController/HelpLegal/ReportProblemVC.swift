//
//  ReportProblemVC.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import UIKit
import MaterialComponents

class ReportProblemVC: UserBaseVC {
    
    // MARK: - All IBOutlet
    // Top Bar
    @IBOutlet weak var btnSend: UIButton!
    
    // Feedback Text View
    @IBOutlet weak var viewFeedBackText: MDCMultilineTextField!
    @IBOutlet weak var heightTextViewFeedBack: NSLayoutConstraint!

    // Camera Image view
    @IBOutlet weak var containerCameraImage: UIView!
    @IBOutlet weak var viewCameraImage: UIView!
    
    // Screenshot Image View
    @IBOutlet weak var viewScreenImage: UIView!
    @IBOutlet weak var imgviewScreen: UIImageView!
    
    // Add Screenshot Button View
    @IBOutlet weak var viewAddScreenshotBtn: UIView!
    @IBOutlet weak var btnAddScreenshot: UIButton!
    
    
    // MARK: - Properties
    var feedback: String = ""
    var selectedImage: UIImage? = nil
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func setupUI() {
        super.setupUI()
        
        viewFeedBackText.placeholder = "What went wrong?"
        viewFeedBackText.textView?.delegate = self

        allTextFieldControllers.append(MDCTextInputControllerUnderline(textInput: viewFeedBackText))
        allTextFieldControllers.forEach { (item) in
            item.textInput?.textColor = AppColor.grey_text
            item.textInputFont = AppFont.regular.size(17.0)
            item.applyTheme(withScheme: AppScheme.purpleTextField)
            item.floatingPlaceholderNormalColor = .black
            item.floatingPlaceholderScale = 0.9
            item.textInput?.addClearBtn(image: "ic_x_grey")
        }
        
        viewCameraImage.layer.borderColor = AppColor.grey_button_border.cgColor
        btnAddScreenshot.addShadow(3.0, shadowOpacity: 0.3, shadowOffset: CGSize.zero)
        
        updateTextView(feedback)
        updateImage(selectedImage)

    }
    
    
    // MARK: - User Action Handlers
    
    @IBAction func actionBackBtn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func actionSendBtn(_ sender: Any) {
        sendReport()
    }
    
    @IBAction func actionCancelBtn(_ sender: Any) {
        updateImage(nil)
    }
    
    @IBAction func tapAddScreenshot(_ sender: UIButton) {
        MEDIA_PICKER.openGallery(sender: self,
                                 delegate: self,
                                 action: .takeScreen)
    }
    
    @IBAction func actionImageBtn(_ sender: Any) {
        APP_MANAGER.openImageVC(image: selectedImage, sender: self)
    }
    
        
    // MARK: - Private Methods
    func updateImage(_ image: UIImage? = nil) {
        selectedImage = image
        if let image = selectedImage {
            imgviewScreen.image = image
            containerCameraImage.isHidden = true
            viewAddScreenshotBtn.isHidden = true
            viewScreenImage.isHidden = false
        }else {
            imgviewScreen.image = nil
            containerCameraImage.isHidden = false
            viewAddScreenshotBtn.isHidden = false
            viewScreenImage.isHidden = true
        }
    }
    
    func updateTextView(_ text: String?) {
        feedback = text ?? ""
        viewFeedBackText.text = text
        viewFeedBackText.sizeToFit()
        let width = viewFeedBackText.frame.size.width - viewFeedBackText.clearButton.bounds.width
        if var height = text?.height(withConstrainedWidth: width, font: AppFont.regular.size(17)) {
            height += 40
            if height > 60.0 {
                heightTextViewFeedBack.constant = height
            }else {
                heightTextViewFeedBack.constant = 60.0
            }
        }
        
        if let text = text, text.count > 0 {
            btnSend.isHidden = false
        }else {
            btnSend.isHidden = true
        }
    }

    
    // MARK: - Api method for sending the problem
    func sendReport() {
        let text = feedback.trimmingCharacters(in: .whitespaces)
        let dict = ["feedbackMessage": text,
                    "feedbackType": "report",
                    "feedbackSubject": ""] as [String : Any]
        self.showLoader()
        SETTING_SERVICES.sendFeedback(dict, userPhoto: selectedImage ?? nil).done { (response) -> Void in
            self.hideLoader()
            self.navigationController?.popViewController(animated: false)
            POPUP_MANAGER.makeToast("Thank you for your help!\nYour reported problem is submitted.")
        }.catch { (error) in
            self.hideLoader()
            POPUP_MANAGER.handleError(error)
        }
    }


}


// MARK: - UITextViewDelegate
extension ReportProblemVC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == viewFeedBackText.textView {
            let text = textView.text ?? ""
            updateTextView(text.count > 500 ? feedback : text)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        viewFeedBackText.textColor = AppColor.grey_text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        viewFeedBackText.textColor = .black
    }

}

// MARK: - MediaPickerDelegate
extension ReportProblemVC : MediaPickerDelegate {
    func mediaPicker(_ mediaPicker: MediaPicker?, didTakenImage image: UIImage?) {
        updateImage(image)
    }
}



