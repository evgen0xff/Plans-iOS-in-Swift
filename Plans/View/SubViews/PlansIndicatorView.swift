//
//  PlansIndicatorView.swift
//  Plans
//
//  Created by Star on 5/19/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class PlansIndicatorView: UIView {

    @IBOutlet var viewContent: UIView!
    @IBOutlet var lblMessage: UILabel!
    @IBOutlet var loadingIndicator: NVActivityIndicatorView!
    @IBOutlet var consHeightIndicator: NSLayoutConstraint!

    @IBInspectable public var message : String = ""
    @IBInspectable public var colorIndicator : UIColor = AppColor.teal_main
    @IBInspectable public var heightIndicator: CGFloat = 20.0
    
    var type = NVActivityIndicatorType.circleStrokeSpin

    var isAnimating : Bool {
        return loadingIndicator.isAnimating
    }

    class func loadView(_ message: String? = nil,
                        heightIndicator: CGFloat = 20,
                        size: CGSize = CGSize(width: 50, height: 41),
                        cornerRadius: CGFloat = 5.0,
                        type: NVActivityIndicatorType = .circleStrokeSpin,
                        tintColor: UIColor = AppColor.teal_main,
                        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7) ) -> PlansIndicatorView {

        let loading = PlansIndicatorView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        loading.message = message ?? ""
        loading.heightIndicator = heightIndicator
        loading.type = type
        loading.colorIndicator = tintColor
        loading.layer.cornerRadius = cornerRadius
        loading.backgroundColor = backgroundColor
        loading.bounds.size = size

        return loading
    }

    
    class func loadForToast(_ message: String? = nil) -> PlansIndicatorView {
        return PlansIndicatorView.loadView(message)
    }

    class func loadForFullRefresh(_ message: String? = nil) -> PlansIndicatorView {
        return PlansIndicatorView.loadView(message, heightIndicator: 40, size: CGSize(width: 70, height: 70))
    }

    class func loadForPullToRefresh(_ message: String? = nil) -> PlansIndicatorView {
        return PlansIndicatorView.loadView(message, heightIndicator: 30, size: CGSize(width: 60, height: 60), backgroundColor: .clear)
    }

     
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    func initialize() {
        Bundle.main.loadNibNamed(PlansIndicatorView.className, owner: self, options: nil)
        viewContent.fixInView(self)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
    }
  
    func startAnimating() {
        loadingIndicator?.startAnimating()
    }
    
    func stopAnimating() {
        loadingIndicator?.stopAnimating()
    }
     
    func setupUI () {
        lblMessage?.text = message
        loadingIndicator?.type = type
        loadingIndicator?.color = colorIndicator
        consHeightIndicator?.constant = heightIndicator

        if let msg = lblMessage?.text, msg != "" {
            let width = msg.width(withConstraintedHeight: heightIndicator, font: AppFont.regular.size(17)) + 45 + heightIndicator
            bounds.size = CGSize(width: width, height: bounds.size.height)
            lblMessage?.isHidden = false
        }else {
            lblMessage?.isHidden = true
        }

        sizeToFit()
    }
    

}
