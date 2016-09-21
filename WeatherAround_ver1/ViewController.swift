//
//  ViewController.swift
//  WeatherAround_ver1
//
//  Created by Yang Zhou on 2016-09-18.
//  Copyright © 2016 Yang Zhou. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    // 这里必须IBOutlet链接上了，才能初始化mainMapView，否则 不显示
    @IBOutlet weak var mainMapView: MKMapView!

    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    var appDelegate: AppDelegate!
    // 用来存天气的dictionary: [cityname:iconId]
    var weatherDict: [String:String] = [:]
    
    // location manager, for locating
    var locationManager:CLLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // standard map type
        self.mainMapView.mapType = MKMapType.standard
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        // MKCoordinateSpan instance, for accuracy
        let latDelta = 0.05
        let longDelta = 0.05
        
        //
        if CLLocationManager.authorizationStatus() == .notDetermined {
            self.locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .denied {
            showAlert("Location services were previously denied. Please enable location services for this app in Settings.")
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        // setup locationManager
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation() // curt location, get once
        
        
        // setup mapView
        mainMapView.delegate = self
        mainMapView.showsUserLocation = true
        mainMapView.userTrackingMode = .followWithHeading
        
        // centre the view to curt location
        let currentLocationSpan:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
        // initial display location
//
        if let center = locationManager.location?.coordinate {
            let currentRegion:MKCoordinateRegion = MKCoordinateRegion(center: center,
                                                                      span: currentLocationSpan)
            self.mainMapView.setRegion(currentRegion, animated: true)
        } else {
            let location:CLLocation = CLLocation(latitude: 49.25056, longitude: -123.111944)
            let currentRegion:MKCoordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                                      span: currentLocationSpan)
            self.mainMapView.setRegion(currentRegion, animated: true)
        }
        
        
        // for search
        // use the Storyboard ID, instantiate the locationSearchTable programmatically
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        // configures the search bar, and embeds it within the navigation bar
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = self.mainMapView
        
        locationSearchTable.handleMapSearchDelegate = self
        
        // setup a WeatherDetailsViewController
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // let userLocation:CLLocation = locations[0]
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func showAlert(_ alert: String) {
        let alertController = UIAlertController(title: "iOScreator", message:
            alert, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    

    func getDirections(){
        // 这里只对selected pin起作用！！selectedPin 是个全局变量 用来cache pin的
        print("Get directions!")
        if let selectedPin = selectedPin {
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    
    // MARK: - MKMapViewDelegate
    // apple官网资料
    // https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/LocationAwarenessPG/AnnotatingMaps/AnnotatingMaps.html
    // customize drop pin
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
//        if annotation is MKUserLocation {
//            //return nil so map view draws "blue dot" for standard user location
//            return nil
//        }
//        let reuseId = "pin"
//        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
//        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//        pinView?.pinTintColor = UIColor.orange
//        pinView?.canShowCallout = true
//        let smallSquare = CGSize(width: 30, height: 30)
//        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
//        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
////        button.addTarget(self, action: #selector(ViewController.getDirections), for: .touchUpInside)
//        pinView?.leftCalloutAccessoryView = button
//        return pinView
//    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        print("=============== annotation view=================")
        print(annotation.coordinate)
        
        if isSelectePin(annotation) {
            
            print("========Search \(annotation.title!!)=============")
            // if the pin is the searched one
            // 使用城市名 作为id / 但是有重名问题，需要加入一些其余的string
            // reuseId 要格外注意 因为如果这里与下面另外的情况有重复，则显示混乱
            let reuseId = annotation.title!!
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
//            let pinView = MKPinAnnotationView()
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            pinView!.pinTintColor = UIColor.orange
            pinView!.canShowCallout = true
            let smallSquare = CGSize(width: 30, height: 30)
            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
            button.setBackgroundImage(UIImage(named: "car"), for: .normal)
            button.addTarget(self, action: #selector(ViewController.getDirections), for: .touchUpInside)
            pinView!.leftCalloutAccessoryView = button
            return pinView
            
        } else {
            // the pin is for weather display
            guard let WeatherAnnotation = annotation as? WeatherMarkerAnnotation else {
                return nil
            }
            let reuseId = "\(WeatherAnnotation.title!)\(WeatherAnnotation.iconId)"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if pinView == nil {
                pinView = MKAnnotationView(annotation: WeatherAnnotation, reuseIdentifier: reuseId)
                // update Weather Icons
                self.updateWeatherIconId(WeatherAnnotation, pinView: pinView!)
//                pinView?.image = getIconById(id: iconId) // UIImage(named:imageName)
                pinView?.canShowCallout = true
                pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            else {
                //we are re-using a view, update its annotation reference...
                // need to update the view too
                pinView?.annotation = WeatherAnnotation
                self.updateWeatherIconId(WeatherAnnotation, pinView: pinView!)
            }
            return pinView
        }
        
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    // 这里把url写在subtitle中
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let weatherAnnotation = view.annotation as? WeatherMarkerAnnotation else {
            return
        }
        
        // 这里要判断 是search pin， 还是weather点击; 有temp的是weather，没有的是pin
        if self.isSelectePin(weatherAnnotation) {
            // 如果是search的pin 则不要做什么，调用 getDirections()
            return
        } else {
            // print(weatherAnnotation.weatherDescription)
            // weatherController没法定义在整个这个class中，会报错
            let weatherController: WeatherDetailsViewController
            // 使用storyboard调用controller 必须要在controller identity中 填写storyboard id, 然后使用storyboard id调用
            weatherController = self.storyboard?.instantiateViewController(withIdentifier: "WeatherDetailsViewController") as! WeatherDetailsViewController
            weatherController.cityName = weatherAnnotation.title
            weatherController.temp = weatherAnnotation.temperature
            weatherController.backgroundId = "\(weatherAnnotation.iconId!)-1"
            weatherController.iconId = weatherAnnotation.iconId
            // print("============== \(weatherController.backgroundId)===================")
            self.present(weatherController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        
    }
    
    
    
    
    
    // ============ 自己的design ===============
    // 给一个坐标，地图上显示周围的天气
    func displayWeatherAround(_ location:CLLocationCoordinate2D) {
        // 获取周围城市id 和天气
        let methodParameters = [Constants.WeatherMapParameterKeys.APIKey:Constants.WeatherMapParameterValues.ApiKey as AnyObject, Constants.WeatherMapParameterKeys.lat:location.latitude as AnyObject, Constants.WeatherMapParameterKeys.lon:location.longitude as AnyObject, Constants.WeatherMapParameterKeys.cnt:20 as AnyObject] as [String: AnyObject]
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(url: appDelegate.weatherMapURLFromParameters(parameters: methodParameters, withPathExtension: "/find") as URL)
        
        /* 4. Make the request */
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            
            /* 5. Parse the data */
            /* 6. Use the data! */
//            print("============ start ========")
            guard (error == nil) else {
                print("getRequestToken error, error = nil")
                return
            }
            /* 5. Parse the data */
            guard let data = data else {
                print("getRequestToken error, data = data")
                return
            }
            
            let parsedResult: AnyObject!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            } catch {
                print("getRequestToken error, parsedResult")
                return
            }
//            print(parsedResult["list"])
            guard let list = parsedResult["list"] as? [AnyObject] else {
                print("Getting cityList failed")
                return
            }
            
            // clear existing pins 似乎不需要清除这些pin
            // 当search的时候，第一件事就是clear了所有pin
            // 当返回自己位置的时候，也会clear所有pin
            // 所以这里不需要 否则会错误删除pin
            // self.mainMapView.removeAnnotations(self.mainMapView.annotations)
            // loop through the nearest cities, for each city, display the weather on the map
            // var annotations = [MKPointAnnotation]()
            // 这里使用自定义的WeatherMarkerAnnotation，包含天气等信息
//            var annotations = [WeatherMarkerAnnotation]()
            
            // 其实这里的city中已经包含了天气信息！！
            for city in list {
                //                let annotation = MKPointAnnotation()
                let annotation = WeatherMarkerAnnotation()
                
                
                // get coord
                guard let coord_temp = city["coord"], let coord = coord_temp as? [String:AnyObject] else {
                    continue
                }
                guard let lat = coord["lat"] as? Double, let lon = coord["lon"] as? Double else {
                    continue
                }
                // print("lat is \(lat), long is \(lon)")
                guard let cityName = city["name"] as? String else {
                    continue
                }
                
//                // get temperature
//                guard let main_temp = city["main"], let main = main_temp as? [String:AnyObject] else {
//                    continue
//                }
//                guard let temperature = main["temp"] as? Double else {
//                    continue
//                }
//                
//                // get wheather icon id
//                guard let weather_temp1 = city["weather"] else {
//                    print("Getting weather_temp1 failed")
//                    return
//                }
//                guard let weather_temp2 = weather_temp1 as? NSArray else {
//                    print("Getting weather_temp2 failed")
//                    return
//                }
//                guard let weather = weather_temp2[0] as? [String:AnyObject] else {
//                    print("Getting weather failed")
//                    return
//                }
//                
//                guard let icon = weather["icon"] as? String else {
//                    print("Getting icon failed")
//                    return
//                }
//                guard let weather_main = weather["main"] as? String else {
//                    print("Getting weather_main failed")
//                    return
//                }
//                guard let description = weather["description"] as? String else {
//                    print("Getting description failed")
//                    return
//                }
                
                annotation.coordinate = CLLocation(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon)).coordinate
                annotation.title = cityName
//                annotation.subtitle = description
//                annotation.iconId = icon
////                annotation.weather = weather_main
//                annotation.weatherDescription = description
//                annotation.temperature = temperature
                
//                // 更新UI
//                self.mainMapView.addAnnotation(annotation)
                // 如果是cached pin (或附近)，就不要覆盖
                
                if self.isSelectePin(annotation) {
                    continue
                }
                
                performUIUpdatesOnMain {
                    self.mainMapView.addAnnotation(annotation)
                }
//                annotations.append(annotation)
            }
            // 这里循环太多 循环体太大，导致UI卡住
//            performUIUpdatesOnMain {
//                self.mainMapView.addAnnotations(annotations)
//            }
            /* 6. Use the data! */
            
        }
        
        /* 7. Start the request */
        task.resume()

    }
    
    // 右下角圆按钮，回到当前界面。显示周围天气
    @IBAction func switchToUserCurtRegion(_ sender: AnyObject) {
        locationManager.requestLocation() // curt location, get once
        // remove all pins
        performUIUpdatesOnMain {
            self.mainMapView.removeAnnotations(self.mainMapView.annotations)
        }
        // centre the view to curt location
        let latDelta = 0.05
        let longDelta = 0.05
        let currentLocationSpan:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
        // initial display location
        if let center = locationManager.location?.coordinate {
            let currentRegion:MKCoordinateRegion = MKCoordinateRegion(center: center,
                                                                      span: currentLocationSpan)
            self.mainMapView.setRegion(currentRegion, animated: true)
            displayWeatherAround(center)
        }
    }
    
    func getIconById(id: String) -> UIImage{
        //定义NSURL对象
        let url = NSURL(string: "http://openweathermap.org/img/w/\(id).png")
        //从网络获取数据流
        let data = NSData(contentsOf: url! as URL)
        //通过数据流初始化图片
        if let data_unwrapped = data {
            return UIImage(data: data_unwrapped as Data)!
        } else {
            return UIImage(named: "50d")!
        }
    }
    
    
    // 显示某annotation周围天气
    // MKAnnotation 这里是protocol只要符合这个协议的 都可以传入
    func updateWeatherIconId(_ annotation: MKAnnotation, pinView:MKAnnotationView) {
        
        if let WeatherAnnotation = annotation as? WeatherMarkerAnnotation, let id = WeatherAnnotation.iconId {
            // 如果可以得到天气信息 则不需要再用API
            pinView.image = self.getIconById(id: id)
        } else {
            // 如果得不到 则重新API 查询
            guard let weatherAnnotation = annotation as? WeatherMarkerAnnotation else {
                return
            }
            
            let lat = weatherAnnotation.coordinate.latitude, lon = weatherAnnotation.coordinate.longitude;
            
            let methodParameters = [Constants.WeatherMapParameterKeys.APIKey:Constants.WeatherMapParameterValues.ApiKey as AnyObject, Constants.WeatherMapParameterKeys.lat:lat as AnyObject, Constants.WeatherMapParameterKeys.lon:lon as AnyObject] as [String: AnyObject]
            // print(methodParameters)
            //         print(appDelegate.weatherMapURLFromParameters(parameters: methodParameters, withPathExtension: "/weather") as URL)
            /* 2/3. Build the URL, Configure the request */
            let request = NSURLRequest(url: appDelegate.weatherMapURLFromParameters(parameters: methodParameters, withPathExtension: "/weather") as URL)
            
            /* 4. Make the request */
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                
                /* 5. Parse the data */
                /* 6. Use the data! */
                //            print("============ start ========")
                guard (error == nil) else {
                    print("getRequestToken error, error = nil")
                    return
                }
                /* 5. Parse the data */
                guard let data = data else {
                    print("getRequestToken error, data = data")
                    return
                }
                
                let parsedResult: AnyObject!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
                } catch {
                    print("getRequestToken error, parsedResult")
                    return
                }
                //            print(parsedResult["list"])
                guard let weather_temp1 = parsedResult["weather"] else {
                    print("Getting weather_temp1 failed")
                    return
                }
                guard let weather_temp2 = weather_temp1 as? NSArray else {
                    print("Getting weather_temp2 failed")
                    return
                }
                guard let weather = weather_temp2[0] as? [String:AnyObject] else {
                    print("Getting weather failed")
                    return
                }
                
                guard let icon = weather["icon"] as? String else {
                    print("Getting icon failed")
                    return
                }
                
                // get temperature
                guard let main_temp = parsedResult["main"], let main = main_temp as? [String:AnyObject] else {
                    return
                }
                guard let temperature = main["temp"] as? Double else {
                    return
                }
                // main description of weather
                guard let weather_main = weather["main"] as? String else {
                    print("Getting weather_main failed")
                    return
                }
                guard let description = weather["description"] as? String else {
                    print("Getting description failed")
                    return
                }
                
                
                
                
                weatherAnnotation.subtitle = description
                weatherAnnotation.iconId = icon
                weatherAnnotation.weather = weather_main
                weatherAnnotation.weatherDescription = description
                weatherAnnotation.temperature = temperature
                
                
                
                
                pinView.image = self.getIconById(id: icon)
                
                
            }
            /* 7. Start the request */
            task.resume()
        }
        
        // 由于task.resume() 之后马上执行，所以此时weatherIcon 还是"" 就返回了
//        if (weatherIcon == "") {
//            print("==========weatherIcon Error!!!!============")
//        }
    }
    
    func isSelectePin(_ annotation: MKAnnotation) -> Bool {
        let epsilon = 0.001
        if let selectedPin = selectedPin, fabs(annotation.coordinate.latitude - selectedPin.coordinate.latitude) < epsilon && fabs(annotation.coordinate.longitude - selectedPin.coordinate.longitude) < epsilon {
            return true
        } else {
            return false
        }
    }
    
    
}




extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        print("============selectedPin updated===============")
        print(placemark.coordinate)
        selectedPin = placemark
        // clear existing pins
        performUIUpdatesOnMain {
            self.mainMapView.removeAnnotations(self.mainMapView.annotations)
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        // 这里必须用performUIUpdatesOnMain！！！！ 否则这里是asyn的，也就是addAnnotation 直接返回到下一条命令。导致pin迟迟(根本就不出现)。。。所以update UI的 一定放在performUIUpdatesOnMain 里
        performUIUpdatesOnMain {
            self.mainMapView.addAnnotation(annotation)
        }
        print("============selectedPin added===============")
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mainMapView.setRegion(region, animated: true)
        
        // display weather around this pin
         self.displayWeatherAround(placemark.coordinate)
    }
}
