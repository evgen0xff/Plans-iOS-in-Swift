//
//  EventBaseVC.swift
//  Plans
//
//  Created by Star on 2/8/21.
//

import UIKit

// ViewController related to Plans Event
// EventBaseVC -> PlansContentBaseVC -> PlansBaseVC -> BaseViewController -> UIViewController
// Event actions

class EventBaseVC: PlansContentBaseVC {

    var eventID : String?
    var activeEvent : EventFeedModel?
    
    override func initializeData() {
        super.initializeData()

        eventID = eventID ?? activeEvent?._id
    }
    
}

// MARK: - Event
extension EventBaseVC {
    func getEventDetails (_ eventId: String?, complete: ((_ success: Bool, _ eventModel: EventFeedModel?) -> Void)? = nil){
        guard let eventId = eventId else {
            complete?(false, nil)
            return
        }
        EVENT_SERVICE.getEventDetail(eventId).done { (response) -> Void in
            self.activeEvent = response
            complete?(true, response)
        }.catch { (error) in
            complete?(false, nil)
        }
    }
    
    func removeGuestFromEvent(user: UserModel?,
                              isShowLoader: Bool = true,
                              nameAction: String? = nil,
                              complete: ((_ event: EventFeedModel?) -> ())? = nil) {
        
        guard let eventId = eventID else {
            complete?(nil)
            return
        }
        
        let fullName = user?.fullName ?? user?.name ?? ((user?.firstName != nil && user?.lastName != nil) ? "\(user!.firstName!) \(user!.lastName!)" : "this guest")
        
        let _ = showPlansAlertYesNo(message: "Are you sure you want to \(nameAction ?? "remove") \(fullName)?", actionYes: {
            if isShowLoader == true {
                self.showLoader()
            }

            var dict = ["eventId":  eventId] as [String : Any]
            
            if let userId = user?._id ?? user?.userId {
                dict["userId"] = userId
            }
            
            if let email = user?.email {
                dict["email"] = email
            }
            if let mobile = user?.mobile {
                dict["mobile"] = mobile
            }

            EVENT_SERVICE.removeGuestFromEvent(dict).done { (userResponse) -> Void in
                self.hideLoader()
                NOTIFICATION_CENTER.post(name: Notification.Name(rawValue: kRefreshAll), object: nil)
                complete?(userResponse)
            }.catch { (error) in
                self.hideLoader()
                POPUP_MANAGER.handleError(error)
                complete?(nil)
            }
        }, actionNo: {
            complete?(nil)
        }, blurEnabled: true)
        
    }


}
// MARK: - Option Menu
extension EventBaseVC {
    
}

