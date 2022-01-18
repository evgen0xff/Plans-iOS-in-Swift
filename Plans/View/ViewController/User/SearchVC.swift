//
//  SearchVC.swift
//  Plans
//
//  Created by Star on 2/9/21.
//

import UIKit
import Contacts

protocol SearchDelegate {
    
    func hidePeopleView(value: Int) -> Void
//    func selectedPeople(_ arrPeople: [Contacts], arrFriends: [UserModel])
}

class SearchVC: PlansContentBaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
