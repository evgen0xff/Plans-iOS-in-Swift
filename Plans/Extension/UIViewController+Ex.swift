//
//  UIViewController+Plans.swift
//  Plans
//
//  Created by Star on 2/4/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import PopupDialog
import AVKit
import ActiveLabel
import VIMediaCache
import BMPlayer

extension UIViewController {
    
    func makeToast(_ message: String?, title: String? = nil, isAppToast: Bool = true, complete: ((_ didTap: Bool) -> Void)? = nil) {
        if (POPUP_MANAGER.isExistLoadingToast) {
            ToastManager.shared.setPlansStyle(position: .bottomOver)
        }else {
            ToastManager.shared.setPlansStyle(position: .bottom)
        }
        
        if isAppToast == true {
            APPLICATION.keyWindow?.makeToast(message, title: title, completion: complete)
        }else {
            view.makeToast(message, title: title, completion: complete)
        }
    }

    func showToast(_ toast: UIView, duration: TimeInterval = ToastManager.shared.duration, position: ToastPosition = ToastManager.shared.position, isAppToast: Bool = true, complete: ((_ didTap: Bool) -> Void)? = nil) {
        ToastManager.shared.setPlansStyle(position: position)
        if isAppToast == true {
            APPLICATION.keyWindow?.showToast(toast, duration: duration, position: position, completion: complete)
        }else {
            view.showToast(toast, duration: duration, position: position, completion: complete)
        }
    }
    
    func showLoadingToast(_ message: String? = nil, isAppToast: Bool = true, _ complete: ((_ didTap: Bool) -> Void)? = nil) {
        let plansIndicator = PlansIndicatorView.loadForToast(message)
        plansIndicator.startAnimating()
        showToast(plansIndicator, duration: 300.0, position: .bottom, isAppToast: isAppToast, complete: complete)
    }
    
    func hideAllToasts() {
        view.hideAllToasts()
        APPLICATION.keyWindow?.hideAllToasts()
    }
    
    @objc func showAlert(message : String?, title : String? = nil, titleOk: String? = nil, actionOk: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: title ?? APP_CONFIG.APP_NAME, message: message, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: titleOk ?? "OK", style: UIAlertAction.Style.default) { (action) in
            actionOk?()
        }
        alert.addAction(actionOk)
        
        self.present(alert, animated: true, completion: nil)
    }

    @objc func showAlertYesNo(message : String,
                        title : String? = nil,
                        titleYes: String? = nil,
                        titleNo: String? = nil,
                        actionYes: (() -> Void)? = nil,
                        actionNo: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: title ?? "Plans", message: message, preferredStyle: .alert)
        let actionNo = UIAlertAction(title: titleNo ?? "No", style: UIAlertAction.Style.default) { (action) in
            actionNo?()
        }
        let actionYes = UIAlertAction(title: titleYes ?? "Yes", style: UIAlertAction.Style.default) { (action) in
            actionYes?()
        }
        
        alert.addAction(actionNo)
        alert.addAction(actionYes)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func showPlansAlertYesNo(message : String,
                              attributedMsg : String? = nil,
                              title : String? = nil,
                              titleYes: String? = nil,
                              colorYesBtn: UIColor? = nil,
                              titleNo: String? = nil,
                              actionYes: (() -> Void)? = nil,
                              actionNo: (() -> Void)? = nil,
                              complete: (() -> Void)? = nil,
                              blurEnabled: Bool = true,
                              image: UIImage? = nil,
                              urlImage: String? = nil,
                              fontMsg: UIFont? = nil ) -> UIViewController? {
        
        let alert = DMAlertPopUp(nibName: "DMAlertPopUp", bundle: nil)
        
        alert.titleMsg = title
        alert.message = message
        alert.fontMsg = fontMsg
        alert.attributedMsg = attributedMsg
        alert.titleBtnNo = titleNo
        alert.titleBtnYes = titleYes
        alert.colorYesBtn = colorYesBtn
        alert.actionNo = actionNo
        alert.actionYes = actionYes
        alert.actionComplete = complete
        alert.image = image
        alert.urlImage = urlImage
        
        // Create the dialog
        let popup = PopupDialog(viewController: alert,
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                tapGestureDismissal: false,
                                panGestureDismissal: false)

        // Customize overlay appearance
        let ov = PopupDialogOverlayView.appearance()
        ov.blurEnabled     = false
        ov.blurRadius      = 30
        ov.liveBlurEnabled = false
        
        // Custmize Container Appearance
        let container = PopupDialogContainerView.appearance()
        container.cornerRadius = 16.0
        

        if blurEnabled == false {
            ov.opacity         = 0.0
            ov.color           = .clear
        }else {
            ov.opacity         = 0.4
            ov.color           = .black
        }

        
        // Get popup dialog view
        present(popup, animated: true, completion: nil)
        return popup
    }
    
    @objc func showPlansAlert(message : String, title : String? = nil, actionOk: (() -> Void)? = {}) {
        let alert = DMAlertPopUp(nibName: "DMAlertPopUp", bundle: nil)

        alert.titleMsg = title
        alert.message = message
        alert.actionOk = actionOk
        
        // Create the dialog
        let popup = PopupDialog(viewController: alert,
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                tapGestureDismissal: false,
                                panGestureDismissal: false)
        
        present(popup, animated: true, completion: nil)
    }

    func openUrl(urlString: String?) {
        guard let url = urlString, let settingsUrl = URL(string: url) else {
            return
        }
        if APPLICATION.canOpenURL(settingsUrl) {
            APPLICATION.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    func handleError(_ error: Error?) {
        guard let nsError = error as NSError? else { return }
        guard var message = nsError.userInfo["errorMessage"] as? String else{ return }
        
        var isPushToLogin = false
        var isToast = true
        
        switch message {
        case ConstantTexts.loginAgain.rawValue, ConstantTexts.unauthorised.rawValue:
            message = ConstantTexts.sessionExpired.localizedString
            isPushToLogin = true
        case ConstantTexts.lostInternet.rawValue, ConstantTexts.requestTimedOut.rawValue:
            isToast = false
        default:
            isPushToLogin = false
            isToast = true
        }

        if message.lowercased().contains(ConstantTexts.lostInternet.rawValue.lowercased()) == true {
            message = ConstantTexts.lostInternet.rawValue
        }

        if isToast == true {
            makeToast(message) { didTap in
                if isPushToLogin == true {
                    APP_MANAGER.gotoLandingVC()
                }
            }
        }
    }
    
    func openMap(_ coordinate: CLLocationCoordinate2D?, name: String? = nil) {
        guard let coordinate = coordinate else { return }
        
        let regionDistance:CLLocationDistance = 10000
        let regionSpan = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: options)
    }
    
    func openMapForDirections(sourcMapItem: MKMapItem?, sourceName: String? = nil,
                              destMapItem: MKMapItem?, destName: String? = nil) {
        
        guard let source = sourcMapItem, let dest = destMapItem else { return }
        
        if source.name == nil {
            source.name = sourceName ?? "Source"
        }
        if dest.name == nil {
            dest.name = destName ?? "Destination"
        }
        
        MKMapItem.openMaps(with: [source, dest], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    
    func callPhoneNumber(_ phoneNumber: String?) {
        guard let number = phoneNumber?.getDigitalPhoneNum(isRemoveCountryCode: false) else { return }
        
        if let url = URL(string: "tel://\(number)"), APPLICATION.canOpenURL(url) {
            if #available(iOS 10, *) {
                APPLICATION.open(url)
            } else {
                APPLICATION.openURL(url)
            }
        } else {
            POPUP_MANAGER.makeToast("Can't make call")
        }
    }
    
    func playVideo(_ urlStr : String?) {
        guard let urlStr = urlStr, let videoURL = URL(string: urlStr) else { return }
        let asset = BMPlayerManager.shared.cacheManeger.playerItem(with: videoURL)
        let player = AVPlayer(playerItem: asset)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    func addAsChildVC(_ vc: UIViewController?, container: UIView? = nil) {
        guard let vc = vc, let superView = container ?? view else { return }

        // Add Child View Controller
        addChild(vc)
        
        // Add Child View as Subview
        superView.addSubview(vc.view)
        
        // Configure Child View
        vc.view.frame = superView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        vc.didMove(toParent: self)
    }
    
    func removeFromSuperVC() {
        // Notify Child View Controller
        willMove(toParent: nil)
        
        // Remove Child View From Superview
        view.removeFromSuperview()
        
        // Notify Child View Controller
        removeFromParent()
    }

    //MARK: - Active Label
    func setupActiveLabel(label: ActiveLabel?, color: UIColor? = nil) {
        guard let lblActive = label else { return }
        
        let customType = ActiveType.custom(pattern: Constants.regex_website)
        lblActive.enabledTypes = [customType]
        lblActive.customColor[customType] = color ?? AppColor.purple_opacity54
        lblActive.customSelectedColor[customType] = color ?? AppColor.purple_opacity54
        
        lblActive.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case customType:
                atts[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
            default:
                break
            }
            return atts
        }
        
        lblActive.handleCustomTap(for: customType) { urlString in
            var url = urlString
            if !urlString.contains("https://"), !urlString.contains("http://")  {
                url = "https://" + urlString
            }
            self.openUrl(urlString: url)
        }
    }

}
