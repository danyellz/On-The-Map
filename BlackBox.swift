//
//  BlackBox.swift
//  On The Map
//
//  Created by TY on 3/28/16.
//  Copyright © 2016 On The Map. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}