//
//  UITextView+Ex.swift
//  Plans
//
//  Created by Star on 2/23/21.
//

import Foundation
import UIKit

extension UITextView {
    
    func numberOfLines() -> Int {
        let layoutManager:NSLayoutManager = self.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var numberOfLines = 0
        var index = 0
        var lineRange:NSRange = NSRange()

        while (index < numberOfGlyphs) {
            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange);
            numberOfLines = numberOfLines + 1
        }
        
        return numberOfLines
    }

}
