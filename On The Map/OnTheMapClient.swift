//
//  OnTheMapClient.swift
//  On The Map
//
//  Created by TY on 3/25/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation

class OnTheMapClient : NSObject{
    
    // MARK: Properties
    
    // shared session
    var session: NSURLSession
    
    // authentication state
    var requestToken: String? = nil
    var sessionID: String? = nil
    var userID: Int? = nil
    
    // MARK: Initializers
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func taskForGetMethod(method: String, completionHandler:(result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* Build and configure GET request */
        let urlString = Constants.UdacityBaseUrl + method
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        
        /* Make the request */
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            
            /* GUARD: Was there an error */
            guard error == nil else {
                let userInfo = [NSLocalizedDescriptionKey: "There was an error with your request: \(error)"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    let userInfo = [NSLocalizedDescriptionKey: "Your Request returned an invalid respons! Status code: \(response.statusCode)!"]
                    completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                } else if let response = response {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response! Response: \(response)!"]
                    completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                } else {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response!"]
                    completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request!"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            /* Parse and use data */
            let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
            OnTheMapClient.convertDataWithCompletionHandler(newData, completionHandlerForConvertData: completionHandler)
        }
        
        //start the request
        task.resume()
        return task
    }
    
    //Create a request to send login data to the Udacity server, in order to retrieve a session token
    func taskForPostMethod(method: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let urlString = Constants.UdacityBaseUrl + method
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do{
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonBody, options: .PrettyPrinted)
        }
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(result: nil, error: NSError(domain: "taskForPostMethod", code: 1, userInfo: userInfo))
            }
            
            print("The request was sent!")
            
            guard error == nil else{
                sendError("There was an error posting user data.")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 &&  statusCode <= 299 else{
                
                if let response = response as? NSHTTPURLResponse {
                    completionHandler(result: response, error: nil)
                }
                else if let response = response{
                    sendError("There was an error getting your response.")
                }
                else{
                    sendError("There was an error making your request in taskForPost.")
                }
                return
            }
            
            guard let data = data else{
                print("No data was returned during your request.")
                return
            }
            
            let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
            OnTheMapClient.convertDataWithCompletionHandler(newData, completionHandlerForConvertData: completionHandler)
        }
        task.resume()
        return task
        
    }
    
    //Used to delete session token before transitioning back to initial view
    func taskForDeleteMethod(method: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask{
        
        let urlString = Constants.UdacityBaseUrl + method
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "DELETE"
        var httpCookie: NSHTTPCookie? = nil
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        
        for cookie in cookieStorage.cookies as [NSHTTPCookie]!{
            if cookie.name == "XSRF-TOKEN" {httpCookie = cookie}
        }
        
        if let httpCookie = httpCookie{
            request.setValue(httpCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        let task = session.dataTaskWithRequest(request){ (data, response, error) in
            
            guard error == nil else {
                let userInfo = [NSLocalizedDescriptionKey: "Request error: \(error)"]
                completionHandler(result: nil, error: NSError(domain: "taskForDeleteMethod", code: 1, userInfo: userInfo))
                return
            }
            
            if let newData = data?.subdataWithRange(NSMakeRange(5, (data?.length)! - 5)){
                print(NSString(data: newData, encoding: NSUTF8StringEncoding))
            }
        }
        
        
        
        task.resume()
        return task
    }
    
    //Reusable function to parse JSON data during GET/POST requests
    class func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
    
    //Allow session token to be used throughout the app
    class func sharedInstance() -> OnTheMapClient {
        struct Singleton {
            static var sharedInstance = OnTheMapClient()
        }
        return Singleton.sharedInstance
    }
}