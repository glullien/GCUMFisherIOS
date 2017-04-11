//
//  ListViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 28/03/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class ListViewCell : UITableViewCell {
    var photo: ServerPhoto?
    
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var like: UIButton!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var gps: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    
    func setPhoto (_ photo: ServerPhoto) {
        self.photo = photo
        username.text = photo.username
        address.text = photo.location.address.fullName()
        gps.text = photo.location.coordinates.point.fullName()
        date.text = photo.date
        time.text = photo.time ?? ""
        like.setLike(photo: photo)
        do {
            let size = photoView.frame
            let data = try Data(contentsOf: getPhotoURL(id: photo.id, maxWidth: Int(size.width),maxHeight: Int(size.height)))
            photoView.image = UIImage(data: data)
        } catch {
            print("ERROR")
        }
    }
    
    @IBAction func like (sender: UIButton) {
        if let autoLogin = getAutoLogin(), let photo = photo {
            self.like.setTitle("⏱", for: .normal)
            toggleLike (autoLogin: autoLogin, photoId: photo.id) {
                result, error in
                if let error = error {
                    self.like.isEnabled = false
                    self.like.setTitle(error, for: .disabled)
                }
                else if let result = result {
                    self.like.setLike(likesCount: result.likesCount, isLiked: result.isLiked)
                    self.photo?.update(from: result)
                }
            }
        }
    }
}

class ListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var listView : UITableView!
    @IBOutlet weak var moreButton : UIButton!
    
    var point: Point?
    
    private var photos: [ServerPhoto]? = nil
    
    func display(error: String) {
        let alert = UIAlertController(title: "Erreur", message: error, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateMore(nbAfter: Int) {
        if nbAfter == 0 {
            self.moreButton.isEnabled = false
            self.moreButton.setTitle("Plus", for: .disabled)
        }
        else {
            self.moreButton.isEnabled = true
            self.moreButton.setTitle("Plus (\(nbAfter))", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listView.delegate = self
        listView.dataSource = self
        
        let afterRequest: (ListResult?, String?) -> Swift.Void = {
            list, error in
            if let error = error {
                self.display(error: error)
            }
            else if let list = list {
                self.updateMore(nbAfter: list.nbAfter)
                self.photos = list.photos
                self.listView.reloadData()
            }
        }
        
        let autoLogin = getAutoLogin()
        if let point = point {
            getPointInfo(autoLogin: autoLogin, point: point, completionHandler: afterRequest)
        }
        else {
            getList(autoLogin: autoLogin, number: 5, after: nil, completionHandler: afterRequest)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.listView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = listView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListViewCell
        let photo = photos![indexPath.row]
        cell.setPhoto(photo)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowPhoto") {
            if let destination = segue.destination as? PhotoViewController, let photo = sender as? ServerPhoto {
                destination.photo = photo
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowPhoto", sender: photos![indexPath.row])
    }
    
    @IBAction func more (sender: UIButton) {
        if point == nil {
            getList(autoLogin: getAutoLogin(), number: 5, after: photos?.last?.id) {
                list, error in
                if let error = error {
                    self.display(error: error)
                }
                else if let list = list {
                    self.updateMore(nbAfter: list.nbAfter)
                    self.photos?.append(contentsOf: list.photos)
                    self.listView.reloadData()
                }
            }
        }
    }
}
