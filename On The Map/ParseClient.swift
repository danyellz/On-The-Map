//
//  ParseClient.swift
//  On The Map
//
//  Created by TY on 4/1/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation

class ParseClient: NSObject{
    
    var session: NSURLSession
    var sessionID: String? = nil
    var userID: Int? = nil
    
    override init(){
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    //Get data from the Parse API with the Udacity session token
    func taskForGetMethod(method: String, parameters: [String : AnyObject]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //Create URL necessary to make a GET request from the Parse API
        var urlString = ""
        if let urlParameters = parameters {
            urlString = Constants.BaseURL + method + ParseClient.escapedParameters(urlParameters)
        }else{
            urlString = Constants.BaseURL + method
        }
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.addValue("\(Constants.AppID)", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("\(Constants.APIKey)", forHTTPHeaderField: "X-Parse-Rest-API-Key")
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            
            //Error checking
            guard error == nil else{
                let userInfo = [NSLocalizedDescriptionKey: "There was an error handling your request: \(error)"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            
            //Network error checking
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                if let response = response as? NSHTTPURLResponse {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response! Status code: \(response.statusCode)!"]
                    completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                } else if let response = response {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response! Response: \(response)"]
                    completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                } else {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response!"]
                    completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                }
                return
            }
            
            //Check if data is present
            guard let data = data else{
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by your request"]
                completionHandler(result: nil, error: NSError(domain: "taskForGetMethod", code: 1, userInfo: userInfo))
                return
            }
            ParseClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }
        task.resume()
        return task
    }
    
    //Client function for posting data to the Parse database
    func taskforPostMethod(method: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //Format URL to make a POST request to the parse database
        let urlString = Constants.BaseURL + method
        let formattedUrl = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: formattedUrl)
        request.HTTPMethod = "POST"
        request.addValue(Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.APIKey, forHTTPHeaderField: "X-Parse-Rest-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do{
            //Convert raw JSON object to readable data
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
        }
        
        //Make a request with the sharedSession variable
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            
            func sendError (error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(result: nil, error: NSError(domain: "taskForPostMethod", code: 1, userInfo: userInfo))
            }
            //Error checking
            guard error == nil else{
                sendError("There was an error with your taskForPost: \(error)")
                return
            }
            //Network error checking
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                if let response = response {
                    sendError("There was an error with your network request: \(response)")
                }
                return
            }
                guard let data = data else{
                    sendError("Your request did not return any data!")
                    return
                }
            ParseClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }
        task.resume()
        return task
    }
    
    //Function for updloading updated user data to the Parse API
    func taskforPutMethod(method: String, parameters: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
    
        let urlString = Constants.BaseURL + method + "/" + parameters
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.addValue(Constants.AppID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(Constants.APIKey, forHTTPHeaderField: "X-Parse-Rest-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do{
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonBody, options: .PrettyPrinted)
        }
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            
            func sendError(error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(result: nil, error: NSError(domain: "taskForPutMethod", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else{
                sendError("There was an error with your taskForPut: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else{
                
                if let response = response{
                sendError("There was an error with your network request: \(response)")
                }
                
                return
            }
            
            guard let data = data else{
                sendError("No data was returned with your request!")
                return
            }
            ParseClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }
        task.resume()
        return task
    }
    
    //Reusable function to simplify parsing JSON in GET/POST functions
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do{
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        }catch{
            
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the JSON data: \(data)"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandler(result: parsedResult, error: nil)
    }
    
    //Format url string if needed
    class func escapedParameters(parameters: [String: AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            
            let escapeValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars += [key + "=" + "\(escapeValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func sharedInstance() -> ParseClient {
        struct Singleton {
            static var sharedInstance = ParseClient()
        }
        return Singleton.sharedInstance
    }
    
}