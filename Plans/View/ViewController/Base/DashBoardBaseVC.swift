//
//  DashBoardBaseVC.swift
//  Plans
//
//  Created by Star on 2/9/21.
//

import UIKit

// Main Tabbar Item's ViewContorller.
// DashBoardBaseVC -> PlansBaseVC -> BaseViewController -> UIViewController
// The bottom tabbar with center action button

class DashBoardBaseVC: PlansBaseVC {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        APP_MANAGER.updateTabBar(isHiddenCenterAction: false)
    }
}
