//
//  File.swift
//  TattooPlanet
//
//  Created by Peeyush Karnwal on 22/07/17.
//  Copyright © 2017 Girijesh Kumar. All rights reserved.
//

import Foundation

class FBUser: NSObject {
    
    var name: String?
    var fbId: String?
    var birthday: String?
    var email: String?
    var fbToken: String?
    var profileImage: String?
    var first_name: String?
    var last_name: String?

    var age: Int?
    
    init(jsonDic: [String: Any]?) {
        super.init()
        
        if let birthday = jsonDic?["birthday"] as? String {
            self.birthday = birthday
            age = birthday.ageFrom(dateFormat: DateFormat.fbApiDate)
        }
        if let email = jsonDic?["email"] as? String {
            self.email = email
        }
        if let name = jsonDic?["name"] as? String {
            self.name = name
        }
        if let firstname = jsonDic?["first_name"] as? String {
            first_name = firstname
        }
        
        if let lastname = jsonDic?["last_name"] as? String {
            last_name = lastname
        }
        
        if let userID = jsonDic?["id"] as? String{
            fbId = userID
            profileImage = "https://graph.facebook.com/\(userID)/picture?height=400&width=400"
        }
    }
    
}
