//
//  WeatherDetailsViewController.swift
//  WeatherAround_ver1
//
//  Created by Yang Zhou on 2016-09-20.
//  Copyright © 2016 Yang Zhou. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class WeatherDetailsViewController: UIViewController {
    //
    
    @IBOutlet weak var cityNameLabel: UILabel!
    
//    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var tempLabel: UILabel!
    
    
    @IBOutlet weak var Icon: UIImageView!
    
    var cityName: String?
    var backgroundId: String?
    var iconId: String?
    var temp: Double?
    
    override func viewDidLoad() {
        cityNameLabel.text = cityName
        tempLabel.text = "\(Int(temp! - 273.15))\u{00B0}C"
//        backgroundImage.image = UIImage(named: backgroundId!)
        Icon.image = UIImage(named: iconId!)
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: backgroundId!)!)
    }
}
