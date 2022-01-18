//
//  UIDevice+Ex.swift
//  Plans
//
//  Created by Star on 7/20/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import Foundation

extension UIDevice {

    static let uuidString: String? = UIDevice.current.identifierForVendor?.uuidString
    
    var heightTopNotch: CGFloat {
        return APP_DELEGATE.window?.safeAreaInsets.top ?? 0
    }
    
    var heightBottomNotch: CGFloat {
        return APP_DELEGATE.window?.safeAreaInsets.bottom ?? 0
    }

    var heightTopBar: CGFloat {
        return heightTopNotch + 44.0
    }

    var hasTopNotch: Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
            return heightTopNotch > 20
        }
        return false
    }
    
    
}
