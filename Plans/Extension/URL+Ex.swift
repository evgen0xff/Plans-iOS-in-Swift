//
//  URL+Ex.swift
//  Plans
//
//  Created by Star on 10/13/20.
//  Copyright © 2020 PlansCollective. All rights reserved.
//

import UIKit
import Foundation

extension URL {

    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
