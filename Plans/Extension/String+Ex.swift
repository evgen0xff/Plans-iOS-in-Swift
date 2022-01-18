//
//  String+Ex.swift
//  Plans
//
//  Created by Star on 5/12/20.
//  Copyright © 2020 Plans Collective LLC. All rights reserved.
//

import Foundation
import UIKit

extension Character {
    var isAscii : Bool {
        return unicodeScalars.allSatisfy{$0.isASCII}
    }
    
    var ascii: UInt32? {
        return isAscii ? unicodeScalars.first?.value : nil
    }
    
    var isCharVowel: Bool? {
        var isTrue: Bool? = nil
        switch String(self).lowercased() {
        case "a","e","i","o","u":
            isTrue = true
        case "b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z":
            isTrue = false
        default:
            break
        }
        return isTrue
    }

}

extension StringProtocol {
    var asciiValues: [UInt8] { compactMap(\.asciiValue)}
}


extension String {
    var byWords: [String] {
        var byWords:[String] = []
        enumerateSubstrings(in: startIndex..<endIndex, options: .byWords) { p,q,r,s  in
            guard let word = p else { return }
            byWords.append(word)
        }
        return byWords
    }
    
    var firstWord: String {
        return byWords.first ?? ""
    }
    
    var lastWord: String {
        return byWords.last ?? ""
    }
    var uppercasingFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }

    func firstWords(_ max: Int) -> [String] {
        return Array(byWords.prefix(max))
    }
    
    func lastWords(_ max: Int) -> [String] {
        return Array(byWords.suffix(max))
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + self.lowercased().dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func containsNumbers() -> Bool {
        
        // check if there's a range for a number
        let range = rangeOfCharacter(from: .decimalDigits)
        
        // range will be nil if no whitespace is found
        if let _ = range {
            return true
        } else {
            return false
        }
        
    }
    
}

// MARK: Location
extension String {
    
    func removeOwnCountry(_ countryOwn: String? = nil) -> String {
        guard let countryOwn = countryOwn ?? USER_MANAGER.countryOwn else { return self}
        var result = self
        var compoents = components(separatedBy: ", ")
        if let last = compoents.lastIndex(of: countryOwn){
            if last > 0 {
                compoents.removeSubrange(last...(compoents.count-1))
            }else {
                compoents.remove(at: last)
            }
            result = compoents.joined(separator: ", ")
        }
        
        return result
    }

    func getCountryNameFromAddress() -> String? {
        return components(separatedBy: ", ").last(where: {$0.containsNumbers() == false})
    }
}

// MARK: Attributed String
extension String {
    func colored(color: UIColor? = nil,
                 font: UIFont? = nil,
                 imageAttach: String? = nil,
                 isAttachAfterText: Bool = true,
                 offsetY: CGFloat = -3.0) -> NSMutableAttributedString {
        
        let result = NSMutableAttributedString(string: "")
        
        var attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color ?? .black]
        if let font = font {
            attrs[.font] = font
        }
        
        let text = NSMutableAttributedString(string:self, attributes: attrs)
        var attach: NSMutableAttributedString?
        
        if let imageAttach = imageAttach, let image = UIImage(named: imageAttach) {
            let textAttach = NSTextAttachment()
            textAttach.image = image
            textAttach.bounds = CGRect(x: 0, y: offsetY, width: image.size.width, height: image.size.height)
            attach = NSMutableAttributedString(attachment: textAttach)
        }
        
        if let attach = attach, isAttachAfterText == false {
            result.append(attach)
        }
        
        result.append(text)
        
        if let attach = attach, isAttachAfterText == true {
            result.append(attach)
        }

        return result
    }

}

// MARK: - Size
extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension NSAttributedString {

    func height(containerWidth: CGFloat) -> CGFloat {

        let rect = self.boundingRect(with: CGSize.init(width: containerWidth, height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.height)
    }

    func width(containerHeight: CGFloat) -> CGFloat {

        let rect = self.boundingRect(with: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: containerHeight),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.width)
    }
}

// MARK: - Date
extension String {
    func dateFromString(dateFormat: String) -> Date? {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.date(from: self)
    }
    
    func ageFrom(dateFormat: String) -> Int? {
        let dateOfBrith = dateFromString(dateFormat: dateFormat)
        return dateOfBrith?.userAge()
    }

}

// MARK: - Phone Number
extension String {
    static let countryDictionary  = ["AF":"93",
                              "AL":"355",
                              "DZ":"213",
                              "AS":"1",
                              "AD":"376",
                              "AO":"244",
                              "AI":"1",
                              "AG":"1",
                              "AR":"54",
                              "AM":"374",
                              "AW":"297",
                              "AU":"61",
                              "AT":"43",
                              "AZ":"994",
                              "BS":"1",
                              "BH":"973",
                              "BD":"880",
                              "BB":"1",
                              "BY":"375",
                              "BE":"32",
                              "BZ":"501",
                              "BJ":"229",
                              "BM":"1",
                              "BT":"975",
                              "BA":"387",
                              "BW":"267",
                              "BR":"55",
                              "IO":"246",
                              "BG":"359",
                              "BF":"226",
                              "BI":"257",
                              "KH":"855",
                              "CM":"237",
                              "CA":"1",
                              "CV":"238",
                              "KY":"345",
                              "CF":"236",
                              "TD":"235",
                              "CL":"56",
                              "CN":"86",
                              "CX":"61",
                              "CO":"57",
                              "KM":"269",
                              "CG":"242",
                              "CK":"682",
                              "CR":"506",
                              "HR":"385",
                              "CU":"53",
                              "CY":"537",
                              "CZ":"420",
                              "DK":"45",
                              "DJ":"253",
                              "DM":"1",
                              "DO":"1",
                              "EC":"593",
                              "EG":"20",
                              "SV":"503",
                              "GQ":"240",
                              "ER":"291",
                              "EE":"372",
                              "ET":"251",
                              "FO":"298",
                              "FJ":"679",
                              "FI":"358",
                              "FR":"33",
                              "GF":"594",
                              "PF":"689",
                              "GA":"241",
                              "GM":"220",
                              "GE":"995",
                              "DE":"49",
                              "GH":"233",
                              "GI":"350",
                              "GR":"30",
                              "GL":"299",
                              "GD":"1",
                              "GP":"590",
                              "GU":"1",
                              "GT":"502",
                              "GN":"224",
                              "GW":"245",
                              "GY":"595",
                              "HT":"509",
                              "HN":"504",
                              "HU":"36",
                              "IS":"354",
                              "IN":"91",
                              "ID":"62",
                              "IQ":"964",
                              "IE":"353",
                              "IL":"972",
                              "IT":"39",
                              "JM":"1",
                              "JP":"81",
                              "JO":"962",
                              "KZ":"77",
                              "KE":"254",
                              "KI":"686",
                              "KW":"965",
                              "KG":"996",
                              "LV":"371",
                              "LB":"961",
                              "LS":"266",
                              "LR":"231",
                              "LI":"423",
                              "LT":"370",
                              "LU":"352",
                              "MG":"261",
                              "MW":"265",
                              "MY":"60",
                              "MV":"960",
                              "ML":"223",
                              "MT":"356",
                              "MH":"692",
                              "MQ":"596",
                              "MR":"222",
                              "MU":"230",
                              "YT":"262",
                              "MX":"52",
                              "MC":"377",
                              "MN":"976",
                              "ME":"382",
                              "MS":"1",
                              "MA":"212",
                              "MM":"95",
                              "NA":"264",
                              "NR":"674",
                              "NP":"977",
                              "NL":"31",
                              "AN":"599",
                              "NC":"687",
                              "NZ":"64",
                              "NI":"505",
                              "NE":"227",
                              "NG":"234",
                              "NU":"683",
                              "NF":"672",
                              "MP":"1",
                              "NO":"47",
                              "OM":"968",
                              "PK":"92",
                              "PW":"680",
                              "PA":"507",
                              "PG":"675",
                              "PY":"595",
                              "PE":"51",
                              "PH":"63",
                              "PL":"48",
                              "PT":"351",
                              "PR":"1",
                              "QA":"974",
                              "RO":"40",
                              "RW":"250",
                              "WS":"685",
                              "SM":"378",
                              "SA":"966",
                              "SN":"221",
                              "RS":"381",
                              "SC":"248",
                              "SL":"232",
                              "SG":"65",
                              "SK":"421",
                              "SI":"386",
                              "SB":"677",
                              "ZA":"27",
                              "GS":"500",
                              "ES":"34",
                              "LK":"94",
                              "SD":"249",
                              "SR":"597",
                              "SZ":"268",
                              "SE":"46",
                              "CH":"41",
                              "TJ":"992",
                              "TH":"66",
                              "TG":"228",
                              "TK":"690",
                              "TO":"676",
                              "TT":"1",
                              "TN":"216",
                              "TR":"90",
                              "TM":"993",
                              "TC":"1",
                              "TV":"688",
                              "UG":"256",
                              "UA":"380",
                              "AE":"971",
                              "GB":"44",
                              "US":"1",
                              "UY":"598",
                              "UZ":"998",
                              "VU":"678",
                              "WF":"681",
                              "YE":"967",
                              "ZM":"260",
                              "ZW":"263",
                              "BO":"591",
                              "BN":"673",
                              "CC":"61",
                              "CD":"243",
                              "CI":"225",
                              "FK":"500",
                              "GG":"44",
                              "VA":"379",
                              "HK":"852",
                              "IR":"98",
                              "IM":"44",
                              "JE":"44",
                              "KP":"850",
                              "KR":"82",
                              "LA":"856",
                              "LY":"218",
                              "MO":"853",
                              "MK":"389",
                              "FM":"691",
                              "MD":"373",
                              "MZ":"258",
                              "PS":"970",
                              "PN":"872",
                              "RE":"262",
                              "RU":"7",
                              "BL":"590",
                              "SH":"290",
                              "KN":"1",
                              "LC":"1",
                              "MF":"590",
                              "PM":"508",
                              "VC":"1",
                              "ST":"239",
                              "SO":"252",
                              "SJ":"47",
                              "SY":"963",
                              "TW":"886",
                              "TZ":"255",
                              "TL":"670",
                              "VE":"58",
                              "VN":"84",
                              "VG":"284",
                              "VI":"340"]
    
    func formatPhoneNumber(shouldRemoveLastDigit: Bool = false, maxLength: Int = 10) -> String {
        let phoneNumber = self
        guard !phoneNumber.isEmpty else { return "" }
        guard let regex = try? NSRegularExpression(pattern: "[\\s-\\(\\)]", options: .caseInsensitive) else { return "" }
        let r = NSString(string: phoneNumber).range(of: phoneNumber)
        var number = regex.stringByReplacingMatches(in: phoneNumber, options: .init(rawValue: 0), range: r, withTemplate: "")
        
        if number.count > maxLength {
            let tenthDigitIndex = number.index(number.startIndex, offsetBy: maxLength)
            number = String(number[number.startIndex..<tenthDigitIndex])
        }
        
        if shouldRemoveLastDigit {
            let end = number.index(number.startIndex, offsetBy: number.count-1)
            number = String(number[number.startIndex..<end])
        }
        
        if number.count < 7 {
            let end = number.index(number.startIndex, offsetBy: number.count)
            let range = number.startIndex..<end
            number = number.replacingOccurrences(of: "(\\d{3})(\\d+)", with: "$1-$2", options: .regularExpression, range: range)
            
        } else {
            let end = number.index(number.startIndex, offsetBy: number.count)
            let range = number.startIndex..<end
            number = number.replacingOccurrences(of: "(\\d{3})(\\d{3})(\\d+)", with: "$1-$2-$3", options: .regularExpression, range: range)
        }
        return number
    }

    // Get the digital number from a formatted phone number : ex. "+1 (123) 456-7890" -> "11234567890" or "1234567890"
    func getDigitalPhoneNum(isRemoveCountryCode: Bool = true) -> String {
        guard self.count >= 4 else { return self }

        var result = self
        if isRemoveCountryCode == true {
            for (_, value) in String.countryDictionary {
                let code = "+" + value
                if self.contains(code) {
                    result = result.replacingOccurrences(of: code, with: "")
                    break
                }
            }
        }
        
        result = result.replacingOccurrences(of: "+", with: "")
        result = result.replacingOccurrences(of: "(", with: "")
        result = result.replacingOccurrences(of: ")", with: "")
        result = result.replacingOccurrences(of: " ", with: "")
        result = result.replacingOccurrences(of: "-", with: "")
        
        return result
    }
    
    // Get the formatted phone number from a number string
    // ex: "+11234567890" -> "+1 (123) 456-7890"
    //     "1234567890" -> "123-456-7890"
    func getFormattedPhoneNumber(separator: String? = nil, isOmitOwnCountryCode: Bool = true) -> String {
        var result = self
        let numberWithoutCountry = getDigitalPhoneNum()
        let char = separator ?? "-"
        
        guard numberWithoutCountry.count > 6 else { return result }

        let first = numberWithoutCountry.substring(from: 0, length: 3) ?? ""
        let second = numberWithoutCountry.substring(from: 3, length: 3) ?? ""
        let last = numberWithoutCountry.substring(from: 6, length: (numberWithoutCountry.count - 6)) ?? ""

        result = "\(first)\(char)\(second)\(char)\(last)"

        if let codeCountry = checkCountryNumberCode() {
            if isOmitOwnCountryCode {
                if codeCountry != "+1" {
                    result = "\(codeCountry) \(result)"
                }
            }else {
                result = "\(codeCountry) \(result)"
            }
        }
        
        return result
    }
    
    // Get country number code from ISO code : ex. US -> +1, CN -> +86
    // Default : +1
    func getCountryPhoneCodeFromISO () -> String {
        if let code = String.countryDictionary[self.uppercased()] {
            return "+" + code
        }
        else {
            return "+1"
        }
    }

    // Check if it includes a country number code
    // Return : +11234567890 -> +1
    //            1234567890 -> nil
    func checkCountryNumberCode() -> String? {
        var result : String?
        for (_, value) in String.countryDictionary {
            let code = "+" + value
            if self.contains(code) {
                result = code
                break
            }
        }
        return result
    }

    // Get country number code from phone number code : ex. +11234567890 -> +1,  +861234567890-> +86
    // Default : +1
    func getCountryPhoneCodeFromPhoneNumber() -> String {
        let defaultCode = "+1"
        return checkCountryNumberCode() ?? defaultCode
    }
}

// MARK: - Validation Check
extension String {
    func isOnlyAlphabetical() -> Bool {
        return isOnlyAvaliableChars(chars: APP_CONFIG.CHARACTERS_ACCEPTABLE)
    }

    func isOnlyAvaliableChars(chars : String) -> Bool {
        let cs = NSCharacterSet(charactersIn: chars).inverted
        let filtered = self.components(separatedBy: cs).joined(separator: "")
        return self == filtered
    }

    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    func isValidPasssword() -> Bool {
        let passwordRegEx = "^(?=.*[a-zA-Z])(?=.*[0-9]).{8,16}"
        let passwordTest = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordTest.evaluate(with: self)
    }
    
    func isValidPhone() -> Bool {
        let PHONE_REGEX = "^((\\+)|(00))[0-9]{6,14}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result =  phoneTest.evaluate(with: self)
        return result
    }
    
    func isValidUsername() -> Bool {
        let name = trimmingCharacters(in: .whitespaces)
        if name.count > 0, name.count <= 50 {
            return true
        }else {
            return false
        }
    }

}
