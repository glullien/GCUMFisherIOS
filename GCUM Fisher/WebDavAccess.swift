//
//  WebDavAccess.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 08/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class WebDavAccess : NSObject {
    
    let client: LEOWebDAVClient
    let site = "https://cloud.debian-economist.eu"
    let root = "/remote.php/webdav/"
    var requests = [LEOWebDAVRequestDelegate]()
    
    override init() {
        let url = URL(string: "\(site)\(root)")
        client = LEOWebDAVClient(rootURL: url, andUserName: "Gurvan", andPassword: "Web/Dav12")
        super.init()
    }
    
    func list(_ path: String, then: @escaping ([String]) -> Void) {
        let res = WebDavDir(access: self, path: path, then: then)
        requests.append(res)
        res.run()
    }
    
    func mkDir(_ path: String, then: @escaping () -> Void) {
        let res = WebDavMkDir(access: self, path: path, then: then)
        requests.append(res)
        res.run()
    }
    
    func upload(_ path: String, image: UIImage, then: @escaping () -> Void) {
        if let data = UIImageJPEGRepresentation(image, 0.9) {
            upload(path, data: data, mimeType: "image/jpeg", then: then)
        }
    }

    func upload(_ path: String, data: Data, mimeType: String, then: @escaping () -> Void) {
        let res = WebDavUpLoad(access: self, path: path, data: data, mimeType: mimeType, then: then)
        requests.append(res)
        res.run()
    }

}

class WebDavDir : NSObject, LEOWebDAVRequestDelegate {
    
    let access: WebDavAccess
    let path: String
    let prop: LEOWebDAVPropertyRequest
    let then: ([String]) -> Void
    
    init (access: WebDavAccess, path: String, then: @escaping ([String]) -> Void) {
        self.access = access
        self.path = path
        prop = LEOWebDAVPropertyRequest(path: path)
        self.then = then
        super.init()
    }
    
    func run () {
        prop.delegate = self
        access.client.enqueue(prop)
    }
    
    func request(_ request: LEOWebDAVRequest!, didFailWithError error: Error!) {
        debugPrint("error \(error)")
    }
    
    func request(_ request: LEOWebDAVRequest!, didSucceedWithResult result: Any!) {
        debugPrint("success \(result)")
        var res = [String]()
        if let list = result as? [LEOWebDAVItem] {
            for item in list {
                if "\(access.root)\(path)/" != item.href {
                    res.append(item.displayName)
                }
            }
        }
        then(res)
    }
}

class WebDavMkDir : NSObject, LEOWebDAVRequestDelegate {
    
    let access: WebDavAccess
    let path: String
    let prop: LEOWebDAVMakeCollectionRequest
    let then: () -> Void
    
    init (access: WebDavAccess, path: String, then: @escaping () -> Void) {
        self.access = access
        self.path = path
        prop = LEOWebDAVMakeCollectionRequest(path: path)
        self.then = then
        super.init()
    }
    
    func run () {
        prop.delegate = self
        access.client.enqueue(prop)
    }
    
    func request(_ request: LEOWebDAVRequest!, didFailWithError error: Error!) {
        debugPrint("error \(error)")
    }
    
    func request(_ request: LEOWebDAVRequest!, didSucceedWithResult result: Any!) {
        debugPrint("success \(result)")
        then()
    }
}

class WebDavUpLoad : NSObject, LEOWebDAVRequestDelegate {
    
    let access: WebDavAccess
    let path: String
    let prop: LEOWebDAVUploadRequest
    let then: () -> Void
    
    init (access: WebDavAccess, path: String, data: Data, mimeType: String, then: @escaping () -> Void) {
        self.access = access
        self.path = path
        prop = LEOWebDAVUploadRequest(path: path)
        prop.data = data
        prop.dataMimeType = mimeType
        self.then = then
        super.init()
    }
    
    func run () {
        prop.delegate = self
        access.client.enqueue(prop)
    }
    
    func request(_ request: LEOWebDAVRequest!, didFailWithError error: Error!) {
        debugPrint("error \(error)")
    }
    
    func request(_ request: LEOWebDAVRequest!, didSucceedWithResult result: Any!) {
        debugPrint("success \(result)")
        then()
    }
}
