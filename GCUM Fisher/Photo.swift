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
    var id: Int
    
    init (image: UIImage, id: Int) {
        self.image = image
        self.id = id
    }
    
}
