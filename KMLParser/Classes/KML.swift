//
//  KMLElement.swift
//  KMLParser
//
//  Created by Alexander van der Werff on 10/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import Foundation
import MapKit

protocol KMLValue {
    
}

/// KML Box values
struct KMLStringValue: KMLValue {
    let value: String
}

struct KMLCoordValue: KMLValue {
    let coords: [CLLocationCoordinate2D]
}

struct KMLColorValue: KMLValue {
    let value: UIColor
}

struct KMLFloatValue: KMLValue {
    let value: CGFloat
}

struct KMLBoolValue: KMLValue {
    let value: Bool
}

/// KML Element
enum KMLElement: String {
    case
        document = "Document",
        name = "name",
        description = "description",
        folder = "Folder",
        placemark = "Placemark",
        multiGeometry = "MultiGeometry",
        styleUrl = "styleUrl",
        extendedData = "ExtendedData",
        data = "Data",
        value = "value",
        polygon = "Polygon",
        point = "Point",
        outerBoundaryIs = "outerBoundaryIs",
        linearRing = "LinearRing",
        tesselLate = "tessellate",
        coordinates = "coordinates",
        styleMap = "StyleMap",
        lineStyle = "LineStyle",
        lineString = "LineString",
        color = "color",
        width = "width",
        style = "Style",
        polyStyle = "PolyStyle",
        fill = "fill",
        outline = "outline",
        pair = "Pair",
        key = "key",
    
        //extension
        circle = "Circle",
    
        //abstract
        geometry = "Geometry"
    
    /// Converts KML path to String, delimited with :
    static func path(with path: [KMLElement]) -> String {
        return path.map{ "\($0)" }.joined(separator: ":")
    }
    
    static func isGeometry(element: KMLElement) -> Bool {
        switch element {
        case .polygon, .linearRing, .point:
            return true
        default:
            return false
        }
    }
}

///
typealias KMLElementPath = [KMLElement]

/// Geometry
protocol Geometry: KMLValue {
    func `is`(a element: KMLElement) -> Bool
}

/// Point
struct Point: Geometry {
    func `is`(a element: KMLElement) -> Bool {
        return element == .point
    }
    let coordinate: CLLocationCoordinate2D
}

struct LinearString: Geometry {
    func `is`(a element: KMLElement) -> Bool {
        return element == .lineString
    }
    let coordinates: [CLLocationCoordinate2D]
}

/// LinearRing
struct LinearRing: Geometry {
    func `is`(a element: KMLElement) -> Bool {
        return element == .linearRing
    }
    let coordinates: [CLLocationCoordinate2D]
}

/// Polygon
struct Circle: Geometry {
    func `is`(a element: KMLElement) -> Bool {
        return element == .circle
    }
    let geo: (center: CLLocationCoordinate2D, radius: CLLocationDistance)
}

/// Polygon
struct Polygon: Geometry {
    func `is`(a element: KMLElement) -> Bool {
        return element == .polygon
    }
    let outerBoundaryIs: LinearRing
    var innerBoundaryIs: [LinearRing]
}

/// MultiGeometry
struct MultiGeometry: Geometry {
    func `is`(a element: KMLElement) -> Bool {
        return element == .multiGeometry
    }
    var elements: [Geometry]
}

extension MultiGeometry {
    init() {
        self.elements = []
    }
}


/// KML Feature
protocol KMLFeature {
    var name: String? { get set }
    var description: String? { get set }
    func annotation(styles: [KMLStyle]?) -> [MKAnnotation]?
    var styleId: String? { get set }
    var extendedData: [String: String]? { get set }
}


/// Placemark
struct Placemark: KMLFeature {
    
    var name: String?
    var description: String?
    var geometry: Geometry?
    var styleId: String?
    var extendedData: [String: String]?
    
    func annotation(styles: [KMLStyle]?) -> [MKAnnotation]? {
        
        guard let geometry = geometry else { return nil }
        
        if let polygon = geometry as? Polygon {
            let poly = KMLPolygon(
                coordinates: polygon.outerBoundaryIs.coordinates,
                count: polygon.outerBoundaryIs.coordinates.count,
                interiorPolygons: nil
            )
            poly.styles = styles ?? []
            poly.title = self.name
            poly.subtitle = self.description
            poly.extendedData = self.extendedData
            return [poly]
        } else if let line = geometry as? LinearString {
            let polyLine = KMLLineString(coordinates: line.coordinates, count: line.coordinates.count)
            polyLine.styles = styles ?? []
            polyLine.extendedData = self.extendedData
            return [polyLine]
        } else if let point = geometry as? Point {
            let point = KMLAnnotation(coordinate: point.coordinate, title: self.name ?? "", subtitle: self.description ?? "")
            point.extendedData = self.extendedData
            return [point]
        } else if let circle = geometry as? Circle {
            
            let circleElement = KMLCircle(center: circle.geo.center, radius: circle.geo.radius)
            circleElement.styles = styles ?? []
            circleElement.title = self.name
            circleElement.subtitle = self.description
            circleElement.extendedData = self.extendedData
            
            return [circleElement]
            
        } else if let multi = geometry as? MultiGeometry {
            return
                multi.elements.flatMap({ (element) -> MKAnnotation? in
                    map(element: element, name: name, description: description, styles: styles)
                })
        }
        
        return nil
    }
}

func map(element: Geometry, name: String?, description: String?, styles: [KMLStyle]?) -> MKAnnotation? {

    if let polygon = element as? Polygon {
        let poly = KMLPolygon(coordinates: polygon.outerBoundaryIs.coordinates, count: polygon.outerBoundaryIs.coordinates.count, interiorPolygons: nil)
        poly.styles = styles ?? []
        return poly
    } else if let point = element as? Point {
        return KMLAnnotation(coordinate: point.coordinate, title: name ?? "", subtitle: description ?? "")
    }
//    else if let multi = element as? MultiGeometry {
//        return multi.elements.map({ (element) -> MKAnnotation in
//            
//        })
//    }
    return nil
}
