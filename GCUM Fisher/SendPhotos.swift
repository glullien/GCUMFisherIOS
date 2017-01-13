//
//  SendPhotos.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 10/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation

private extension WebDavAccess{
    func ensureDir(_ dir: String, inPath: String, then: @escaping () -> Void) {
        list(inPath) {
            content in
            if content.contains(dir) {
                then()
            }
            else {
                self.mkDir("\(inPath)/\(dir)") {
                    then()
                }
            }
        }
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

func send(address: Address, date: Date, photos: [Photo], progress: @escaping (ProgressType, String) -> Void) {
    DispatchQueue.global().async {
        let districtDir = encode(district: address.district)
        // let districtDir = "111"
        let streetDir = encode(street: address.street)
        let dateDir = encode(date: date)
        let access = WebDavAccess()
        DispatchQueue.main.async {
            progress(ProgressType.Sending, "Création des répertoires")
        }
        access.ensureDir (districtDir, inPath: "prefpol/Dossier") {
            access.ensureDir (streetDir, inPath: "prefpol/Dossier/\(districtDir)") {
                access.ensureDir (dateDir, inPath: "prefpol/Dossier/\(districtDir)/\(streetDir)") {
                    var sent = 0
                    DispatchQueue.main.async {
                        progress(ProgressType.Sending, "Envoi des fichiers \(sent)\(photos.count)")
                    }
                    for photo in photos {
                        let uniqueId = arc4random_uniform(10000000)
                        access.upload( "prefpol/Dossier/\(districtDir)/\(streetDir)/\(dateDir)/gcum\(uniqueId).jpg", image: photo.image, then: {
                            DispatchQueue.main.async {
                                sent += 1
                                if sent == photos.count {
                                    progress(ProgressType.Success, "Fichiers envoyés")
                                }
                                else {
                                    progress(ProgressType.Sending, "Envoi des fichiers \(sent)/\(photos.count)")
                                }
                            }
                         })
                    }
                }
            }
        }
    }
}
