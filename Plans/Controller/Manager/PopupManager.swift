//
//  PopupManager.swift
//  Plans
//
//  Created by Star on 1/28/21.
//

import Foundation
import UIKit

let POPUP_MANAGER = PopupManager.shared

class PopupManager {
    
    static let shared = PopupManager()
    
    enum LoadingToastType: String {
        case posting = "Posting"
        case creatingEvent = "Creating event"
        case uploading = "Uploading"
        case downloading = "Downloading"

        fileprivate var message: String {
            return rawValue
        }
    }
    
    var loadingToasts = [[String: Any]]()
    var isLoadingToastOn = true
    
    var isExistLoadingToast : Bool {
        return getLoadingMsg() != nil && isLoadingToastOn
    }
    
    init() {
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(onLoadingToast), name: Notification.Name(rawValue: kLoadingToastOn), object: nil)
        NOTIFICATION_CENTER.addObserver(self, selector: #selector(offLoadingToast), name: Notification.Name(rawValue: kLoadingToastOff), object: nil)
    }
    
    // MARK: - Loading Toast
    @objc func onLoadingToast() {
        isLoadingToastOn = true
        showLoadingToast()
    }
    
    @objc func offLoadingToast() {
        isLoadingToastOn = false
        hideAllToasts()
    }
    
    func showLoadingToast(_ typeToast: LoadingToastType? = nil, message: String? = nil, target: UIViewController? = nil, complete: ((_ didTap: Bool) -> Void)? = nil){
        hideAllToasts(target: target)
        addLoadingToast(typeToast)
        if isLoadingToastOn == true, let loadingMsg = message ?? getLoadingMsg() {
            let topViewController = target ?? APP_MANAGER.topVC
            topViewController?.showLoadingToast(loadingMsg, complete)
        }
    }
    
    func hideLoadingToast(_ typeToast: LoadingToastType? = nil, target: UIViewController? = nil){
        hideAllToasts(target: target)
        removeLoadingToast(typeToast)
        if isLoadingToastOn == true, let message = getLoadingMsg() {
            let topViewController = target ?? APP_MANAGER.topVC
            topViewController?.showLoadingToast(message)
        }
    }

    func hideAllToasts(target: UIViewController? = nil){
        let topViewController = target ?? APP_MANAGER.topVC
        topViewController?.hideAllToasts()
    }

    func addLoadingToast(_ typeToast: LoadingToastType? = nil) {
        if let type = typeToast {
            if let index = loadingToasts.firstIndex(where: {$0["type"] as? LoadingToastType == type }) {
                loadingToasts[index]["count"] = (loadingToasts[index]["count"] as! Int) + 1
            }else {
                loadingToasts.append(["type": type, "count": 1])
            }
        }
    }
    
    func removeLoadingToast(_ typeToast: LoadingToastType? = nil) {
        if let type = typeToast {
            if let index = loadingToasts.firstIndex(where: {$0["type"] as? LoadingToastType == type }) {
                let count = (loadingToasts[index]["count"] as! Int) - 1
                if count < 1 {
                    loadingToasts.remove(at: index)
                }else {
                    loadingToasts[index]["count"] = count
                }
            }
        }
    }

    func getLoadingMsg() -> String? {
        var message : String? = nil
        loadingToasts.forEach { (item) in
            if let type = item["type"] as? LoadingToastType, let count = item["count"] as? Int {
                if message != nil {
                    message! += " \(type.message)"
                }else {
                    message = "\(type.message)"
                }
                if count > 1 {
                    message! += " (\(count))..."
                }else {
                    message! += "..."
                }
            }
        }
        return message
    }

    // MARK: - General Popup Toast
    // Standard bottom black toast
    func makeToast(_ message: String?, title: String? = nil, target: UIViewController? = nil, complete: ((_ didTap: Bool) -> Void)? = nil){
        let topViewController = target ?? APP_MANAGER.topVC
        topViewController?.makeToast(message, title: title, complete: complete)
    }

    // Custom view toast
    func showToast(_ toast: UIView, target: UIViewController? = nil, complete: ((_ didTap: Bool) -> Void)? = nil){
        let topViewController = target ?? APP_MANAGER.topVC
        topViewController?.showToast(toast, complete: complete)
    }
    
    // MARK: - Alerts
    func showAlert(_ message: String?, title:String? = nil, okButtonTitle: String? = nil, target: UIViewController? = nil, actionOk: (() -> Void)? = nil) {
        let topViewController = target ?? APP_MANAGER.topVC
        topViewController?.showAlert(message: message, title: title, titleOk: okButtonTitle, actionOk: actionOk)
    }
    
    func showAlertWithAction(title: String?, message: String?, style: UIAlertController.Style, actionTitles:[String?], action:((UIAlertAction) -> Void)?) {
        
        showAlertWithActionWithCancel(title: title, message: message, style: style, actionTitles: actionTitles, showCancel: false, deleteTitle: nil, action: action)
    }
    
    func handleError(_ error: Error?, target: UIViewController? = nil) {
        let topViewController = target ?? APP_MANAGER.topVC
        topViewController?.handleError(error)
    }
    
    func showAlertWithActionWithCancel(title: String?, message: String?, style: UIAlertController.Style, actionTitles:[String?], showCancel:Bool, deleteTitle: String? ,_ viewC: UIViewController? = nil, action:((UIAlertAction) -> Void)?) {
        
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        if deleteTitle != nil {
            let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive, handler: action)
            deleteAction.setValue(AppColor.teal_main, forKey: "titleTextColor")
            alertController.addAction(deleteAction)
        }
        for (_, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default, handler: action)
            action.setValue(AppColor.teal_main, forKey: "titleTextColor")
            alertController.addAction(action)
        }
        
        if showCancel {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            cancelAction.setValue(AppColor.teal_main, forKey: "titleTextColor")
            alertController.addAction(cancelAction)
        }
        if let viewController = viewC {
            
            viewController.present(alertController, animated: true, completion: nil)
            
        } else {
            let topViewController: UIViewController? = APP_MANAGER.topVC
            topViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func showPlansMenu(items: [String]?, sender: UIViewController? = nil, action:((UIAlertAction) -> Void)? = nil) {
        guard  let items = items, items.count > 0 else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        items.forEach { (item) in
            let action = UIAlertAction(title: item, style: .default, handler: action)
            action.setValue(AppColor.teal_main, forKey: "titleTextColor")
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(AppColor.teal_main, forKey: "titleTextColor")
        alertController.addAction(cancelAction)

        (sender ?? APP_MANAGER.topVC)?.present(alertController, animated: true, completion: nil)
    }


}
