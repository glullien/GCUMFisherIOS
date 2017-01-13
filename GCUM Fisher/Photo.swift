//
//  Photo.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 04/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit


struct Photo {
    
    var image: UIImage
    var date: Date
    var id: Int
    
    init (image: UIImage, date: Date, id: Int) {
        self.image = image
        self.date = date
        self.id = id
    }
    
}
