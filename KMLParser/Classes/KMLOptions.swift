//
//  KMLOptions.swift
//  Pods
//
//  Created by Alexander van der Werff on 24/05/2017.
//
//

import Foundation

public struct KMLOptions {
    
    /// parse kml points as circle overlays instead of annotations when  > 0
    public let pointToCircleRadius: Double
    
    public init(pointToCircleRadius: Double) {
        self.pointToCircleRadius = pointToCircleRadius
    }
    
}
