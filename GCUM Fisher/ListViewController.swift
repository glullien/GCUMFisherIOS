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
    
    private var photos: [ServerPhoto]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listView.delegate = self
        listView.dataSource = self
        
        getList(number: 5, start: nil) {
            list, error in
            if let error = error {
                let alert = UIAlertController(title: "Erreur", message: error, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else if let list = list {
                self.moreButton.setTitle("Plus (\(list.nbAfter))", for: .normal)
                self.photos = list.photos
                self.listView.reloadData()
            }
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
                //photoView.image = try UIImage(data: Data(contentsOf: getPhotoURL(id: photo.id, maxWidth: Int(listView?.frame.size.width ?? 10), maxHeight: 176)))
                print(photoView.frame)
            } catch {
                print("ERRROR")
            }
        }
        return cell
    }
    
}
