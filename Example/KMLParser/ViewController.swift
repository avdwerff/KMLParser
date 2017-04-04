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
        
        if let zones = Bundle.main.url(forResource: "polygon", withExtension: "kml") {
            do {
                
                let kml = try Data(contentsOf: zones)
                parse(kml: kml)
            } catch let error {
                print(error)
            }
        }
        
    }
    
    private func parse(kml: Data) {
        KMLParser.parse(with: kml) { [weak self] (result) in
            if case let .success(annotations, overlays) = result {
                self?.mapView.addOverlays(overlays)
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? KMLPolygon {            
            return overlay.renderer()
        }
        return MKOverlayRenderer()
    }

}

