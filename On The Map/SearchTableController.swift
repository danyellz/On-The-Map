//
//  SearchTableController.swift
//  On The Map
//
//  Created by TY on 4/11/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

//Custom table created to store autocomplete results from Google Places

import Foundation
import UIKit

//protocol to contain coordinates from selected row in Google maps autocomplete table
protocol LocateOnTheMap{
    func locateWithLongitude(lon:Double, andLatitude lat:Double, andTitle title: String)
}

class SearchTableController: UITableViewController {
    var searchResults: [String]!
    var delegate: LocateOnTheMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchResults = Array()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cellIdentifier")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier", forIndexPath: indexPath)
        cell.textLabel?.text = self.searchResults[indexPath.row]
        return cell
    }
    
    
    //When table cell is selected, prepare annotation for the GMaps view
    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let correctedAddress:String! = self.searchResults[indexPath.row].stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.symbolCharacterSet())
        let url = NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(correctedAddress)&sensor=false")
        
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.layer.opacity = 0.8
        view.addSubview(activityView)
        
        let activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        activityView.addSubview(activityIndicator)
        
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) { (data, response, error) -> Void in
            
            activityView.removeFromSuperview()
            activityIndicator.stopAnimating()
            
            guard error == nil else{
                dispatch_async(dispatch_get_main_queue(), {
                    self.showAlertMessage("There was an issue geocoding your address!")
                })
                activityView.removeFromSuperview()
                activityIndicator.stopAnimating()
                print("There was an issue geocoding your address!")
                return
            }
            // 3
            do {
                if data != nil{
                    let dic = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves) as! NSDictionary
                    
                    let lat = dic["results"]?.valueForKey("geometry")?.valueForKey("location")?.valueForKey("lat")?.objectAtIndex(0) as! Double
                    let lon = dic["results"]?.valueForKey("geometry")?.valueForKey("location")?.valueForKey("lng")?.objectAtIndex(0) as! Double
                    // 4
                    self.delegate.locateWithLongitude(lon, andLatitude: lat, andTitle: self.searchResults[indexPath.row])
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                
            }catch {
                print("There was an error geocoding the address")
            }
        }
        // 5
        task.resume()
    }
    //Update data in the tableView
    func reloadDataWithArray(array:[String]){
        self.searchResults = array
        self.tableView.reloadData()
    }
    
    func showAlertMessage(message: String){
        let alertController = UIAlertController(title: "Woops", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let closeAlertAction  = UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel) {(alertAction) -> Void in
        }
        alertController.addAction(closeAlertAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
}

