//
//  NSObject+Ex.swift
//  Plans
//
//  Created by Star on 1/28/21.
//

import Foundation

extension NSObject {
    
    class var className: String {
        return String(describing: self)
    }
    
    
}
