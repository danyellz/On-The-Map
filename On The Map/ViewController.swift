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
        OnTheMapClient.sharedInstance().postSession(userField.text!, password: passField.text!) {(sessionID, error) in
            
            //Loading animation while data is fetched from the server
            let activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            activityView.center = self.view.center
            activityView.startAnimating()
            self.view.addSubview(activityView)
            
            //If a session ID is present, remove animation
            if let sessionID = sessionID {
                
                dispatch_async(dispatch_get_main_queue(), {
                    activityView.stopAnimating()
                    activityView.removeFromSuperview()
                    })
                //Store session ID in OnTheMapClient
                OnTheMapClient.sharedInstance().sessionID = sessionID
                //Instantiate the next view controller if login is successful
                self.completeLogin()
            } else {
                self.showAlert("Woops", alertMessage: "There was an error connecting to the server, try new credentials or reconnect", actionTitle: "Try Again")
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
}
