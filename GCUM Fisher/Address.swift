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
