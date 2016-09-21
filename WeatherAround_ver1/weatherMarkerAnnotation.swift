//
//  weatherMarkerAnnotation.swift
//  WeatherAround_ver1
//
//  Created by Yang Zhou on 2016-09-20.
//  Copyright © 2016 Yang Zhou. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

// 这里是重写了MKAnnotationView 类
// 具体操作见 http://stackoverflow.com/questions/33133864/swift-mapkit-add-extraattribut-to-annotation
//class WeatherMarkerAnnotation: MKAnnotationView{
//    
////    override init(frame: CGRect) {
////        super.init(frame: frame)
////        image = IconImage.getEmptyImage()
////        alpha = 0
////    }
//    var iconId: String?
//    
//    override init(annotation: MKAnnotation!, reuseIdentifier: String!) {
//        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
////        image = IconImage.getEmptyImage()
//        alpha = 0
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//}

//MKAnnotation is a protocol. Typically, you will create a NSObject subclass that implements this protocol. Instances of this custom class will then serve as your map annotation.
//
//MKPointAnnotation is a class that implements MKAnnotation. You can use it directly if you want your own business logic on the annotation.
class WeatherMarkerAnnotation: MKPointAnnotation {
    var iconId: String?
    var weather: String?
    var weatherDescription: String?
    var temperature: Double?
}
