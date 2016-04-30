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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.grayColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        //Fetch student names on load
        getStudentData()
    }
    
    @IBAction func reloadBtnPressed(sender: AnyObject) {
        getStudentData()
    }
    
    //Query student data to be loaded into the table
    func getStudentData(){
        
        //Begin animation
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.alpha = 0.8
        view.addSubview(activityView)
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = view.center
        activitySpinner.startAnimating()
        activityView.addSubview(activitySpinner)
        
        
        ParseClient.sharedInstance().getStudentLocations {(result, error) in
            
            //End animation once getStudentLocaions method is called
            dispatch_async(dispatch_get_main_queue(), {
                activityView.removeFromSuperview()
                activitySpinner.stopAnimating()
            })
            
            //Show alert message if an error becomes apparent
            guard error == nil else{
                self.showAlert("Woops!", alertMessage: "There was an error retrieving student table data", actionTitle: "Try Again")
                return
            }
            
            //If there is data currently loaded into the table, remove all previous data
            if !StudentDataModel.studentData.isEmpty{
                StudentDataModel.studentData.removeAll()
            }
            
            //Add new data to the student data struct, replacing removed data
            for s in result!{
                StudentDataModel.studentData.append(UserInformation(dictionary: s))
            }
            //Load student data from latest to oldest when querying from Parse
            StudentDataModel.studentData = StudentDataModel.studentData.sort() {$0.updatedAt.compare($1.updatedAt) == NSComparisonResult.OrderedDescending}
        }
        
    }
    
    //Determine the number of rows loaded onto the tableview
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentDataModel.studentData.count
    }
    
    //When a cell is selected, go to the student URL
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("studentDataCell")
        let student = StudentDataModel.studentData[indexPath.row]
        let titleText = student.firstName + " " + student.lastName
        
        cell?.textLabel?.text = titleText
        
        return cell!
    }
    
    //When a cell is selected, go to the student URL
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedUrl = StudentDataModel.studentData[indexPath.row]
        let userUrl = selectedUrl.mediaURL
        
        if userUrl.rangeOfString("http") != nil{
            UIApplication.sharedApplication().openURL(NSURL(string: "\(userUrl)")!)
        }else{
            showAlert("Invalid", alertMessage: "It looks like this link is invalid", actionTitle: "Try Another")
        }
    }
    
    //Logout method from client
    func sessionLogOut(){
        OnTheMapClient.sharedInstance().deleteSession(tabBarController!)
    }
    
    @IBAction func logOutAction(sender: AnyObject) {
        sessionLogOut()
    }
    
    //Alert message for easy error checking
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}