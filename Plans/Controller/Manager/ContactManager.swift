//
//  ContactManager.swift
//  Plans
//
//  Created by Star on 2/18/21.
//

import Foundation
import Contacts


let CONTACT_MANAGER = ContactManager.share
class ContactManager: NSObject {
    static let share = ContactManager()
    
    func fetchContactList(isAlert: Bool = false, complete: ((Bool, [UserModel]?) -> Void)? = nil) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: {
            granted, error in
            
            guard granted else {
                APP_CONFIG.defautMainQ.async {
                    if isAlert == true {
                        POPUP_MANAGER.makeToast("Can't access contact. Please go to Settings -> Plan App to enable contact permission")
                    }
                    complete?(false, nil)
                }
                return
            }
            
            let keysToFetch = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey,CNContactImageDataKey] as [Any]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
            var cnContacts = [CNContact]()
            do {
                try store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    cnContacts.append(contact)
                }
            } catch let error {
                NSLog("Fetch contact error: \(error)")
                APP_CONFIG.defautMainQ.async {
                    complete?(false, nil)
                }
            }
            APP_CONFIG.defautMainQ.async {
                complete?(true, cnContacts.map({UserModel(contact: $0)}))
            }
        })
    }



}
