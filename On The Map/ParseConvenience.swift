//
//  ParseConvenience.swift
//  On The Map
//
//  Created by TY on 4/1/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension ParseClient{
    
    func getStudentLocations(completionHandler: (result: [[String: AnyObject]]?, error: NSError?) -> Void){
        
        taskForGetMethod(Methods.StudentCoords, parameters: nil) {(JSONResult, error) in
            
            func sendError(error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(result: nil, error: NSError(domain: "postStudentLocation", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else{
                sendError("There was an error with getStudentLocations convenience")
                return
            }
            
            if let results = JSONResult[JSONResponseKeys.Results] as? [[String: AnyObject]] {
                completionHandler(result: results, error: nil)
            }else{
                completionHandler(result: nil, error: NSError(domain: "getStudentLocations", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve student data"]))
            }
    }
    }
    
    func postStudentLocationsConvenience(jsonBody: [String: AnyObject], completionHandler: (result: AnyObject?, error: NSError?) -> Void) {
        
        taskforPostMethod(Methods.StudentCoords, jsonBody: jsonBody) {(JSONResult, error) in
            
            func sendError(error: String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(result: nil, error: NSError(domain: "postStudentLocation", code: 0, userInfo: userInfo))
                
            }
            
            guard error == nil else{
                sendError("There was an error with your postStudentLocations convenience method: \(error)")
                return
            }
            
            if let result = JSONResult[JSONResponseKeys.ObjectID] as? String {
                completionHandler(result: result, error: nil)
            }else{
                sendError("ObjectID was not returned with postStudentLovations convenience")
            }
        }
    }
    
    func putStudentLocationsConvenience(parameters: String, jsonBody: [String: AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void){
        
        taskforPutMethod(JSONResponseKeys.ObjectID, parameters: parameters, jsonBody: jsonBody) {(JSONResult, error) in
            
            func sendError(error:String){
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(result: nil, error: NSError(domain: "putStudentLocation", code: 0, userInfo: userInfo))

            }
            
            guard error == nil else{
                sendError("There was an error in putStudent convnience method \(error)")
                return
            }
            
            if let result = JSONResult[JSONResponseKeys.CreatedAt] as? String {
                completionHandler(result: result, error: nil)
            }else{
                sendError("CreatedAt was not found during putStudentLocation convenience")
            }
        }
    }
}