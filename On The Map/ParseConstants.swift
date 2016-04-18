//
//  ParseConstants.swift
//  On The Map
//
//  Created by TY on 4/1/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation

extension ParseClient{
    
    struct Constants{
    static let AppID: String = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    static let APIKey: String = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    static let BaseURL: String = "https://api.parse.com/1/classes/"
}

struct Methods{
    static let StudentCoords = "StudentLocation"
}

struct ParameterKeys{
    static let Where = "where"
    static let UniqueKey = "uniqueKey"
}

struct JSONBodyKeys {
    static let UniqueKey = "uniqueKey"
    static let FirstName = "firstName"
    static let LastName = "lastName"
    static let MapString = "mapString"
    static let MediaURL = "mediaURL"
    static let Latitude = "latitude"
    static let Longitude = "longitude"
}

struct JSONResponseKeys {
    static let Results = "results"
    static let FirstName = "firstName"
    static let LastName = "lastName"
    static let Latitude = "latitude"
    static let Longitude = "longitude"
    static let MapString = "mapString"
    static let MediaURL = "mediaURL"
    static let ObjectID = "objectId"
    static let UniqueKey = "uniqueKey"
    static let CreatedAt = "createdAt"
    static let UpdatedAt = "updatedAt"
}
    
    struct User{
        static var objectId: String?
    }
    
}