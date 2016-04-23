//
//  OnTheMapTable.swift
//  On The Map
//
//  Created by TY on 4/3/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation
import UIKit

class OnTheMapTable: UITableViewController{
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var reloadStudentData: UIBarButtonItem!
    
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        view.backgroundColor = UIColor.grayColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        getStudentData()
    }
    
    @IBAction func reloadBtnPressed(sender: AnyObject) {
        getStudentData()
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
            
            guard error == nil else{
                self.showAlert("Woops!", alertMessage: "There was an error retrieving student table data", actionTitle: "Try Again")
                
                return
            }
            
            
            if !UserInformation.studentData.isEmpty{
                UserInformation.studentData.removeAll()
            }
            
            for s in result!{
                UserInformation.studentData.append(UserInformation(dictionary: s))
            }
            UserInformation.studentData = UserInformation.studentData.sort() {$0.updatedAt.compare($1.updatedAt) == NSComparisonResult.OrderedDescending}
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserInformation.studentData.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("studentDataCell")
        let student = UserInformation.studentData[indexPath.row]
        let titleText = student.firstName + " " + student.lastName
        
        cell?.textLabel?.text = titleText
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedUrl = UserInformation.studentData[indexPath.row]
        let userUrl = selectedUrl.mediaURL
        
        if userUrl.rangeOfString("http") != nil{
            UIApplication.sharedApplication().openURL(NSURL(string: "\(userUrl)")!)
        }else{
            showAlert("Invalid", alertMessage: "It looks like this link is invalid", actionTitle: "Try Another")
        }
    }
    
    func sessionLogOut(){
        OnTheMapClient.sharedInstance().deleteSession(UITabBarController!)
    }
    
    @IBAction func logOutAction(sender: AnyObject) {
        sessionLogOut()
    }
    
    
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}