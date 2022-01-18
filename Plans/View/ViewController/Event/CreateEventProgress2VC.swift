//
//  CreateEventProgress2VC.swift
//  Plans
//
//  Created by Star on 2/19/21.
//

import Foundation
import UIKit
import MaterialComponents
import CoreData
import Contacts

class CreateEventProgress2VC: PlansContentBaseVC {

    // MARK: - IBOutlets

    @IBOutlet weak var txtvCaption: MDCMultilineTextField!
    @IBOutlet weak var heightCaptionTextView: NSLayoutConstraint!
    @IBOutlet weak var viewInvitation: UIView!
    @IBOutlet weak var viewInviedPeople: UIView!
    @IBOutlet var viewsInvitedFriends: [UIView]!
    @IBOutlet var imgviewsInvitedFriends: [UIImageView]!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var lblSelectedCounts: UILabel!
    @IBOutlet weak var constContinueViewBottom: NSLayoutConstraint!

    
    // MARK: - Properties
    override var screenName: String? { "CreateEvent_Screen_3" }

    var eventModel : EventModel!
    var allTextFieldControllers = [MDCTextInputControllerUnderline]()
    
    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func initializeData() {
        super.initializeData()
        eventModel =  eventModel ?? EventModel()

        if eventModel.invitedUsers == nil {
            eventModel.invitedUsers = [InvitationModel]()
            eventModel.friendsContactNumbers = ""
        }
    }
    
    override func setupUI() {
        super.setupUI()
        progressView.addPinkGradient(width: MAIN_SCREEN_WIDTH * 0.75, height: 8.0)
        viewInvitation.layer.borderColor = AppColor.grey_button_border.cgColor
        setupTextFields()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
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
    
    @IBAction func actionTapBackground(_ sender: Any) {
        view.endEditing(true)
    }
    
    
    @IBAction func actionInvitedFriends(_ sender: Any) {
        view.endEditing(true)
        APP_MANAGER.pushEditInvitationVC(editMode: .create, selectedUsers: getInvitedUsers(), delegate: self, sender: self)
    }
    
    @IBAction func actionContinue(_ sender: Any) {
        moveToNext(eventModel)
    }
    
    // MARK: - Private Methods
    func setupTextFields() {
        
        // Caption
        txtvCaption.placeholder = "Caption"
        txtvCaption.textView?.delegate = self

        // Apply the app scheme to TextFields
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
    
    func updateUI() {
        updateCaptionTextView(eventModel?.caption)
        updateInvitedFriends(list: eventModel.invitedUsers)
    }
    
    
    func updateInvitedFriends(list: [InvitationModel]?) {
        viewsInvitedFriends.forEach { (view) in
            view.isHidden = true
        }
        
        if let invitation = list, invitation.count > 0 {
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
        
        let counts = eventModel?.getInvitedUserCounts() ?? (0, 0, 0)
        if let attrText = getAttriString(friends: counts.0, contacts: counts.1, emails: counts.2, isSelected: true) {
            lblSelectedCounts.attributedText = attrText
            lblSelectedCounts.isHidden = false
            viewInviedPeople.isHidden = false
        }else {
            lblSelectedCounts.isHidden = true
            viewInviedPeople.isHidden = true
        }
    }
    
    func updateCaptionTextView(_ text: String?) {
        txtvCaption.text = text
        txtvCaption.sizeToFit()
        let width = txtvCaption.frame.size.width - txtvCaption.clearButton.bounds.width
        if var height = text?.height(withConstrainedWidth: width, font: AppFont.regular.size(17)) {
            height += 40
            if height > 60.0 {
                heightCaptionTextView.constant = height
            }else {
                heightCaptionTextView.constant = 60.0
            }
        }
        
        eventModel.caption = text?.trimmingCharacters(in: .whitespaces)
    }

    
    func moveToNext(_ model : EventModel)
    {
        guard let vc = STORY_MANAGER.viewController(CreateEventProgress3VC.className) as? CreateEventProgress3VC else { return }
        vc.eventModel = model
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func getInvitedUsers() -> [UserModel] {
        var result = [UserModel]()
        eventModel?.invitedUsers?.forEach({ result.append( UserModel(invitationModel: $0) ) })
        eventModel?.invitedPeople?.forEach({ result.append($0) })

        return result
    }

}

// MARK: - UITextFieldDelegate
extension CreateEventProgress2VC : UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == txtvCaption.textView {
            updateCaptionTextView(textView.text)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        txtvCaption.textColor = AppColor.grey_text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        txtvCaption.textColor = .black
    }

}

// MARK: - EditInvitationVCDelegate
extension CreateEventProgress2VC : EditInvitationVCDelegate {
    
    func didSelectedUsers(users: [UserModel]?) {
        eventModel?.invitedUsers = users?.filter({$0.inviteType == .friend}).map({InvitationModel(user: $0)})
        eventModel?.invitedPeople = users?.filter({$0.inviteType == .mobile || $0.inviteType == .email })

        var arrPeople = [String]()
        eventModel.invitedUsers?.forEach({ (model) in
            if let mobNumVar = model.mobile {
                arrPeople.append(mobNumVar)
            }
        })
        
        eventModel.friendsContactNumbers = arrPeople.joined(separator: ",")
        updateUI()
    }
}



