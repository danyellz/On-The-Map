//
//  ViewController.swift
//  On The Map
//
//  Created by TY on 3/25/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var userField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var loginPressed: UIButton!
    
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Unwrap optional AppDelegate to be used later
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    //Action button calls login function
    @IBAction func loginPressed(sender: AnyObject) {
        loginSession()
    }
    
    //Uses username and password and compares strings to userdata form Udacity
    func loginSession(){
        //Loading animation while data is fetched from the server
        let activityView = UIView.init(frame: view.frame)
        activityView.backgroundColor = UIColor.grayColor()
        activityView.alpha = 0.8
        self.view.addSubview(activityView)
        
        let activitySpinner = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activitySpinner.center = view.center
        activitySpinner.startAnimating()
        activityView.addSubview(activitySpinner)
        
        OnTheMapClient.sharedInstance().postSession(userField.text!, password: passField.text!) {(sessionID, error) in
            
            guard error == nil else{
                dispatch_async(dispatch_get_main_queue(),{
                    activityView.removeFromSuperview()
                    activitySpinner.stopAnimating()
                    self.showAlert("Woops", alertMessage: "There was an error connecting to the server, try new credentials or reconnect", actionTitle: "Try Again")
                })
                return
            }
            
            //If a session ID is present, remove animation
            if sessionID != nil{
                
                dispatch_async(dispatch_get_main_queue(), {
                    activityView.removeFromSuperview()
                    activitySpinner.stopAnimating()
                })
                //Store session ID in OnTheMapClient
                OnTheMapClient.sharedInstance().sessionID = sessionID
                //Instantiate the next view controller if login is successful
                self.completeLogin()
            } else {
                dispatch_async(dispatch_get_main_queue(),{
                    activityView.removeFromSuperview()
                    activitySpinner.stopAnimating()
                    self.showAlert("Woops", alertMessage: "There was an error connecting to the server, try new credentials or reconnect.", actionTitle: "Try Again")
                })
            }
        }
    }
    
    func completeLogin() {
        dispatch_async(dispatch_get_main_queue(), {
            
            performUIUpdatesOnMain {
                self.setUIEnabled(true)
                let controller = self.storyboard!.instantiateViewControllerWithIdentifier("OnTheMapViewController")
                self.presentViewController(controller, animated: true, completion: nil)
            }
        })
    }
}

//Enable UI once view loads successfully
extension ViewController {
    
    private func setUIEnabled(enabled: Bool) {
        userField.enabled = enabled
        passField.enabled = enabled
    }
    
    func showAlert(alertTitle: String, alertMessage: String, actionTitle: String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
