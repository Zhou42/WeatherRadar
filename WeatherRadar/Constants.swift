//
//  Constants.swift
//  WeatherAround_ver1
//
//  Created by Yang Zhou on 2016-09-19.
//  Copyright © 2016 Yang Zhou. All rights reserved.
//

import Foundation

struct Constants {
    
    // MARK: WeatherMap
    struct WeatherMap {
        static let ApiScheme = "http"
        static let ApiHost = "api.openweathermap.org"
        static let ApiPath = "/data/2.5"
    }
    
    // MARK: WeatherMap Parameter Keys
    struct WeatherMapParameterKeys {
        static let APIKey = "appid"
        static let lat = "lat"
        static let lon = "lon"
        static let callback = "callback"
        static let cnt = "cnt" // number of cities returned
    }
    
    // MARK: TMDB Parameter Values
    struct WeatherMapParameterValues {
        static let ApiKey = "417af1d940df628f2943da80318f8f2c"
    }
    
    struct WeatherMapResponseKeys {
        static let StatusCode = "cod"
    }
}
