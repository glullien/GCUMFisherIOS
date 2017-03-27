//
//  Address.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 04/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation

struct Address {
    var street: String
    var district: Int
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
struct Point {
    var latitude: Int
    var longitude: Int
    init (latitude: Int, longitude: Int) {
        self.latitude = latitude
        self.longitude = longitude
    }

    func distance(from: Point) -> Int {
        let R = Double(6378000);
        let latA = toRadian(latitude);
        let lonA = toRadian(longitude);
        let latB = toRadian(from.latitude);
        let lonB = toRadian(from.longitude);
        return Int(R * (Double.pi / 2 - asin(sin(latB) * sin(latA) + cos(lonB - lonA) * cos(latB) * cos(latA))));
    }
}
