//
//  UIButton+Ex.swift
//  Plans
//
//  Created by Star on 2/1/21.
//

import Foundation
import UIKit

extension UIButton {
    
    enum DoneTheme {
        case auth
        
        var activeTitleColor : UIColor {
            switch self {
            case .auth:
                return AppColor.pink_done
            }
        }
        
        var inactiveTitleColor : UIColor {
            switch self {
            case .auth:
                return .white
            }
        }

        var activeBackgroundColor : UIColor {
            switch self {
            case .auth:
                return .white
            }
        }
        
        var inactiveBackgroundColor : UIColor {
            switch self {
            case .auth:
                return AppColor.grey_button
            }
        }

    }
    
    private func updateActive(_ isActive: Bool = false,
                      activeTitleColor: UIColor = AppColor.pink_done,
                      inactiveTitleColor: UIColor = .white,
                      activeBackgroundColor: UIColor = .white,
                      inactiveBackgroundColor: UIColor = AppColor.grey_button) {
        
        isEnabled = isActive
        setTitleColor(isActive ? activeTitleColor : inactiveTitleColor, for: .normal)
        backgroundColor = isActive ? activeBackgroundColor : inactiveBackgroundColor
    }

    func updateActive(_ isActive: Bool = false, theme: DoneTheme = DoneTheme.auth) {
        updateActive(isActive,
                     activeTitleColor: theme.activeTitleColor,
                     inactiveTitleColor: theme.inactiveTitleColor,
                     activeBackgroundColor: theme.activeBackgroundColor,
                     inactiveBackgroundColor: theme.inactiveBackgroundColor)
    }

}


