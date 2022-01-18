//
//  Int+Ex.swift
//  Plans
//
//  Created by Star on 1/25/21.
//

import Foundation

extension Int {
    func getDayofWeek() -> String {
        var result = "Sunday"

        let value = self - 1
        switch ((value % 7) + 1 ){
        case 1:
            result = "Sunday"
        case 2:
            result = "Monday"
        case 3:
            result = "Tuesday"
        case 4:
            result = "Wednesday"
        case 5:
            result = "Thursday"
        case 6:
            result = "Friday"
        case 7:
            result = "Saturday"
        default:
          break
        }
        
        return result
    }
}


