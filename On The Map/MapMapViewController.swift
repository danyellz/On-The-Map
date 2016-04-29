//
//  MapMapViewController.swift
//  On The Map
//
//  Created by TY on 3/29/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

class MapMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var appDelegate: AppDelegate!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var logOut: UIBarButtonItem!
    @IBOutlet weak var reloadStudentData: UIBarButtonItem!
    @IBOutlet weak var overwriteInfo: UIBarButtonItem!
    @IBOutlet weak var studentCountLabel: UILabel!
    
    let cllocationManager: CLLocationManager = CLLocationManager()
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.cllocationManager.requestAlwaysAuthorization()
        self.cllocationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            cllocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            cllocationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
            
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        getUserData()
        getStudentData()
    }
    
    func getUserData(){
        
        /* GET the users Parse data with their Udacity login session token*/
        OnTheMapClient.sharedInstance().getUserData(OnTheMapClient.sharedInstance().sessionID!) {(result, error) in
            
            guard error == nil else {
                self.showAlert("Woops!", alertMessage: "There was an error with your request. Try reconnecting to the network.", actionTitle: "Try Again")
                return
            }
            /* Store the user resulting user data in the appDelegate */
            
            self.appDelegate.userData = result!
        }
    }
    
    func getStudentData(){
        
        /*Start spinner when data is being retrieved from the server*/
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.alpha = 0.8
        view.addSubview(activityView)
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = view.center
        activitySpinner.startAnimating()
        activityView.addSubview(activitySpinner)
        
        /*Call getStudentLocations from ParseClient.swift*/
        ParseClient.sharedInstance().getStudentLocations {(result, error) in
            
            dispatch_async(dispatch_get_main_queue(), {
                activityView.removeFromSuperview()
                activitySpinner.stopAnimating()
            })
            
            guard error == nil else{
                self.showAlert("Woops!", alertMessage: "There was an issue fetching student data", actionTitle: "Try Again")
                return
            }
            
            /*If studentData array in data model is not empty, remove all previous data to prepare view*/
            if !AppDelegate.studentData.isEmpty{
                AppDelegate.studentData.removeAll()
            }
            
            /*Unwrap the optional result or the userinformation loaded from Parse*/
            /*Add all Udacity user's data from parse into local data model*/
            for s in result! {
                AppDelegate.studentData.append(UserInformation(dictionary: s))
            }
            
            /*Query the student data from most recent to latest, to be used on the map*/
            AppDelegate.studentData = AppDelegate.studentData.sort() {$0.updatedAt.compare($1.updatedAt) == NSComparisonResult.OrderedDescending}
            
            /*Add student data to the map*/
            dispatch_async(dispatch_get_main_queue(), {
                self.populateWithStudentData()
            })
        }
    }
    
    /*Button to reload map data*/
    @IBAction func reloadStudentData(sender: AnyObject) {
        getStudentData()
    }
    
    /*Logout function*/
    func sessionLogOut(){
        OnTheMapClient.sharedInstance().deleteSession(tabBarController!)
    }
    
    /*Logout button action*/
    @IBAction func logoutBtnPressed(sender: AnyObject) {
        print("Logout pressed!")
        sessionLogOut()
    }
    
    func populateWithStudentData(){
        
        /* Remove any pins previously on the map to avoid duplicates */
        if !mapView.annotations.isEmpty{
            mapView.removeAnnotations(mapView.annotations)
        }
        
        var annotations = [MKPointAnnotation]()
        var points = [CLLocationCoordinate2D]()
        
        /* For each student in the data */
        for s in AppDelegate.studentData {
            
            self.cllocationManager.delegate = self
            
            /* Get the lat and lon values to create a coordinate */
            let lat = CLLocationDegrees(s.latitude)
            let lon = CLLocationDegrees(s.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            /* Make the map annotation with the coordinate and other student data */
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(s.firstName) \(s.lastName)"
            annotation.subtitle = s.mediaURL
            
            /* Add the annotation to the array */
            annotations.append(annotation)
            /*Append cllocations to represent overlay connections between annotations*/
            points.append(coordinate)
            
            /*Adds a line to between user coordinates *experimental*/
            mapView.delegate = self
            
            /*Load annotations/overlay to map view once data is completely loaded*/
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotations(annotations)
                self.mapView.showAnnotations(annotations, animated: true)
                self.studentCountLabel.text = "Student Count:" + String(points.count)
            })
        }
    }
    
    /*Delegate how annotations are displayed in the view*/
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            if #available(iOS 9.0, *) {
                pinView!.pinTintColor = UIColor.greenColor()
            }else {
                // Fallback on earlier versions
            }
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView?.enabled = true
            
        }else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    /*Delegate annotation views as well as control to access URL links*/
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView{
            
            view.layer.cornerRadius = 0.5
            view.backgroundColor = UIColor.grayColor()
            
            let linkUrl = view.annotation!.subtitle!
            if linkUrl!.rangeOfString("http") != nil{
                if let link = view.annotation?.subtitle!{
                    UIApplication.sharedApplication().openURL(NSURL(string: "\(link)")!)
                }
            }else{
                dispatch_async(dispatch_get_main_queue(),{
                    self.showAlert("Invalid", alertMessage: "This link is invalid", actionTitle: "Try Another")
                })
            }
        }
    }
    
    /*Update current user location coordinates*/
    var isInitialized = false
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !isInitialized {
            // Here is called only once
            isInitialized = true
            locations[0]
            let userLoction: CLLocation = locations[0]
            let latitude = userLoction.coordinate.latitude
            let longitude = userLoction.coordinate.longitude
            let latDelta: CLLocationDegrees = 0.095
            let lonDelta: CLLocationDegrees = 0.095
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            self.mapView.setRegion(region, animated: true)
            self.mapView.showsUserLocation = true
        }
    }
    
    /*Instantiate action to add updated new user data*/
    @IBAction func overwriteInfoAction(sender: AnyObject) {
        showOverwriteLocationAlert()
    }
    
    /*Alert message confirming overwrite/transition to new view*/
    func showOverwriteLocationAlert(){
        /* Prepare the strings for the alert */
        let userFirstName = self.appDelegate.userData[0]
        let alertTitle = "Overwrite location?"
        let alertMessage = userFirstName + " do you really want to overwrite your existing information?"
        
        /* Prepare to overwrite for the alert */
        let overWriteAction = UIAlertAction(title: "Overwrite", style: .Default) {(action) in
            /* instantiate and then present the view controller */
            let informationPostingViewController = self.storyboard!.instantiateViewControllerWithIdentifier("InformationPostingViewController")
            self.presentViewController(informationPostingViewController, animated: true, completion: nil)
        }
        
        /* Prepare the cancel for the alert */
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {(action) in
            
        }
        
        /* Configure the alert view to display the error */
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(overWriteAction)
        alert.addAction(cancelAction)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
    
    /*Alert used for debugging throughout file*/
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}