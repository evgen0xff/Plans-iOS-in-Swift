//
//  PlansRefreshFooter.swift
//  Plans
//
//  Created by Star on 7/14/20.
//  Copyright © 2020 Plans Collective. All rights reserved.
//

import UIKit
import PullToRefreshKit

class PlansRefreshFooter: UIView, RefreshableFooter {

    class func footer() -> PlansRefreshFooter {
        return PlansRefreshFooter()
    }
    
    var indicator = PlansIndicatorView.loadForPullToRefresh()
    var refreshMode = RefreshMode.scroll
    var isEndedRefreshing = true
    
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
    }
    
    func updateUI () {
        indicator.center = CGPoint(x: frame.size.width/2.0, y: frame.size.height/2.0);
    }
    
    // MARK: - RefreshableFooter
    func heightForFooter() -> CGFloat {
        return indicator.bounds.size.height
    }
    
    func didUpdateToNoMoreData() {
    }
    
    func didResetToDefault() {
    }
    
    func didEndRefreshing() {
        self.isHidden = true
        isEndedRefreshing = true
        indicator.stopAnimating()
    }
    
    func didBeginRefreshing() {
        self.isHidden = false
        isEndedRefreshing = false
        indicator.startAnimating()
    }
    
    func shouldBeginRefreshingWhenScroll() -> Bool {
        return refreshMode != .tap
    }
    
}
