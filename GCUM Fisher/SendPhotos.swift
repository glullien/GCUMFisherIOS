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

private extension WebDavAccess{
    private func mkDirs (_ dirs: ArraySlice<String>, inPath: String, then: @escaping () -> Void) {
        if dirs.count == 0 {
            then()
        }
        else {
            mkDir("\(inPath)/\(dirs[0])") {
                self.mkDirs(dirs.suffix(from: 1), inPath: inPath, then: then)
            }
        }
    }
    
    func ensureDirs (_ dirs: [String], inPath: String, then: @escaping () -> Void) {
        list(inPath) {
            content in
            var toMake = ArraySlice<String>()
            for dir in dirs {
                if (!content.contains(dir)) && (!toMake.contains(dir)) {
                    toMake.append(dir)
                }
            }
            self.mkDirs(toMake, inPath: inPath, then: then)
        }
    }
    
    func ensureDir(_ dir: String, inPath: String, then: @escaping () -> Void) {
        ensureDirs([dir], inPath: inPath, then: then)
    }
}

private let streetDirs = ["quai de jemmapes": "quai_Jemmapes"]

private func replaceSpecialChars(_ source: String) -> String {
    return toStdChars(source.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "_"))
}

private func encode(street: String) -> String {
    if let special = streetDirs[street.lowercased()] {
        return special
    }
    else {
        return firstCharToLowerCase(replaceSpecialChars(street))
    }
}

private func encode(district: Int) -> String {
    return district == 1 ? "1er" : "\(district)e"
}

private func encode(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "fr_FR")
    formatter.dateFormat = "yyyy_MM_dd"
    return formatter.string(from: date)
}

enum ProgressType {
    case Sending
    case Success
    case Error}

func send(credentials: Credentials, address: Address, photos: [Photo], progress: @escaping (ProgressType, String) -> Void) {
    DispatchQueue.global().async {
        let districtDir = encode(district: address.district)
        // let districtDir = "111"
        let streetDir = encode(street: address.street)
        var dateDirs = [String]()
        for photo in photos {
            dateDirs.append(encode(date: photo.date))
        }
        let access = WebDavAccess(credentials: credentials, error: {
            error in
            progress(ProgressType.Error, error.localizedDescription)
        })
        DispatchQueue.main.async {
            progress(ProgressType.Sending, "Création des répertoires")
        }
        access.ensureDir (districtDir, inPath: "prefpol/Dossier") {
            access.ensureDir (streetDir, inPath: "prefpol/Dossier/\(districtDir)") {
                access.ensureDirs (dateDirs, inPath: "prefpol/Dossier/\(districtDir)/\(streetDir)") {
                    var sent = 0
                    DispatchQueue.main.async {
                        progress(ProgressType.Sending, "Envoi des fichiers \(sent) / \(photos.count)")
                    }
                    for photo in photos {
                        let data = photo.getData (size: getImageSize(), quality: getImageQuality())
                        let uniqueId = arc4random_uniform(10000000)
                        let dateDir = encode(date: photo.date)
                        access.upload( "prefpol/Dossier/\(districtDir)/\(streetDir)/\(dateDir)/gcum\(uniqueId).jpg", data: data, mimeType: "image/jpeg", then: {
                            DispatchQueue.main.async {
                                sent += 1
                                if sent == photos.count {
                                    progress(ProgressType.Success, "Fichiers envoyés")
                                }
                                else {
                                    progress(ProgressType.Sending, "Envoi des fichiers \(sent) / \(photos.count)")
                                }
                            }
                         })
                    }
                }
            }
        }
    }
}
