//
//  Server.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 24/03/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

//let baseUrl = "https://www.gcum.lol/"
let baseUrl = "http://192.168.1.13:8080/"
//let baseUrl = "http://192.168.62.233:8080/"

private func returnError<R> (_ error: String, completionHandler: @escaping (R?, String?) -> Swift.Void) {
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

private func getRequest (servlet: String, params: String) -> URLRequest {
    let url = URL(string: "\(baseUrl)\(servlet)")!
    var request = URLRequest(url:url)
    request.httpMethod = "POST"
    request.httpBody = params.data(using: String.Encoding.utf8)
    request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
    return request
}

private func jsonRequest (servlet: String, params: String, completionHandler: @escaping ([String:Any]?, String?) -> Swift.Void) {
    let url = URL(string: "\(baseUrl)\(servlet)")!
    var request = URLRequest(url:url)
    request.httpMethod = "POST"
    request.httpBody = params.data(using: String.Encoding.utf8)
    request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
    jsonRequest(with: getRequest(servlet: servlet, params: params), completionHandler: completionHandler)
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

enum CoordinatesSource: String {
    case Street
    case Device
}

struct Coordinates {
    var source: CoordinatesSource
    var point: Point
    init(source: CoordinatesSource, point: Point) {
        self.source = source
        self.point = point
    }
}
struct Location {
    var address: Address
    var coordinates: Coordinates
    init(address: Address, coordinates: Coordinates) {
        self.address = address
        self.coordinates = coordinates
    }
}
struct ServerPhoto {
    var id: String
    var date: String
    var time: String?
    var location: Location
    var username: String?
    var likesCount: Int
    var isLiked: Bool
    init(id: String, date: String, time: String?, location: Location, username: String?, likesCount: Int, isLiked: Bool) {
        self.id = id
        self.date = date
        self.time = time
        self.location = location
        self.username = username
        self.likesCount = likesCount
        self.isLiked = isLiked
    }
}
struct ListResult {
    var photos: [ServerPhoto]
    var nbAfter: Int
    init(photos: [ServerPhoto], nbAfter: Int) {
        self.photos = photos
        self.nbAfter = nbAfter
    }
}

private func getServerPhoto(_ photo: [String: Any]) -> ServerPhoto {
    let address = Address(street: photo["street"] as! String, district: photo["district"] as! Int)
    let point = Point(latitude: photo["latitude"] as! Int, longitude: photo["longitude"] as! Int)
    let source = CoordinatesSource(rawValue: photo["locationSource"] as! String)
    let coordinates = Coordinates(source: source!, point: point)
    let location = Location(address: address, coordinates: coordinates)
    return ServerPhoto(
        id: photo["id"] as! String,
        date: photo["date"] as! String,
        time: photo["time"] as? String,
        location: location,
        username: photo["username"] as? String,
        likesCount: photo["likesCount"] as! Int,
        isLiked: photo["isLiked"] as! Bool)
}

func getList (number: Int, start: String?, completionHandler: @escaping (ListResult?, String?) -> Swift.Void) {
    jsonRequest(servlet: "getList", params: "number=\(number)&district=All&sort=date") {
        (json, error) in
        if error != nil {
            completionHandler(nil, error)
        }
        else {
            var photos = [ServerPhoto]()
            for photo in json?["photos"] as! [[String: Any]] {
                photos.append(getServerPhoto(photo))
            }
            completionHandler(ListResult(photos: photos, nbAfter: json?["nbAfter"] as! Int),nil)
        }
    }
}

func getPointInfo (point: Point, completionHandler: @escaping (ListResult?, String?) -> Swift.Void) {
    jsonRequest(servlet: "getPointInfo", params: "latitude=\(point.latitude)&longitude=\(point.longitude)&timeFrame=All&locationSources=Street,Device&authors=-All-") {
        (json, error) in
        if error != nil {
            completionHandler(nil, error)
        }
        else {
            var photos = [ServerPhoto]()
            for photo in json?["photos"] as! [[String: Any]] {
                photos.append(getServerPhoto(photo))
            }
            completionHandler(ListResult(photos: photos, nbAfter: 0),nil)
        }
    }
}

struct ServerPoint {
    let point: Point
    let street: String
    let district: Int
    let dates: String
    let nbPhotos: Int
    let latestId: String
    init (point: Point, street: String, district: Int, dates: String, nbPhotos: Int, latestId: String) {
        self.point = point
        self.street = street
        self.district = district
        self.dates = dates
        self.nbPhotos = nbPhotos
        self.latestId = latestId
    }
}

func getPoints (completionHandler: @escaping ([ServerPoint]?, String?) -> Swift.Void) {
    jsonRequest(servlet: "getPoints", params: "zone=All&locationSources=Street,Device&timeFrame=All&authors=-All-") {
        (json, error) in
        if error != nil {
            completionHandler(nil, error)
        }
        else {
            var points = [ServerPoint]()
            for point in json?["photos"] as! [[String: Any]] {
                points.append(ServerPoint(
                    point: Point(latitude: point["latitude"] as! Int, longitude: point["longitude"] as! Int),
                    street: point["street"] as! String,
                    district: point["district"] as! Int,
                    dates: point["dates"] as! String,
                    nbPhotos: point["nbPhotos"] as! Int,
                    latestId: point["latestId"] as! String))
            }
            completionHandler(points,nil)
        }
    }
}
    
func getPhotoURL(id: String, maxWidth: Int, maxHeight: Int) -> URL {
    return URL(string: "\(baseUrl)getPhoto?id=\(id)&maxWidth=\(maxWidth)&maxHeight=\(maxHeight)")!
}

func getPhoto (id: String, maxWidth: Int, maxHeight: Int, completionHandler: @escaping (UIImage?, String?) -> Swift.Void) {
    let request = getRequest(servlet: "getPhoto", params: "id=\(id)&maxWidth=\(maxWidth)&maxHeight=\(maxHeight)")
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
        DispatchQueue.main.async {
            completionHandler(UIImage(data: data), nil)
        }
    }
    task.resume()
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
