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

class PhotosAnnotation : NSObject, MKAnnotation {
    
    let point: ServerPoint
    var coordinate: CLLocationCoordinate2D {
        get {
            return point.point.getCLLocationCoordinate2D()
        }
    }
    var title: String? {
        get {
            return point.street
        }
    }
    var subtitle: String? {
        get {
            return "\(point.dates) : \(point.nbPhotos) photos"
        }
    }
    init(_ point: ServerPoint){
        self.point = point
    }
    
}

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
                    self.mapView.addAnnotation(PhotosAnnotation(point))
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView?
        if let annotation = annotation as? PhotosAnnotation {
            let annotationIdentifier = "Photo"
            if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
                annotationView = dequeuedAnnotationView
                annotationView?.annotation = annotation
            }
            else {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            if let annotationView = annotationView {
                annotationView.isEnabled = true
                annotationView.canShowCallout = true
            }
        }
        return annotationView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowListForPoint") {
            if let destination = segue.destination as? ListViewController, let point = sender as? Point {
                destination.point = point
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? PhotosAnnotation {
            performSegue(withIdentifier: "ShowListForPoint", sender: annotation.point.point)
        }
    }
    
    @IBAction func showHere(sender: UIButton) {
        mapView.region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 500, 500)
    }
    
    @IBAction func showParis(sender: UIButton) {
        mapView.region = parisRegion
    }
    
}
