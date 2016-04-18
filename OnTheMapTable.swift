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
        
        let loadSpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        loadSpinner.center = view.center
        loadSpinner.startAnimating()
        view.addSubview(loadSpinner)
        
        ParseClient.sharedInstance().getStudentLocations {(result, error) in
            
            
            if !UserInformation.studentData.isEmpty{
                UserInformation.studentData.removeAll()
            }
            
            for s in result!{
                UserInformation.studentData.append(UserInformation(dictionary: s))
            }
                UserInformation.studentData = UserInformation.studentData.sort() {$0.updatedAt.compare($1.updatedAt) == NSComparisonResult.OrderedDescending}
                
                dispatch_async(dispatch_get_main_queue(), {
                    loadSpinner.stopAnimating()
                    self.tableView.reloadData()
                })
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
}