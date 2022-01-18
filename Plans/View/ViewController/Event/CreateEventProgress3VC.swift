//
//  CreateEventProgress3VC.swift
//  Plans
//
//  Created by Star on 2/19/21.
//

import UIKit

class CreateEventProgress3VC: PlansContentBaseVC {
    
    // MARK: - IBOutlets
    @IBOutlet weak var btnPublicEvent: UIButton!
    @IBOutlet weak var btnPrivateEvent: UIButton!
    @IBOutlet weak var btnGroupChatOn: UIButton!
    @IBOutlet weak var btnGroupChatOff: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    // MARK: - Properties
    override var screenName: String? { "CreateEvent_Screen_4" }

    var eventModel : EventModel!

    // MARK: - ViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func initializeData() {
        super.initializeData()

        eventModel = eventModel ?? EventModel()
        eventModel.isPublic = eventModel.isPublic ?? false
        eventModel.invitesOnly = eventModel.invitesOnly ?? true
        eventModel.isGroupChatOn = eventModel.isGroupChatOn ?? true
    }
    
    override func setupUI() {
        super.setupUI()
        progressView.addPinkGradient(width: MAIN_SCREEN_WIDTH, height: 8.0)
        updateUI(eventModel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }


    // MARK: - User Action Handlers
    @IBAction func actionBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func actionChangedPublicPrivateEvent(_ sender: UIButton) {
        if sender == btnPublicEvent {
            eventModel?.isPublic = true
        }else if sender == btnPrivateEvent {
            eventModel?.isPublic = false
        }
        
        eventModel?.invitesOnly = !(eventModel?.isPublic ?? false)
        updateUI()
    }
    
    @IBAction func actionChangedGroupChatOnOff(_ sender: UIButton) {
        if sender == btnGroupChatOn {
            eventModel?.isGroupChatOn = true
        }else if sender == btnGroupChatOff {
            eventModel?.isGroupChatOn = false
        }
        updateUI()
    }
    
    @IBAction func actionCreateEvent(_ sender: Any) {
         hitCreateEventApi(event: eventModel)
    }
    
    // MARK: - Private Methods
    func updateUI(_ event: EventModel? = nil) {
        guard let event = event ?? eventModel else { return }
        
        // Options
        if let isPublic = event.isPublic {
            btnPublicEvent.isSelected = isPublic
            btnPrivateEvent.isSelected = !isPublic
        }
        if let isGroupChat = event.isGroupChatOn {
            btnGroupChatOn.isSelected = isGroupChat
            btnGroupChatOff.isSelected = !isGroupChat
        }
    }
    
    // MARK: - Backend APIs

    func hitCreateEventApi(event: EventModel?) {
        guard let event = event else { return }
        
        POPUP_MANAGER.showLoadingToast(.creatingEvent)
        EVENT_SERVICE.hitCreateEventApi(event.toJSON(), image: event.imageData, videoUrl: event.videoUrl).done { (userResponse) -> Void in
            ANALYTICS_MANAGER.logEvent(.create_event)
            POPUP_MANAGER.hideLoadingToast(.creatingEvent)
            POPUP_MANAGER.makeToast(ConstantTexts.createdEvent.localizedString)
            NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
            }.catch { (error) in
                POPUP_MANAGER.hideLoadingToast(.creatingEvent)
                POPUP_MANAGER.handleError(error)
        }
        
        APP_MANAGER.gotoTabItemVC(tabType: .home)
    }
}

