//
//  MapViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 30/03/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView : MKMapView!
    
    let parisRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: 48.85, longitude: 2.34), 9500, 11200)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView?.delegate = self
        mapView.showsUserLocation = true
        
        mapView.region = parisRegion
        
        getPoints() {
            points, error in
            if let error = error {
                let alert = UIAlertController(title: "Erreur", message: error, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else if let points = points {
                for point in points {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = point.getCLLocationCoordinate2D()
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    @IBAction func showHere(sender: UIButton) {
        mapView.region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 500, 500)
    }
    
    @IBAction func showParis(sender: UIButton) {
        mapView.region = parisRegion
    }
    
}
