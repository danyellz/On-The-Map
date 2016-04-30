//
//  InformationPostingViewController.swift
//  On The Map
//
//  Created by TY on 4/8/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

//View to add updated user address and URL

import Foundation
import UIKit
import MapKit
import GoogleMaps

class InformationPostingViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, LocateOnTheMap {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var urlLinkField: UITextField!
    @IBOutlet weak var updateInfoBtn: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var searchPlacesBtn: UIButton!
    
    var mapViewController: MapMapViewController!
    var searchTableController: SearchTableController!
    var resultsArray = [String
        ]()
    //Store latitude
    var userLat = [Double]()
    //Store longitue
    var userLong = [Double]()
    //Store string of selected address
    var addressString = [String]()
    var studentDataModel: StudentDataModel!
    var appDelegate: AppDelegate!
    
    let cllocationManager: CLLocationManager = CLLocationManager()
    
    @IBAction func cancelPostAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.urlLinkField.hidden = true
        self.urlLinkField.enabled = false
        urlLinkField.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        //Load Google maps view
        super.viewDidAppear(true)
        self.mapView = MKMapView(frame: self.mapView.frame)
        self.view.addSubview(self.mapView)
        
        searchTableController = SearchTableController()
        searchTableController.delegate = self
    }
    
    @IBAction func searchPlacesBtn(sender: AnyObject) {
        //Instatniate autocomplete results table and searchBar input
        let searchController = UISearchController(searchResultsController: searchTableController)
        searchController.searchBar.delegate = self
        self.presentViewController(searchController, animated: true, completion: nil)
        
    }
    
    //Geocode address to be placed on Google map view
    func locateWithLongitude(lon: Double, andLatitude lat: Double, andTitle title: String) {
        
        //Prepare lat and long to be posted to the database
        self.userLat.append(lat)
        self.userLong.append(lon)
        
        dispatch_async(dispatch_get_main_queue(), {
            
            //Zoom to the coordinate loaded onto GMap
            /* Get the lat and lon values to create a coordinate */
            let lat = CLLocationDegrees(lat)
            let lon = CLLocationDegrees(lon)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            /* Make the map annotation with the coordinate and other student data */
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(title)"
            
            self.urlLinkField.hidden = false
            self.urlLinkField.enabled = true
            self.statusLabel.text = "Add Profile URL"
            
            self.searchPlacesBtn.enabled = false
            self.searchPlacesBtn.hidden = true
            
            self.addressString.append(title)
            
            let latDelta: CLLocationDegrees = 0.05
            let lonDelta: CLLocationDegrees = 0.05
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, lon)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            self.mapView.setRegion(region, animated: true)
            
            self.mapView.addAnnotation(annotation)
        })
    }
    
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
    
    
    //Set up the address searchBar
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String){
        
        let mapsClient = GMSPlacesClient()
        mapsClient.autocompleteQuery(searchText, bounds: nil, filter: nil) {(results, error: NSError?) in
            
            self.resultsArray.removeAll()
            
            if results == nil{
                self.showAlert("Woops", alertMessage: "You were unable to return any addresses. Try reconnecting", actionTitle: "Try Again")
                return
            }
            
            for result in results! {
                if let result = result as GMSAutocompletePrediction! {
                    self.resultsArray.append(result.attributedFullText.string)
                }
            }
            //When the character count of the searchBar changes, load new autocomplete results into the table
            self.searchTableController.reloadDataWithArray(self.resultsArray)
        }
    }
    
    //Remove keyboard when return is pressed
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    @IBAction func updateUserInfo(sender: UIButton) {
        
        //Make sure valid address and URL are added to text fields
        guard urlLinkField.text! != "" else{
            showAlert("Missing URL", alertMessage: "Please input a URL", actionTitle: "Ok")
            return
        }
        
        guard UIApplication.sharedApplication().canOpenURL(NSURL(string: urlLinkField.text!)!) else{
            showAlert("Invalid URL", alertMessage: "The website you added is invalid-recheck format (http:// etc)", actionTitle: "Ok")
            return
        }
        
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.alpha = 0.8
        view.addSubview(activityView)
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = view.center
        activitySpinner.startAnimating()
        activityView.addSubview(activitySpinner)
        
        //Prepare data to be posted (notice how I used the lat/long arrays here)
        let updatedStudentInfo : [String: AnyObject] = [
            ParseClient.JSONBodyKeys.UniqueKey: OnTheMapClient.sharedInstance().sessionID!,
            ParseClient.JSONBodyKeys.FirstName: appDelegate.userData[0],
            ParseClient.JSONBodyKeys.LastName: appDelegate.userData[1],
            ParseClient.JSONBodyKeys.MapString: addressString[0],
            ParseClient.JSONBodyKeys.MediaURL: urlLinkField.text!,
            ParseClient.JSONBodyKeys.Latitude: userLat[0],
            ParseClient.JSONBodyKeys.Longitude: userLong[0]
        ]
        
        print(updatedStudentInfo)
        
        //There is no objectID in use, post the new student information
        if appDelegate.objectID == "" {
            
            ParseClient.sharedInstance().postStudentLocationsConvenience(updatedStudentInfo) {(result, error) in
                
                guard error == nil else{
                    dispatch_async(dispatch_get_main_queue(), {
                        activityView.removeFromSuperview()
                        activitySpinner.stopAnimating()
                        self.showAlert("Couldn't Update Info", alertMessage: "There was an error with your request. Try reconnecting", actionTitle: "Ok")
                    })
                    return
                }
                
                //Remove temporary values from arrays
                self.userLat.removeAll()
                self.userLong.removeAll()
                
                
                dispatch_async(dispatch_get_main_queue(),{
                    activityView.removeFromSuperview()
                    activitySpinner.stopAnimating()
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
                
            }
        }else{
            
            //There is an objectID available, upload new student data to Parse
            ParseClient.sharedInstance().putStudentLocationsConvenience(appDelegate.objectID, jsonBody: updatedStudentInfo) {(result, error) in
                
                guard error == nil else{
                    dispatch_async(dispatch_get_main_queue(), {
                        activityView.removeFromSuperview()
                        activitySpinner.stopAnimating()
                        self.showAlert("Couldn't Update Info", alertMessage: "There was an error with your request. Try reconnecting", actionTitle: "Ok")
                    })
                    return
                }
                
                //Remove temporary values from arrays
                self.userLat.removeAll()
                self.userLong.removeAll()
                
                dispatch_async(dispatch_get_main_queue(),{
                    activityView.removeFromSuperview()
                    activitySpinner.stopAnimating()
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
                
            }
        }
    }
    
    //Function to show alert message for error checking
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
