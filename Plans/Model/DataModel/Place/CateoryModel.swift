//
//  CateoryModel.swift
//  Plans
//
//  Created by Star on 5/23/20.
//  Copyright © 2020 Brainmobi. All rights reserved.
//

import UIKit
import ObjectMapper


class CateoryModel: NSObject {
    var name : String?
    var iconImage: String?
    var defaultImage: String?
    var types: [String]?
    var typesRestricted: [String]?
    
    init(name: String? = nil, iconImage: String? = nil, defaultImage: String? = nil, types: [String]? = nil, typesRestricted: [String]? = nil) {
        super.init()
        self.name = name
        self.iconImage = iconImage
        self.defaultImage = defaultImage
        self.types = types
        self.typesRestricted = typesRestricted
    }
    
    static var plansCateories : [CateoryModel] {
        var list = [CateoryModel]()
        let food = CateoryModel(name: "Food & Drink",
                                iconImage: "ic_food_green",
                                defaultImage: "ic_food_white",
                                types: ["bakery","restaurant","cafe"])
        
        let outDoors = CateoryModel(name: "Outdoors",
                                    iconImage: "ic_outdoor_green",
                                    defaultImage: "ic_outdoor_white",
                                    types: ["amusement_park", "park","zoo"])
        
        let nightlife = CateoryModel(name: "Nightlife",
                                     iconImage: "ic_wine_green",
                                     defaultImage: "ic_wine_white",
                                     types: ["bar","night_club"])
        
        let fitness = CateoryModel(name: "Fitness",
                                   iconImage: "ic_fitness_green",
                                   defaultImage: "ic_fitness_white",
                                   types: ["gym"])
        
        let entertainment = CateoryModel(name: "Entertainment",
                                         iconImage: "ic_theater_green",
                                         defaultImage: "ic_theater_white",
                                         types: ["art_gallery","bowling_alley",
                                                "movie_theater","museum","spa","stadium","aquarium","casino"])
        
        let shopping = CateoryModel(name: "Shopping",
                                    iconImage: "ic_shopping_green",
                                    defaultImage: "ic_shopping_white",
                                    types: ["shopping_mall", "store"],
                                    typesRestricted: ["pharmacy", "hospital"])
        
        list.append(contentsOf: [food, outDoors, nightlife, fitness, entertainment, shopping])
        return list
    }
    
}


