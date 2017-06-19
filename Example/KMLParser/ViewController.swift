//
//  ViewController.swift
//  KMLParserSample
//
//  Created by Alexander van der Werff on 09/03/2017.
//  Copyright © 2017 AvdWerff. All rights reserved.
//

import UIKit
import KMLParser
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        
        if let zones = Bundle.main.url(forResource: "multiGeometry", withExtension: "kml") {
            do {
                
                let kml = try Data(contentsOf: zones)
                parse(kml: kml)
            } catch let error {
                print(error)
            }
        }
        
    }
    
    private func parse(kml: Data) {
        let options = KMLOptions(pointToCircleRadius: 10000)
        KMLParser.parse(with: kml, options: options) { [weak self] (result) in
            if case let .success(_, overlays) = result {
                self?.mapView.addOverlays(overlays)
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? KMLPolygon {
            let renderer = overlay.renderer()
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.black
            renderer.lineWidth = 1
            return renderer
        } else if let overlay = overlay as? KMLLineString {
            return overlay.renderer()
        } else if let overlay = overlay as? KMLCircle {
            let renderer = overlay.renderer()
            renderer.fillColor = UIColor.green
            renderer.strokeColor = UIColor.cyan
            renderer.lineWidth = 1
            return renderer
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
        if let rect = mapView.overlays.first?.boundingMapRect{
            mapView.visibleMapRect = mapView.mapRectThatFits(rect)
        }
    }
}

