//
//  PhotoViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 02/04/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewController : UIViewController {
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var street: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var size: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    var photo: ServerPhoto?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let photo = photo {
            username?.text = photo.username
            street?.text = photo.location.address.fullName()
            date?.text = "\(photo.date) \(photo.time ?? "")"
            size?.text = photo.size()
            do {
                image?.image = try UIImage(data: Data(contentsOf: getPhotoURL(id: photo.id)))
            } catch {
                print("ERRROR")
            }
        }
    }
}
