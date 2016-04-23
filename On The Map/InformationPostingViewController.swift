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

class InformationPostingViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, UISearchBarDelegate, LocateOnTheMap {
    
    @IBOutlet weak var googleMapsView: UIView!
    @IBOutlet weak var urlLinkField: UITextField!
    @IBOutlet weak var updateInfoBtn: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var searchPlacesBtn: UIButton!
    
    var mapViewController: MapMapViewController!
    
    var googleMaps: GMSMapView!
    var searchTableController: SearchTableController!
    var resultsArray = [String]()
    //Store latitude
    var userLat = [Double]()
    //Store longitue
    var userLong = [Double]()
    //Store string of selected address
    var addressString = [String]()
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
        self.googleMaps = GMSMapView(frame: self.googleMapsView.frame)
        self.view.addSubview(self.googleMaps)

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
        
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.alpha = 1
        view.addSubview(activityView)
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = view.center
        activitySpinner.startAnimating()
        activityView.addSubview(activitySpinner)
        
        //Prepare lat and long to be posted to the database
        self.userLat.append(lat)
        self.userLong.append(lon)
        
        dispatch_async(dispatch_get_main_queue(), {
            
            //Zoom to the coordinate loaded onto GMap
            let position = CLLocationCoordinate2DMake(lat, lon)
            let marker = GMSMarker(position: position)
            
            let camera = GMSCameraPosition.cameraWithLatitude(lat, longitude: lon, zoom: 15)
            self.googleMaps.camera = camera
            
            marker.title = "New Location: \(title)"
            marker.map = self.googleMaps
            
            self.urlLinkField.hidden = false
            self.urlLinkField.enabled = true
            self.statusLabel.text = "Add Profile URL"
            
            self.searchPlacesBtn.enabled = false
            self.searchPlacesBtn.hidden = true
            
            self.addressString.append(title)
            
            activityView.removeFromSuperview()
            activitySpinner.stopAnimating()
        })
    }
    
    //Set up the address searchBar
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String){
        
        let mapsClient = GMSPlacesClient()
        mapsClient.autocompleteQuery(searchText, bounds: nil, filter: nil) {(results, error: NSError?) in
            
            self.resultsArray.removeAll()
            
            if results == nil{
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
                    self.showAlert("Couldn't Update Info", alertMessage: "Error while trying to add your new data (post)", actionTitle: "Ok")
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
            
        }else{
            
            //There is an objectID available, upload new student data to Parse
            ParseClient.sharedInstance().putStudentLocationsConvenience(appDelegate.objectID, jsonBody: updatedStudentInfo) {(result, error) in
                
                guard error == nil else{
                    self.showAlert("Couldn't Update Info", alertMessage: "Unable to add your new data (put)", actionTitle: "Ok")
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
        }
        
        //Remove temporary values from arrays
        userLat.removeAll()
        userLong.removeAll()
    }
    
    //Function to show alert message for error checking
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
