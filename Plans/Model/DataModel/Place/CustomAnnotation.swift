//
//  CustomAnnotation.swift
//  FACS
//
//  Created by Star  on 1/09/21.
//  Copyright © 2021 Plans Collective. All rights reserved.
//

import UIKit
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var imageName = String()
    var tag: Int?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, imageName: String, _ tag: Int = 0) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.imageName = ""
        self.imageName = imageName
        self.tag = tag
    }
    
    func annotationView() -> MKAnnotationView {
        let view = MKAnnotationView(annotation: self, reuseIdentifier: CustomAnnotation.className)
        view.isEnabled = true
        view.canShowCallout = true
        view.image = UIImage(named: imageName)
        return view
    }
        
}

