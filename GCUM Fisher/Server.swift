//
//  Server.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 24/03/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
//import MobileCoreServices
import UIKit

let baseUrl = "https://www.gcum.lol/"
//let baseUrl = "http://192.168.1.13:8080/"
//let baseUrl = "http://192.168.62.233:8080/"

private func returnError (_ error: String, completionHandler: @escaping ([String:Any]?, String?) -> Swift.Void) {
    DispatchQueue.main.async {
        completionHandler(nil,error)
    }
}
private extension String {
    func addingPercentEncodingForQueryParameter() -> String? {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        return addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

/*func mimeType(for path: String) -> String {
 let url = NSURL(fileURLWithPath: path)
 let pathExtension = url.pathExtension
 
 if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
 if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
 return mimetype as String
 }
 }
 return "application/octet-stream";
 }*/

func generateBoundaryString() -> String {
    return "Boundary-\(NSUUID().uuidString)"
}

func createBody(with parameters: [String: String]?, data: Data, boundary: String) throws -> Data {
    var body = Data()
    
    if parameters != nil {
        for (key, value) in parameters! {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n")
            body.append("Content-type: text/plain; charset=UTF-8\r\n\r\n")
            body.append("\(value)\r\n")
        }
    }
    
    /*let url = URL(fileURLWithPath: path)
     let filename = url.lastPathComponent
     let data = try Data(contentsOf: url)
     let mimetype = mimeType(for: path)*/
    
    body.append("--\(boundary)\r\n")
    body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpeg\"\r\n")
    body.append("Content-Type: image/jpeg\r\n\r\n")
    body.append(data)
    body.append("\r\n")
    
    body.append("--\(boundary)--\r\n")
    return body
}

func createRequest(_ servlet: String, with parameters: [String: String]?, data: Data) throws -> URLRequest {
    let boundary = generateBoundaryString()
    
    let url = URL(string: "\(baseUrl)\(servlet)")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    //let path1 = Bundle.main.path(forResource: "image1", ofType: "png")!
    request.httpBody = try createBody(with: parameters, data: data, boundary: boundary)
    
    return request
}

private func jsonRequest (with request: URLRequest, completionHandler: @escaping ([String:Any]?, String?) -> Swift.Void) {
    let session = URLSession.shared
    let task = session.dataTask(with: request) {
        (data, response, error) in
        if let error = error  {
            returnError(error.localizedDescription, completionHandler: completionHandler)
            return
        }
        guard let data = data, let _:URLResponse = response else {
            returnError("No error but no data", completionHandler: completionHandler)
            return
        }
        do {
            let parsedJson = try JSONSerialization.jsonObject(with : data, options: .allowFragments)
            guard let json = parsedJson as? [String:Any] else {
                returnError("Wrong Json object", completionHandler: completionHandler)
                return
            }
            if json["result"] as! String != "success" {
                returnError(json["message"] as! String, completionHandler: completionHandler)
                return
            }
            DispatchQueue.main.async {
                completionHandler(json, nil)
            }
        }catch let error as NSError {
            returnError(error.localizedDescription, completionHandler: completionHandler)
            return
        }
    }
    task.resume()
}

private func jsonRequest (servlet: String, params: String, completionHandler: @escaping ([String:Any]?, String?) -> Swift.Void) {
    let url = URL(string: "\(baseUrl)\(servlet)")!
    var request = URLRequest(url:url)
    request.httpMethod = "POST"
    request.httpBody = params.data(using: String.Encoding.utf8)
    request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
    jsonRequest(with: request, completionHandler: completionHandler)
}

struct AutoLogin {
    var username: String
    var password: String
    var autoLogin: String
    var validTo: String
    init (username: String, password: String, autoLogin: String, validTo: String) {
        self.username = username
        self.password = password
        self.autoLogin = autoLogin
        self.validTo = validTo
    }
    
}

func saveAutoLogin (_ autoLogin: AutoLogin) {
    let defaults = UserDefaults.standard
    defaults.setValue(autoLogin.username, forKey: "username")
    defaults.setValue(autoLogin.password, forKey: "password")
    defaults.setValue(autoLogin.autoLogin, forKey: "autoLogin")
    defaults.setValue(autoLogin.validTo, forKey: "validTo")
    defaults.synchronize()
}

func removeAutoLogin () {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: "username")
    defaults.removeObject(forKey: "password")
    defaults.removeObject(forKey: "autoLogin")
    defaults.removeObject(forKey: "validTo")
    defaults.synchronize()
}

func getAutoLogin () -> AutoLogin? {
    let defaults = UserDefaults.standard
    if let username = defaults.string(forKey: "username"), let password = defaults.string(forKey: "password"), let autoLogin = defaults.string(forKey: "autoLogin"), let validTo = defaults.string(forKey: "validTo") {
        return AutoLogin(username: username, password: password, autoLogin: autoLogin, validTo: validTo)
    }
    else {
        return nil
    }
}

func getAutoLogin(username:String, password: String, String email: String? = nil, register: Bool = false, completionHandler: @escaping (AutoLogin?, String?) -> Swift.Void) {
    var params = "username=\(username)&password=\(password)&register=\(register)"
    if email != nil {
        params += "&email=\(email)"
    }
    jsonRequest(servlet: "getAutoLogin", params: params) {
        (json, error) in
        if error != nil {
            completionHandler(nil, error)
        }
        else {
            completionHandler(AutoLogin(username: username, password: password, autoLogin: json!["autoLogin"] as! String, validTo: json!["validTo"] as! String), nil)
        }
    }
}


func searchClosest (latitude: Int, longitude: Int, nb: Int, completionHandler: @escaping ([Address]?, String?) -> Swift.Void) {
    jsonRequest(servlet: "searchClosest", params: "latitude=\(latitude)&longitude=\(longitude)&nb=3") {
        (json, error) in
        if error != nil {
            completionHandler(nil, error)
        }
        else if let streets = json?["streets"] as? [[String: Any]] {
            var addresses = [Address]()
            for street in streets {
                addresses.append(Address(street: street["street"] as! String, district: street["district"] as! Int))
            }
            completionHandler(addresses,nil)
        }
        else {
            completionHandler(nil, "bad format")
        }
    }
}

func searchAddress (pattern: String, nb: Int, completionHandler: @escaping ([Address]?, String?) -> Swift.Void) {
    let patternEncoded = pattern.addingPercentEncodingForQueryParameter()
    jsonRequest(servlet: "searchAddress", params: "pattern=\(patternEncoded)&nbAnswers=\(nb)") {
        (json, error) in
        if error != nil {
            completionHandler(nil, error)
        }
        else if let streets = json?["streets"] as? [[String: Any]] {
            var addresses = [Address]()
            for street in streets {
                addresses.append(Address(street: street["street"] as! String, district: street["district"] as! Int))
            }
            completionHandler(addresses,nil)
        }
        else {
            completionHandler(nil, "bad format")
        }
    }
}

func uploadAndReport(autoLogin: AutoLogin, address: Address, photos: [Photo], completionHandler: @escaping (ProgressType, String) -> Swift.Void) {
    completionHandler(ProgressType.Sending, "\(photos.count) photos restantes")
    uploadAndReport(autoLogin: autoLogin, address: address, photo: photos[0]) {
        (type, message) in
        switch type {
        case .Sending:
            completionHandler(type,message)
        case .Error:
            completionHandler(type,message)
        case .Success:
            let remaining = Array(photos.suffix(from: 1))
            if (remaining.count > 0) {
                uploadAndReport(autoLogin: autoLogin, address: address, photos: remaining, completionHandler: completionHandler)
            }
            else {
                completionHandler(ProgressType.Success, "Photos envoyées")
            }
        }
    }
}

func uploadAndReport(autoLogin: AutoLogin, address: Address, photo: Photo, completionHandler: @escaping (ProgressType, String) -> Swift.Void) {
    let timeZone = TimeZone(identifier: "Europe/Paris")
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = timeZone
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm:ss"
    timeFormatter.timeZone = timeZone
    var parameters: [String: String] = [
        "autoLogin": autoLogin.autoLogin,
        "street": address.street,
        "district": String(address.district),
        "date": dateFormatter.string(from: photo.date),
        "time": timeFormatter.string(from: photo.date)]
    
    if let point = photo.point {
        parameters["latitude"] = String(point.latitude)
        parameters["longitude"] = String(point.longitude)
    }
    
    let data = UIImageJPEGRepresentation(photo.image, 0.9)
    do {
        let request = try createRequest("uploadAndReport", with: parameters, data: data!)
        jsonRequest(with: request) {
            (result, error) in
            if let error = error {
                completionHandler(ProgressType.Error, error)
            }
            else {
                completionHandler(ProgressType.Success, "Photo envoyée")
            }
        }
    }
    catch {
        completionHandler(ProgressType.Error, "Cannot build request")
    }
}
