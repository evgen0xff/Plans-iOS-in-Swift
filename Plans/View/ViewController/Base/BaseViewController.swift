//
//  BaseViewController.swift
//  Plans
//
//  Created by Star on 1/23/21.
//

import UIKit

/*
* Most Super ViewController of all viewcontorllers in the app.
* BaseViewController -> UIViewController
* Center Loading view, PullToRefresh on top and bottom
*/

class BaseViewController: UIViewController {
    
    let loader: LoaderView = LoaderView.fromNib()
    let refreshHeader = PlansRefreshHeader.header()
    let refreshFooter = PlansRefreshFooter.footer()
    var screenName: String? { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NOTIFICATION_CENTER.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { (noti) in
            guard let userInfo = noti.userInfo as NSDictionary? else { return }
            guard let keyboardFrame = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as? NSValue else { return }
            self.willShowKeyboard(frame: keyboardFrame.cgRectValue)
        }
        NOTIFICATION_CENTER.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { (noti) in
            self.willHideKeyboard()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NOTIFICATION_CENTER.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NOTIFICATION_CENTER.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ANALYTICS_MANAGER.logScreenView(screenName, className: String(describing: type(of: self)))
    }

    func willShowKeyboard (frame: CGRect) {
    }
    
    func willHideKeyboard (){
    }
    
    func showLoader(_ message : String? = nil) {
        loader.showLoader(message)
    }

    func hideLoader() {
        loader.hideLoader()
    }

    func hideLoaderAfter(_ message :String , completion: (() -> Void)? = nil) {
        loader.hideLoaderAfter(message) {
            completion?()
        }
    }
    
    // MARK: - Prviate Methods
    func initialize() {
        initializeData()
        setupUI()
    }
    
    func initializeData() {
    }
    
    func setupUI() {
    }

    
}
