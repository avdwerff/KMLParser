//
//  File.swift
//  KMLParser
//
//  Created by Alexander van der Werff on 18/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import Foundation
import MapKit
import UIKit


protocol KMLOverlay {
    func renderer() -> MKOverlayRenderer
}

/// # KMLPolygon
open class KMLPolygon: MKPolygon, KMLOverlay, KMLStyleable {
    
    var styles: [KMLStyle] = []
    
    var outline = true
    
    var fill = true
    
    var lineWidth: CGFloat = 0
    
    var strokeColor: UIColor = UIColor.clear
    
    var fillColor: UIColor = UIColor.clear
    
    open func renderer() -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(polygon: self)
        for style in styles {
            switch style {
            case .line(let color, let width):
                self.lineWidth = width
                self.strokeColor = color
            case .poly(let color, let fill, let outline):
                self.outline = outline
                self.fill = fill
                self.fillColor = color
            default:
                break
            }
        }
        if fill {
            renderer.fillColor = fillColor
        }
        if outline {
            renderer.lineWidth = lineWidth
            renderer.strokeColor = strokeColor
        }
        return renderer
    }
    
}

open class KMLLineString: MKPolyline, KMLOverlay, KMLStyleable {
    
    var styles: [KMLStyle] = []
    
    var lineWidth: CGFloat = 0
    
    var strokeColor: UIColor = UIColor.clear
    
    open func renderer() -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: self)
        for style in styles {
            switch style {
            case .line(let color, let width):
                self.lineWidth = width
                self.strokeColor = color
            default:
                break
            }
        }
        renderer.lineWidth = lineWidth
        renderer.strokeColor = strokeColor
        return renderer
    }
}
