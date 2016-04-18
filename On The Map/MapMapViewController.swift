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
    
    let cllocationManager: CLLocationManager = CLLocationManager()
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.cllocationManager.requestAlwaysAuthorization()
        self.cllocationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            cllocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            cllocationManager.startUpdatingLocation()
            self.mapView.showsUserLocation = true
    
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        getUserData()
        getStudentData()
    }
    
    func getUserData(){
        
        /* GET the users first and last name */
        OnTheMapClient.sharedInstance().getUserData(OnTheMapClient.sharedInstance().sessionID!) {(result, error) in
            
            guard error == nil else {
                let alertTitle = "Couldn't get your data"
                let alertMessage = "There was a problem trying to fetch your name and user ID."
                let actionTitle = "OK"
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.showAlert(alertTitle, alertMessage: alertMessage, actionTitle: actionTitle)
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
                return
            }
            /* Store the user resulting user data in the appDelegate */
            
            self.appDelegate.userData = result!
        }
    }
    
    func getStudentData(){
        
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.alpha = 0.8
        view.addSubview(activityView)
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = view.center
        activitySpinner.startAnimating()
        activityView.addSubview(activitySpinner)
        
        ParseClient.sharedInstance().getStudentLocations {(result, error) in
            

                dispatch_async(dispatch_get_main_queue(), {
                    activityView.removeFromSuperview()
                    activitySpinner.stopAnimating()
                    })

            if !UserInformation.studentData.isEmpty{
                UserInformation.studentData.removeAll()
            }
            
            for s in result! {
                UserInformation.studentData.append(UserInformation(dictionary: s))
            }
            
            UserInformation.studentData = UserInformation.studentData.sort() {$0.updatedAt.compare($1.updatedAt) == NSComparisonResult.OrderedDescending}
            
            dispatch_async(dispatch_get_main_queue(), {
                self.populateWithStudentData()
            })
        }
    }
    @IBAction func reloadStudentData(sender: AnyObject) {
        getStudentData()
    }
    
    func sessionLogOut(){
        
        OnTheMapClient.sharedInstance().deleteSession(tabBarController!)
    }
    
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
        for s in UserInformation.studentData {
            
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
            points.append(coordinate)
            
            let polyLine = MKPolyline(coordinates: UnsafeMutablePointer(points), count: points.count)
            
            mapView.delegate = self
            
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotations(annotations)
                self.mapView.showAnnotations(annotations, animated: true)
                self.mapView.addOverlay(polyLine)
            })
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {

            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            
            if #available(iOS 9.0, *) {
                pinView!.pinTintColor = UIColor.redColor()
            } else {
                // Fallback on earlier versions
            }
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView?.enabled = true
            
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer!{
    if overlay is MKPolyline {
    let polylineRenderer = MKPolylineRenderer(overlay: overlay)
    polylineRenderer.strokeColor = UIColor.blueColor()
    polylineRenderer.lineWidth = 1
    return polylineRenderer
    }
        return nil
    }
    
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
    
    
    @IBAction func overwriteInfoAction(sender: AnyObject) {
        showOverwriteLocationAlert()
    }
    
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
    
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    }