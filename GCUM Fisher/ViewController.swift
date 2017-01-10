//
//  ViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 07/12/2016.
//  Copyright © 2016 Gurvan Lullien. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var images : UICollectionView!
    @IBOutlet weak var position : UILabel!
    
    var photos = [Photo]()
    var nextId = 0
    
    var locationManager: CLLocationManager!
    
    var geoCoder: CLGeocoder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        images.delegate = self
        images.dataSource = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        geoCoder = CLGeocoder()
    }
    
    override func viewWillAppear (_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0]
        geoCoder.reverseGeocodeLocation(userLocation, completionHandler: {
            (placemarks, error) in
            if error != nil {
                debugPrint("ERROR \(error)")
            }
            else if let placemark = placemarks?.first {
                if let postalCodeStr = placemark.postalCode, let postalCode = Int(postalCodeStr), let street = placemark.thoroughfare {
                    let district = postalCode-75000
                    let address = Address (street: street, district: district)
                    self.setGPS (address)
                }
            }
        })
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("ERROR \(error)")
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
    
    @IBAction func clearAllPhotos(sender: UIButton) {
        for  view in images.subviews{
            view.removeFromSuperview()
            photos.removeAll()
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        let photo = Photo(image: chosenImage, id: nextId)
        nextId += 1
        photos.append(photo)
        images.reloadData()
        dismiss(animated:true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
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
        
        return cell
    }
    
    func trashPhoto (sender: UIButton) {
        let id = sender.tag
        photos = photos.filter { $0.id != id }
        images.reloadData()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    }
    
    @IBAction func forceAddress(sender: UIButton) {
        if forcedAddress == nil {
            performSegue(withIdentifier: "SetLocation", sender: nil)
        }
        else {
            forcedAddress = nil
            updatePositionText()
        }
    }
    
    var gpsAddress: Address?
    var forcedAddress: Address?
    
    func setGPS(_ address: Address) {
        gpsAddress = address
        updatePositionText()
    }
    
    func forceAddress(_ address: Address) {
        forcedAddress = address
        updatePositionText()
    }
    
    func updatePositionText() {
        if let forcedAddress = self.forcedAddress {
            position.text = forcedAddress.fullName()
        }
        else if let gpsAddress = self.gpsAddress {
            position.text = gpsAddress.fullName()
        }
        else {
            position.text = "..."
        }
        
    }
    
    @IBAction func sendPhotos(sender: UIButton) {
        if let address = forcedAddress != nil ? forcedAddress : gpsAddress {
            if photos.count != 0 {
                DispatchQueue.global().async {
                    send(address: address, photos: self.photos)
                }
            }
        }
    }
    
}

