//
//  Photo.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 04/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

let imageSizes = [ImageSize.Small: 400, ImageSize.Medium: 800, ImageSize.Maximal:Int.max]

struct Photo {
    
    var image: UIImage
    var date: Date
    var id: Int
    var point: Point?
    
    init (image: UIImage, date: Date, id: Int, point: Point? = nil) {
        self.image = image
        self.date = date
        self.id = id
        self.point = point
    }
    
    func getImage(width: Double, height: Double) -> UIImage {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 1)
        let context = UIGraphicsGetCurrentContext()!
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }
    
    func getImage(maxSize: Double) -> UIImage {
        let width = Double(image.size.width)
        let height = Double(image.size.height)
        if (width <= maxSize) && (height <= maxSize) {
            return image
        }
        else if width <= height {
            return getImage (width: width*maxSize/height, height: maxSize)
        }
        else {
            return getImage (width: width*maxSize/height, height: maxSize)
        }
    }
    
    func getData(size: ImageSize, quality: Int) -> Data {
        let maxSize = Double(imageSizes[size]!)
        let quality = CGFloat(Double(quality)/100.0)
        return UIImageJPEGRepresentation(getImage(maxSize: maxSize), quality)!
    }
    
}
