//
//  GCDBlackBox.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: @escaping () -> Void) {
//    dispatch_async(dispatch_get_main_queue()) {
//        updates()
//    }
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: updates)
}
