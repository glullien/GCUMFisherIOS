//
//  PhotoViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 02/04/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var street: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var size: UILabel!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var image: UIImageView!
    
    var photo: ServerPhoto?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scroll.minimumZoomScale=0.1;
        scroll.maximumZoomScale=6.0;
        //scroll.contentSize=CGSize(width: 400, height: 400);
        scroll.delegate=self;
        if let photo = photo {
            username?.text = photo.username
            street?.text = photo.location.address.fullName()
            date?.text = "\(photo.date) \(photo.time ?? "")"
            size?.text = photo.size()
            do {
                image?.image = try UIImage(data: Data(contentsOf: getPhotoURL(id: photo.id)))
                scroll.zoomScale = 0.1
            } catch {
                print("ERRROR")
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")
        //let topInset = 50
        //scroll.contentInset = UIEdgeInsetsMake(CGFloat(topInset), 0, 0, 0)
        //scroll.bounds = CGRect(x: 0, y: 60, width: 100, height: 100)
    }
    
    override func viewDidLayoutSubviews () {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")
        if let i = image.image {
            print("size scroll \(scroll.bounds.width) x \(scroll.bounds.height)")
            print("i \(i.size.width) x \(i.size.height)")
            let zoomWidth = scroll.bounds.width / i.size.width
            let zoomHeight = scroll.bounds.height / i.size.height
            let zoom = min(zoomWidth, zoomHeight)
            print ("zoom \(zoomWidth) \(zoomHeight) \(zoom)")
            scroll.minimumZoomScale = zoom
            scroll.zoomScale = zoom
        }
    }
    
    func layoutSubviews() {
        print("layoutSubviews")
    }
    
    override func viewWillAppear (_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear")
        //navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return image
    }
}
