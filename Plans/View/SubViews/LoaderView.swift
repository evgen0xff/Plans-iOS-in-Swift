//
//  LoaderView.swift
//  Plans
//
//  Created by Plans Collective LLC on 6/22/18.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import Foundation
import UIKit

class  LoaderView: UIView
{
    // MARK: - IBOutlets
    
    @IBOutlet weak var imgViewDone: UIImageView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var indicatorView: PlansIndicatorView!
    
    var isAdded = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true
        self.frame = CGRect(x: 0, y: 0, width: MAIN_SCREEN_WIDTH, height: MAIN_SCREEN_HEIGHT)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isHidden = true
        self.frame = CGRect(x: 0, y: 0, width: MAIN_SCREEN_WIDTH, height: MAIN_SCREEN_HEIGHT)
    }

    func showLoader(_ message : String? = nil, isDoneMark: Bool = false, delay: TimeInterval = 2.0) {
        isAdded = true
 
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + delay) {
            guard self.isAdded == true else { return }

            self.isHidden = false
            
            self.imgViewDone?.isHidden = !isDoneMark
            self.indicatorView?.isHidden = isDoneMark
            
            if isDoneMark == false {
                self.indicatorView?.startAnimating()
            }
            
            if let msg = message, msg != "" {
                self.indicatorView?.backgroundColor = .clear
                self.lblMessage?.text = msg
                self.lblMessage?.isHidden = false
                self.lblMessage.textColor = isDoneMark ? .white : .white
                self.innerView?.backgroundColor = isDoneMark ? .clear : .white
                self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            }else {
                self.indicatorView?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                self.lblMessage?.text = ""
                self.lblMessage?.isHidden = true
                self.innerView?.backgroundColor = .clear
                self.backgroundColor = .clear
            }
            
            APPLICATION.keyWindow?.addSubview(self)
        }
    }
    
    func hideLoaderAfter(_ messageDone : String? = nil, duration: TimeInterval = 1.0, completion: @escaping () -> ()) {
        showLoader(messageDone, isDoneMark: true, delay: 0)
        APP_CONFIG.defautMainQ.asyncAfter(deadline: .now() + duration, execute: {
            self.hideLoader ()
            completion()
        })
    }
    
    func hideLoader () {
        APP_CONFIG.defautMainQ.async {
            self.indicatorView?.stopAnimating()
            self.isHidden = true
            self.removeFromSuperview()
            self.isAdded = false
        }
    }
}
