//
//  ViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 07/12/2016.
//  Copyright © 2016 Gurvan Lullien. All rights reserved.
//

import UIKit
import CoreLocation
import ImageIO
import AssetsLibrary

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var images : UICollectionView!
    @IBOutlet weak var position : UILabel!
    @IBOutlet weak var actions : UILabel!
    @IBOutlet weak var sendButton : UIButton!
    @IBOutlet weak var forceAddressButton : UIButton!
    
    var photos = [Photo]()
    var nextId = 0
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        images.delegate = self
        images.dataSource = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        updateSendButton()
        
    }
    
    func updateSendButton() {
        if getAutoLogin() == nil {
            sendButton.isEnabled = true
            sendButton.setTitle("Se connecter", for: UIControlState.normal)
        }
        else {
            sendButton.isEnabled = ((forcedAddress != nil) || (gpsAddress != nil)) && (photos.count != 0) && !sending
            sendButton.setTitle("Envoyez les photos", for: UIControlState.normal)
        }
    }
    
    override func viewWillAppear (_ animated: Bool) {
        //navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [  CLLocation ]) {
        let userLocation = locations[0]
        let latitude = Int(Double(userLocation.coordinate.latitude*1E5))
        let longitude = Int(Double(userLocation.coordinate.longitude*1E5))
        let newLocation = Point(latitude: latitude, longitude: longitude)
        let distanceMoved = location?.distance(from: newLocation) ?? Int.max
        location = newLocation
        
        if distanceMoved > 3 {
            searchClosest(latitude: latitude, longitude: longitude, nb: 3) {
                (addresses, error) in
                if let error = error {
                    self.setGpsErrorMessage(error)
                }
                else if let addresses = addresses {
                    self.setGPS (addresses[0])
                }
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        setGpsErrorMessage (error.localizedDescription)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func takePhoto(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = false
            picker.modalPresentationStyle = .fullScreen
            present(picker, animated: true, completion: nil)
        }
        else {
            debugPrint("CANNOT FIND CAMERA")
        }
    }
    
    @IBAction func choosePhotoLibrary(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
            picker.allowsEditing = false
            picker.modalPresentationStyle = .popover
            self.present(picker, animated: true, completion: nil)
        }
        else {
            debugPrint("CANNOT FIND LIBRARY")
        }
    }
    
    private func clearAllPhotos() {
        for  view in self.images.subviews{
            view.removeFromSuperview()
            self.photos.removeAll()
        }
    }
    
    @IBAction func clearAllPhotos(sender: UIButton) {
        let clearAlert = UIAlertController(title: "Retirer toutes les photos", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        clearAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.clearAllPhotos()
        }))
        clearAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(clearAlert, animated: true, completion: nil)
    }
    
    private func getDate(_ asset: ALAsset?) -> Date {
        var res = Date()
        if let metadata = asset!.defaultRepresentation().metadata() {
            if let exif = metadata["{Exif}"] as? Dictionary<String,Any>{
                if let dateString = exif["DateTimeOriginal"] as? String {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "fr_FR")
                    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                    if let date = formatter.date(from: dateString) {
                        res = date
                        debugPrint("dateString \(dateString) \(res)")
                    }
                }
            }
        }
        return res
    }
    
    private func getPoint(_ asset: ALAsset?) -> Point? {
        var res: Point? = nil
        if let metadata = asset!.defaultRepresentation().metadata() {
            if let gps = metadata["{GPS}"] as? Dictionary<String,Any>{
                if let latitude = gps["Latitude"] as? Double, let longitude = gps["Longitude"] as? Double {
                    res = Point(latitude: Int(latitude*1E5), longitude: Int(longitude*1E5))
                }
            }
        }
        return res
    }
    
    private func addPhoto(image: UIImage, date: Date, point: Point?) {
        let photo = Photo(image: image, date: date, id: nextId, point: point)
        nextId += 1
        photos.append(photo)
        images.reloadData()
        dismiss(animated:true, completion: nil)
        updateSendButton()
    }
    
    private func addPhoto(image: UIImage) {
        addPhoto(image: image, date: Date(), point: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let chosenImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let assetsLibrary = ALAssetsLibrary()
            if let url = info[UIImagePickerControllerReferenceURL] as? URL {
                assetsLibrary.asset(for: url, resultBlock: {
                    (asset: ALAsset?) -> Void in
                    let date = self.getDate(asset)
                    let assetPoint = self.getPoint(asset)
                    let point = (assetPoint != nil) ? assetPoint : (picker.sourceType == .camera) ? self.location : nil
                    self.addPhoto(image: chosenImage, date: date, point: point)
                }, failureBlock: {
                    (error: Error?) -> Void in
                    self.addPhoto(image: chosenImage)
                })
            }
            else {
                let point = (picker.sourceType == .camera) ? self.location : nil
                self.addPhoto(image: chosenImage, date: Date(), point: point)
            }
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated:true, completion: nil)  
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    private func midnight(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }
    
    private func diffDays(from: Date, to upTo: Date) -> Int {
        let calendar = Calendar.current
        debugPrint("diff between \(midnight(from)) \(midnight(upTo))")
        let components = calendar.dateComponents([Calendar.Component.day], from: midnight(from), to: midnight(upTo))
        return components.day!
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
        
        let photo = photos[index]
        let imageView = cell.viewWithTag(1) as! UIImageView
        imageView.image = photo.image
        
        let trashButton = UIButton(type: UIButtonType.system)
        trashButton.setTitle("Retirer", for: UIControlState.normal)
        trashButton.backgroundColor = UIColor.red
        trashButton.tintColor = UIColor.white
        trashButton.tag = photo.id
        trashButton.addTarget(self, action: #selector(self.trashPhoto(sender:)), for: .touchUpInside)
        trashButton.frame = CGRect(x: 8, y: 8, width: 53, height: 18)
        cell.addSubview(trashButton)
        
        let diff = diffDays(from: photo.date, to: Date())
        if diff >= 1 {
            let daysLabel = UILabel()
            daysLabel.text = diff == 1 ? "1 jour" : "\(diff) jours"
            daysLabel.textColor = UIColor.red
            daysLabel.font = UIFont.boldSystemFont(ofSize: 12)
            daysLabel.frame = CGRect(x: 8, y: 25, width: 53, height: 18)
            cell.addSubview(daysLabel)
        }
        
        return cell
    }
    
    func trashPhoto (sender: UIButton) {
        let id = sender.tag
        photos = photos.filter { $0.id != id }
        images.reloadData()
    }
    
    @IBAction func disconnect (sender: UIButton) {
        if getAutoLogin() == nil {
            performSegue(withIdentifier: "Login", sender: nil)
        }
        else {
            let disconnectAlert = UIAlertController(title: "Déconnecter", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            disconnectAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                removeAutoLogin()
                self.updateSendButton()
            }))
            disconnectAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(disconnectAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func openSettings (sender: UIButton) {
        performSegue(withIdentifier: "Settings", sender: nil)
 }
    
    @IBAction func forceAddress(sender: UIButton) {
        if forcedAddress == nil {
            performSegue(withIdentifier: "SetLocation", sender: nil)
        }
        else {
            forcedAddress = nil
            forceAddressButton.setBackgroundImage(UIImage(named: "EditPosition"), for: .normal)
            updatePositionText()
            updateSendButton()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowList") {
            if let destination = segue.destination as? ListViewController {
                destination.point = nil
            }
        }
    }
    
    @IBAction func showList(sender: UIButton) {
        performSegue(withIdentifier: "ShowList", sender: nil)
    }
    
    @IBAction func showMap(sender: UIButton) {
        performSegue(withIdentifier: "ShowMap", sender: nil)
    }
    
    var location: Point?
    var gpsAddress: Address?
    var forcedAddress: Address?
    var gpsError: String?
    
    func setGpsErrorMessage(_ error: String){
        gpsError = error
        gpsAddress = nil
        updatePositionText()
        updateSendButton()
    }
    
    func setGPS(_ address: Address) {
        gpsError = nil
        gpsAddress = address
        updatePositionText()
        updateSendButton()
    }
    
    func forceAddress(_ address: Address) {
        forcedAddress = address
        forceAddressButton.setBackgroundImage(UIImage(named: "Here"), for: .normal)
        updatePositionText()
        updateSendButton()
    }
    
    func updatePositionText() {
        if let forcedAddress = self.forcedAddress {
            position.text = forcedAddress.fullName()
            position.textColor = UIColor.black
        }
        else if let gpsAddress = self.gpsAddress {
            position.text = gpsAddress.fullName()
            position.textColor = UIColor.black
        }
        else if let gpsError = self.gpsError {
            position.text = gpsError
            position.textColor = UIColor.red
        }
        else {
            position.text = "..."
            position.textColor = UIColor.black
        }
    }
    
    var sending = false
    
    @IBAction func sendPhotos(sender: UIButton) {
        if let autoLogin = getAutoLogin() {
            if let address = forcedAddress != nil ? forcedAddress : gpsAddress {
                if photos.count != 0 {
                    sending = true
                    updateSendButton()
                    var finished = false
                    uploadAndReport(autoLogin: autoLogin, address: address, photos: self.photos) {
                        (type: ProgressType, message: String) in
                        if !finished {
                            switch type {
                            case .Sending:
                                self.actions.text = message
                                self.sendButton.isEnabled = false
                            case .Error:
                                self.actions.text = " "
                                self.sending = false
                                self.updateSendButton()
                                finished = true
                                let successAlert = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.alert)
                                successAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                self.present(successAlert, animated: true, completion: nil)
                            case .Success:
                                self.actions.text = " "
                                self.sending = false
                                self.updateSendButton()
                                finished = true
                                self.clearAllPhotos()
                                let successAlert = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.alert)
                                successAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                self.present(successAlert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
        else {
            performSegue(withIdentifier: "Login", sender: nil)
        }
    }
    
}

