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
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var like: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var gps: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var photo: UIImageView!
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
        
        if let point = point {
            getPointInfo(point: point, completionHandler: afterRequest)
        }
        else {
            getList(number: 5, after: nil, completionHandler: afterRequest)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = listView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListViewCell
        let photo = photos![indexPath.row]
        cell.username?.text = photo.username
        cell.address?.text = photo.location.address.fullName()
        cell.gps?.text = photo.location.coordinates.point.fullName()
        cell.date?.text = photo.date
        cell.time?.text = photo.time ?? ""
        if let photoView = cell.photo {
            do {
                photoView.image = try UIImage(data: Data(contentsOf: getPhotoURL(id: photo.id, maxWidth: Int(photoView.frame.width), maxHeight: Int(photoView.frame.height))))
            } catch {
                print("ERRROR")
            }
        }
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
            getList(number: 5, after: photos?.last?.id) {
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
