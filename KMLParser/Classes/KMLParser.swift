//
//  KMLParser.swift
//  KMLParser
//
//  Created by Alexander van der Werff on 08/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import Foundation
import MapKit


open class KMLParser: NSObject, XMLParserDelegate {
    
    // actual parser
    private var parser: XMLParser?
    
    // options
    private var options: KMLOptions?
    
    // lookup table during parsing
    private var kmlObjectLookup: [KMLElement: KMLValue] = [:]
    
    // styles
    private var styles: [String: [KMLStyle]] = [:]
    
    // style map
    private var styleMaps: [String: [String: String]] = [:]
    
    // extended data
    private var extendedData: [String: String] = [:]
    
    private var currentDataKey: String?
    
    // current style id
    private var currentStyleId: String?
    
    // current style map id
    private var currentStyleMapId: String?
    
    // current element in parsing
    private var currentElement: KMLElement?
    
    // full xpath to current element
    private var currentElementPath: KMLElementPath = []
    
    // to be converted kml features to MKAnnotations and MKOverlays
    private var features: [KMLFeature] = []
    
    /// parsed overlays from KML document
    private var overlays: [MKOverlay] = []
    
    /// parsed points from KML document
    private var annotations: [MKAnnotation] = []
    
    /// result handler
    var completion: Result?
    
    /// private initialiser, use KMLParser.parse to initiate a parse session
    private init(data: Data) {
        parser = XMLParser(data: data)
    }
    
    // MARK: - API
    
    /// parse: Parses a kml document and returns a `Result`
    /// - Parameter data: A Data object representing the KML xml content
    /// - Parameter options
    public static func parse(with data: Data, options: KMLOptions?, completion: @escaping Result) {
        let kmlParser = KMLParser(data: data)
        kmlParser.parser?.delegate = kmlParser
        kmlParser.options = options
        kmlParser.completion = completion
        kmlParser.parser?.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    public func parserDidStartDocument(_ parser: XMLParser) {
        overlays = []
        styles = [:]
        styleMaps = [:]
    }
    
    /// End parsing
    public func parserDidEndDocument(_ parser: XMLParser) {
        _ = features.compactMap { [weak self] feature -> [MKAnnotation]? in
            
            ///guard let `self` = self else { return annotations
                let styles = self?.styles(with: feature.styleId)
            
                let annotations = feature.annotation(styles: styles)

                return annotations
            }
            .map {
                for overlay in $0 {
                    if let overlay = overlay as? MKOverlay {
                        overlays.append(overlay)
                    } else {
                        annotations.append(overlay)
                    }
                }
            }
        
        if let completion = completion {
            completion(ResultType.success(annotations: annotations, overlays: overlays))
        }
        
        //clean
        features = []
        styles = [:]
    }
    
    
    /// Start element
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentElement = KMLElement(rawValue: elementName)
        
        guard
            let element = currentElement
            else {
                return
            }
        
        currentElementPath.append(element)
        
        switch element {
        case .multiGeometry:
            let multiGeo = MultiGeometry()
            kmlObjectLookup[.multiGeometry] = multiGeo
        case .style:
            guard attributeDict["id"] != nil else { return }
            
            guard let id = attributeDict["id"] else {
                return
            }
            let hashedId = "#\(id)"
            currentStyleId = hashedId
            styles[hashedId] = []
        case .styleMap:
            guard attributeDict["id"] != nil else { return }
            
            guard let id = attributeDict["id"] else {
                return
            }
            let hashedId = "#\(id)"
            currentStyleMapId = hashedId
            styleMaps[hashedId] = [:]
        case .extendedData:
            //reset start with extended data tag
            extendedData = [:]
        case .data:
            guard let name = attributeDict["name"] else { return }
            currentDataKey = name
        default:
            break
        }
        
    }
    
    /// End element
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    
        guard
            let element = KMLElement(rawValue: elementName)
            else {
                return
        }
        
        defer {
            if currentElementPath.count > 0 {
                currentElementPath.removeLast()
            }
            currentElement = nil
        }
        
        switch element {
        case .style:
            currentStyleId = nil
        case .placemark:
            var placemark = Placemark()
            if let geo = kmlObjectLookup[.geometry] as? Geometry {
                placemark.geometry = geo
                kmlObjectLookup.removeValue(forKey: .geometry)
            }
            else if let multi = kmlObjectLookup[.multiGeometry] as? Geometry {
                placemark.geometry = multi
                kmlObjectLookup.removeValue(forKey: .multiGeometry)
            }
            if let name = kmlObjectLookup[.name] as? KMLStringValue {
                placemark.name = name.value
                kmlObjectLookup.removeValue(forKey: .name)
            }
            if let description = kmlObjectLookup[.description] as? KMLStringValue {
                placemark.description = description.value
                kmlObjectLookup.removeValue(forKey: .description)
            }
            if let styleUrl = kmlObjectLookup[.styleUrl] as? KMLStringValue {
                placemark.styleId = styleUrl.value
                kmlObjectLookup.removeValue(forKey: .styleUrl)
            }
            if extendedData.count > 0 {
                placemark.extendedData = extendedData
                //reset extended data tag
                extendedData = [:]
            }
            features.append(placemark)
        case .polygon:
            do {
                if let polygon = try self.createGeometryFromLookup(with: .polygon) {
                    
                    if var multi = kmlObjectLookup[.multiGeometry] as? MultiGeometry {
                       
                       multi.elements.append(polygon)
                       kmlObjectLookup[.multiGeometry] = multi
                        
                    } else {
                        kmlObjectLookup[.geometry] = polygon
                    }
                }
            } catch {
                
            }
            
        // required element from polygon, should be ring
        case .outerBoundaryIs:
            if let ring = kmlObjectLookup[.linearRing] as? Geometry {
                kmlObjectLookup[.outerBoundaryIs] = ring
                kmlObjectLookup.removeValue(forKey: .linearRing)
            }
        case .linearRing:
        
            if let coords = kmlObjectLookup[.coordinates] as? KMLCoordValue {
                
                guard coords.coords[0] == coords.coords[coords.coords.count-1] else {
                    return
                }
            
                kmlObjectLookup[.linearRing] = LinearRing(coordinates: coords.coords)
                kmlObjectLookup.removeValue(forKey: .coordinates)
            }
        case .point:
            if let coords = kmlObjectLookup[.coordinates] as? KMLCoordValue{
                guard coords.coords.count > 0 else { return }
                
                if let pointToCircleRadius = options?.pointToCircleRadius, pointToCircleRadius > 0 {
                    kmlObjectLookup[.geometry] = Circle(geo: (center: coords.coords[0], radius: pointToCircleRadius))
                } else {
                    kmlObjectLookup[.geometry] = Point(coordinate: coords.coords[0])
                }
                kmlObjectLookup.removeValue(forKey: .coordinates)
            }
        case .lineString:
            defer {
                kmlObjectLookup.removeValue(forKey: .coordinates)
            }
            if let coords = kmlObjectLookup[.coordinates] as? KMLCoordValue {
                guard coords.coords.count > 0 else { return }
                kmlObjectLookup[.geometry] = LinearString(coordinates: coords.coords)
            }
        case .lineStyle:
            defer {
                kmlObjectLookup.removeValue(forKey: .width)
                kmlObjectLookup.removeValue(forKey: .color)
            }
            let width: KMLFloatValue = kmlObjectLookup[.width] as? KMLFloatValue ?? KMLFloatValue(value: 1.0)
            let color: KMLColorValue = kmlObjectLookup[.color] as? KMLColorValue ?? KMLColorValue(value: UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            if currentStyleId == nil {
                let styleID = ""
                currentStyleId = styleID
                styles[styleID] = []
            }
            let id: String = currentStyleId ?? ""
            styles[id]?.append(KMLStyle.line(color: color.value, width: width.value))
        case .polyStyle:
            defer {
                kmlObjectLookup.removeValue(forKey: .outline)
                kmlObjectLookup.removeValue(forKey: .fill)
                kmlObjectLookup.removeValue(forKey: .color)
            }
            guard
                let outline = kmlObjectLookup[.outline] as? KMLBoolValue,
                let fill = kmlObjectLookup[.fill] as? KMLBoolValue,
                let color = kmlObjectLookup[.color] as? KMLColorValue,
                let id = currentStyleId
                else {
                    return
            }
            
            styles[id]?.append(KMLStyle.poly(color: color.value, fill: fill.value, outline: outline.value))
        default:
            break
        }
        
    }
    
    /// Parse value
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case .some(.value):
            if let key = currentDataKey {
                extendedData[key] = string
            }
        case .some(.color):
            let color = UIColor(hex: string)
            kmlObjectLookup[.color] = KMLColorValue(value: color)
        case .some(.width):
            if let float = Float(string) {
                kmlObjectLookup[.width] = KMLFloatValue(value: CGFloat(float))
            }
        case .some(.fill):
            if let bool = string.toBool() {
                kmlObjectLookup[.fill] = KMLBoolValue(value: bool)
            }
        case .some(.outline):
            if let bool = string.toBool() {
                kmlObjectLookup[.outline] = KMLBoolValue(value: bool)
            }
        case .some(.name) where string.count > 1:
            kmlObjectLookup[.name] = KMLStringValue(value: string)
        case .some(.description):
            kmlObjectLookup[.description] = KMLStringValue(value: string)
        case .some(.styleUrl):
        
            //style map
            if currentElementPath[currentElementPath.count - 2] == .pair {
                
                //assumes normal key is first
                guard let currentStyleMapId = currentStyleMapId else { return }
                
                if styleMaps[currentStyleMapId]?.count == 0 {
                    styleMaps[currentStyleMapId]?["normal"] = string
                } else {
                    styleMaps[currentStyleMapId]?["highlight"] = string
                }
                
            } else {
                kmlObjectLookup[.styleUrl] = KMLStringValue(value: string)
            }
            
        case .some(.key) where KMLParser.findParentGeometryElement(in: currentElementPath) == .pair:
            guard let currentStyleMapId = currentStyleMapId else { return }
            //assumes some semantics that key is found first!!
            styleMaps[currentStyleMapId] = [string: ""]
        case .some(.coordinates):
            //coordinates can be removed
            //let path = Array(currentElementPath.dropLast())
            let coords = KMLParser.parseCoordinates(with: string)
            
            guard coords.count > 0 else {
                return
            }
            
            kmlObjectLookup[.coordinates] = KMLCoordValue(coords: coords)
        default:
            break
        }
    }
    
    
    /// MARK: - Private
    
    /// Creates a geometry object
    private func createGeometryFromLookup(with element: KMLElement) throws -> Geometry? {
        switch element {
        case .polygon:
            
            guard let outer = kmlObjectLookup[.outerBoundaryIs] as? LinearRing else {
                throw XMLParser.SemanticError.polygonError("outerBoundaryIs is required for a polygon")
            }
            
            let polygon = Polygon(outerBoundaryIs: outer, innerBoundaryIs: [])
            
            kmlObjectLookup.removeValue(forKey: .outerBoundaryIs)
            
            return polygon
            
        default:
            break
        }
        
        return nil
    }
    
    /// Parse coordinates from tag
    private static func parseCoordinates(with coordString: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let lines: [String] = coordString.toLines()
        for line in lines {
            let points: [String] = line.components(separatedBy: ",")
            //ignore 3th param altitude
            guard
                points.count >= 2,
                let lat = CLLocationDegrees(points[1]),
                let long = CLLocationDegrees(points[0])
                else {
                    break
                }
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: long)
            coordinates.append(coord)
        }
        return coordinates
    }
    
    ///
    private static func findParentGeometryElement(in path: KMLElementPath) -> KMLElement? {
        let reversedPath = path.reversed()
        for i in reversedPath.indices {
            if KMLElement.isGeometry(element: reversedPath[i]) {
                return reversedPath[i]
            }
        }
        return nil
    }
    
    ///
    private func styles(with styleId: String?) -> [KMLStyle]? {
        
        let styleId = styleId ?? ""
        
        let style = styleMaps[styleId]?["normal"] ?? styleId
        
        guard let applicableStyles = styles[style] else { return nil }
        
        return applicableStyles
    }
    
}
