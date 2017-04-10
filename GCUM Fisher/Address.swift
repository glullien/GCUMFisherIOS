//
//  Address.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 04/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import MapKit

struct Address {
    let street: String
    let district: Int
    init (street: String, district: Int) {
        self.street = street
        self.district = district
    }
    func fullName () -> String {
        return "\(street), dans le \(district)e"
    }
}

private func toRadian (_ degree: Int) -> Double {
    return (Double.pi * Double (degree) * 1E-5) / (180);
}

private func format(_ degree: Int) -> String {
    return String(format: "%.5f", Double(degree)*1E-5)
}
struct Point {
    var latitude: Int
    var longitude: Int
    init (latitude: Int, longitude: Int) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    func getCLLocationCoordinate2D () -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: Double(latitude)*1E-5, longitude: Double(longitude)*1E-5)
    }
    
    
    func distance(from: Point) -> Int {
        let R = Double(6378000);
        let latA = toRadian(latitude);
        let lonA = toRadian(longitude);
        let latB = toRadian(from.latitude);
        let lonB = toRadian(from.longitude);
        let a = sin(latB) * sin(latA) + cos(lonB - lonA) * cos(latB) * cos(latA)
        let d = Double.pi / 2 - asin(min (1.0, max (-1.0, a)))
        return Int(R * d);
    }
    
    func fullName () -> String {
        return "\(format(latitude)) °N / \(format(longitude)) °E"
    }
}
