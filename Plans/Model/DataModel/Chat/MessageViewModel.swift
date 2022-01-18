//
//  MessageViewModel.swift
//  Plans
//
//  Created by Star on 3/3/21.
//

import UIKit

class MessageViewModel: NSObject {
    enum OwnerType {
        case date
        case mine
        case other
    }
    
    enum CornerType : Int {
        case topLeft = 0
        case topRight = 1
        case bottomRight = 2
        case bottomLeft = 3
    }
    
    enum PositionType {
        case normal
        case start
        case medium
        case end
    }
    
    var isHiddenProfileImage = false
    var isHiddenOwnerName = false
    var colorBackGround: UIColor = .white
    var colorMessage: UIColor = .black
    var colorTime: UIColor = AppColor.grey_text
    var cornersNonRounding = [CornerType]()
    
    var ownerType: OwnerType = .other {
        didSet {
            colorBackGround = ownerType == .mine ? AppColor.teal_main : .white
            colorMessage = ownerType == .mine ? .white : .black
        }
    }
    
    var positionType: PositionType = .normal {
        didSet {
            isHiddenProfileImage = true
            isHiddenOwnerName = true
            cornersNonRounding.removeAll()
            switch positionType {
            case .normal:
                if ownerType == .other {
                    isHiddenProfileImage = false
                    isHiddenOwnerName = false
                }
                break
            case .start:
                if ownerType == .mine {
                    cornersNonRounding.append(contentsOf: [.bottomRight])
                }else if ownerType == .other {
                    isHiddenOwnerName = false
                    cornersNonRounding.append(contentsOf: [.bottomLeft])
                }
                break
            case .medium:
                if ownerType == .mine {
                    cornersNonRounding.append(contentsOf: [.topRight, .bottomRight])
                }else if ownerType == .other {
                    cornersNonRounding.append(contentsOf: [.topLeft, .bottomLeft])
                }
                break
            case .end:
                if ownerType == .mine {
                    cornersNonRounding.append(contentsOf: [.topRight])
                }else if ownerType == .other {
                    isHiddenProfileImage = false
                    cornersNonRounding.append(contentsOf: [.topLeft])
                }
                break
            }
        }
    }

}
