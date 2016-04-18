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
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func loginPressed(sender: AnyObject) {
        
        loginSession()
    }
    
    func loginSession(){
        
        OnTheMapClient.sharedInstance().postSession(userField.text!, password: passField.text!) {(sessionID, error) in
            
            let activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            activityView.center = self.view.center
            activityView.startAnimating()
            self.view.addSubview(activityView)
            
            if let sessionID = sessionID {
                
                dispatch_async(dispatch_get_main_queue(), {
                    activityView.stopAnimating()
                    activityView.removeFromSuperview()
                    })
                
                OnTheMapClient.sharedInstance().sessionID = sessionID
                self.completeLogin()
            } else {
                //ERROR: WRONG USERNAME/PW
                print ("Error, wrong username")
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

extension ViewController {
    
    private func setUIEnabled(enabled: Bool) {
        userField.enabled = enabled
        passField.enabled = enabled
    }
}
