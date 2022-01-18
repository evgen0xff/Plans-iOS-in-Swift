//
//  PlansRefreshHeader.swift
//  Plans
//
//  Created by Star on 7/14/20.
//  Copyright © 2020 Plans Collective. All rights reserved.
//

import UIKit
import PullToRefreshKit

class PlansRefreshHeader: UIView, RefreshableHeader {
    
    class func header() -> PlansRefreshHeader {
        return PlansRefreshHeader()
    }
    
    var indicator = PlansIndicatorView.loadForPullToRefresh()
    var durationWhenHide = 0.3
    var isEndedRefreshing = true
    var isUnderStatusBar = false
    var status: RefreshHeaderState = .idle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }

    // MARK: - Private Methods
    func initialize() {
        addSubview(indicator)
        self.isHidden = true
        self.backgroundColor = .clear
    }
    
    func updateUI () {
        let x = frame.size.width/2.0
        let y = frame.size.height/2.0 + (isUnderStatusBar == true ? (UIDevice.current.heightTopNotch / 2.0) : 0)
        indicator.center = CGPoint(x: x, y: y);
    }

    // MARK: - RefreshableHeader
    func heightForHeader() -> CGFloat {
        return indicator.bounds.size.height + (isUnderStatusBar == true ? UIDevice.current.heightTopNotch : 0)
    }
    
    func percentUpdateDuringScrolling(_ percent: CGFloat) {
        self.isHidden = false
    }
    
    func didBeginRefreshingState() {
        self.isHidden = false
        isEndedRefreshing = false
        indicator.startAnimating()
    }
    
    func durationOfHideAnimation() -> Double {
        return durationWhenHide
    }
    
    func didBeginHideAnimation(_ result: RefreshResult) {
        isEndedRefreshing = true
        indicator.stopAnimating()
    }
    
    func didCompleteHideAnimation(_ result: RefreshResult) {
        self.isHidden = true
    }
    
    func stateDidChanged(_ oldState: RefreshHeaderState, newState: RefreshHeaderState) {
        status = newState
    }

}
