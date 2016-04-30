//
//  StudentDataModel.swift
//  On The Map
//
//  Created by TY on 4/29/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation
import UIKit

class StudentDataModel{
    
    //Array that holds all student data using the UserInformation struct in UserInfoStruct.swift
    static var studentData = [UserInformation]()
    
    class func sharedInstance() -> StudentDataModel{
        struct Singleton{
            static var sharedInstance = StudentDataModel()
        }
        return Singleton.sharedInstance
    }
}

