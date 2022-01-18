//
//  UILabel+Ex.swift
//  Plans
//
//  Created by Top Star on 9/20/21.
//

import Foundation
import UIKit

extension UILabel {
    func countLines(text: String? = nil, width: CGFloat? = nil, font: UIFont? = nil) -> Int {
        
        guard let myText = text ?? self.text else { return 0 }
        guard let myFont = font ?? self.font else { return 0 }
        
        let myWidth = width ?? self.bounds.width
        let heightLabel = myText.height(withConstrainedWidth: myWidth, font: myFont)

        return Int(heightLabel / myFont.lineHeight)
    }

    func countLines(textAttri: NSAttributedString? = nil, width: CGFloat? = nil, font: UIFont? = nil, fontTrail: UIFont? = nil) -> Int {
        
        guard let myText = textAttri else { return 0 }
        guard let myFont = font ?? self.font else { return 0 }
        
        let myWidth = width ?? self.bounds.width
        let heightLabel = myText.height(containerWidth: myWidth)
        var count = Int(heightLabel / myFont.lineHeight)
        let remained = CGFloat(heightLabel - (CGFloat(count) * myFont.lineHeight))
        if let fontEnd = fontTrail, remained > 0 {
            count += Int(remained / fontEnd.lineHeight)
        }

        return count
    }

}
