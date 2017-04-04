//
//  Result.swift
//  KMLParser
//
//  Created by Alexander van der Werff on 08/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import Foundation
import MapKit

public enum Reason: Equatable {
    case
        parseError(Error)
    
    public static func ==(lhs: Reason, rhs: Reason) -> Bool {
        switch (lhs, rhs) {
        default: return false
        }
    }
    
}


// MARK: - Result monad

public typealias Result = (ResultType) -> ()

public enum ResultType {
    
    /// success with value as json dict
    case success(annotations: [MKAnnotation], overlays: [MKOverlay])
    
    /// failure with some reason
    case failure(reason: Reason)
    
}
