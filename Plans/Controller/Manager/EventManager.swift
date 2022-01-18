//
//  EventManager.swift
//  Plans
//
//  Created by Top Star on 11/5/21.
//

import EventKitUI
import EventKit
import UIKit

let EVENT_MANAGER = EventManager.shared

class EventManager: NSObject {
    
    static let shared = EventManager()
    
    let eventStore = EKEventStore()
    
    func addEvent(event: EventFeedModel?, senderVC: UIViewController? = nil) {
        guard let event = event,
              let eventName = event.eventName, !eventName.isEmpty,
              let startTime = event.startTime,
              let endTime = event.endTime,
              let parentVC = senderVC ?? APP_MANAGER.topVC
        else { return }
        
        
        eventStore.requestAccess(to: .event) { [weak parentVC, weak self] success, error in
            if success, error == nil {
                APP_CONFIG.defautMainQ.async {
                    guard let store = self?.eventStore else { return }
                    
                    let newEvent = EKEvent(eventStore: store)
                    newEvent.title = eventName
                    newEvent.startDate = Date(timeIntervalSince1970: startTime)
                    newEvent.endDate = Date(timeIntervalSince1970: endTime)
                    newEvent.notes = event.detail
                    newEvent.location = event.address?.removeOwnCountry()
                    
                    self?.presentEventEditVC(newEvent: newEvent, senderVC: parentVC)
                }
            }
        }
    }
    
    func presentEventEditVC(newEvent: EKEvent?, senderVC: UIViewController?) {
        let vc = EKEventEditViewController()
        vc.editViewDelegate = self
        vc.eventStore = eventStore
        vc.event = newEvent
        vc.modalPresentationStyle = .fullScreen
        
        let img = UIImage(named: "im_background_pink")?.resizeImageUsingVImage(size: CGSize(width: MAIN_SCREEN_WIDTH, height: UIDevice.current.heightTopBar))
        let imgvBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: MAIN_SCREEN_WIDTH, height: UIDevice.current.heightTopBar))
        imgvBackground.clipsToBounds = true
        imgvBackground.contentMode = .scaleToFill
        imgvBackground.image = img
        vc.view.addSubview(imgvBackground)
        vc.view.sendSubviewToBack(imgvBackground)

        senderVC?.present(vc, animated: true)
    }
    
}


// MARK: - EKEventViewDelegate

extension EventManager : EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true)
    }
}
