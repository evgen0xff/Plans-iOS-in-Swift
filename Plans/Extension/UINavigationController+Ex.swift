//
//  UINavigationController+Ex.swift
//  Plans
//
//  Created by Star on 3/22/21.
//

import UIKit

extension UINavigationController {

    func popViewController(animated: Bool = true, direction: CATransitionSubtype? = nil) {
        if animated == true, let direction = direction {
            let transition = CATransition()
            transition.duration = 0.4
            transition.type = .reveal
            transition.subtype = direction
            view.layer.add(transition, forKey: kCATransition)
            popViewController(animated: false)
        }else {
            popViewController(animated: animated)
        }
    }
}
