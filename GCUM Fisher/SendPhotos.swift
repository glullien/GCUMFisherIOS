//
//  SendPhotos.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 10/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation

func send(address: Address, photos: [Photo]) {
    //let districtDir = address.district == 1 ? "1er" : "\(address.district)e"
    let districtDir = "111"
    let access = WebDavAccess()
    access.dir("prefpol/Dossier"){
        content in
        if content.contains(districtDir) {
            access.dir("prefpol/Dossier/\(districtDir)"){
                content in
                for item in content {
                    debugPrint("item -> \(item)")
                }
            }
        }
        else {
            access.mkDir("prefpol/Dossier/\(districtDir)") {
                content in
                debugPrint("yearp")
            }
        }
    }
    
    
}
