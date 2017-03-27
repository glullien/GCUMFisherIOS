//
//  SendPhotos.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 10/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation

enum ImageSize: String {
    case Small = "small"
    case Medium = "medium"
    case Maximal = "maximal"
}

func saveImageSize (_ size: ImageSize) {
    let defaults = UserDefaults.standard
    defaults.setValue(size.rawValue, forKey: "imageSize")
    defaults.synchronize()
}

func getImageSize () -> ImageSize {
    if let size = UserDefaults.standard.string(forKey: "imageSize") {
        return ImageSize(rawValue: size)!
    }
    else {
        return ImageSize.Maximal
    }
}

func saveImageQuality (_ quality: Int) {
    let defaults = UserDefaults.standard
    defaults.setValue(quality, forKey: "imageQuality")
    defaults.synchronize()
}

func getImageQuality () -> Int {
    let quality = UserDefaults.standard.integer(forKey: "imageQuality")
    return quality > 0 ? quality : 95
}


enum ProgressType {
    case Sending
    case Success
    case Error}
