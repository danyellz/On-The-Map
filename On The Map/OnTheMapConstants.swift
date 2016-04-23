//
//  OnTheMapConstants.swift
//  On The Map
//
//  Created by TY on 3/25/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

//Create constants to easily build requests from the Udacity API key/values

import Foundation

extension OnTheMapClient {

struct Constants{
    
    static let UdacityBaseUrl: String = "https://www.udacity.com/api/"
    
}
    
    struct Methods{
        static let Session = "session"
        static let Users = "users/"
    }
    
    struct JSONBodyKeys {
        static let User = "username"
        static let Pass = "password"
        static let Udacity = "udacity"
    }
    
    
    struct JSONResponseKeys {
        static let Account = "account"
        static let Registered = "registered"
        static let Key = "key"
        
        static let Session = "session"
        static let ID = "id"
        static let expiration = "expiration"
        
        static let User = "user"
        static let FirstName = "first_name"
        static let LastName = "last_name"
    }

}