//
//  PhotoViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 02/04/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func setLike (likesCount: Int, isLiked: Bool) {
        let color = isLiked ? UIColor.red : UIColor.black
        let connected = getAutoLogin() != nil
        let state = connected ? UIControlState.normal : UIControlState.disabled
        isEnabled = connected
        setTitle("\(likesCount) ♡", for: state)
        setTitleColor(color, for: state)
    }
    
    func setLike (photo: ServerPhoto) {
        setLike (likesCount: photo.likesCount, isLiked: photo.isLiked)
    }
 
}

class PhotoViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var like: UIButton!
    @IBOutlet weak var street: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var size: UILabel!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var image: UIImageView!
    
    var photo: ServerPhoto?
    
    func display(error: String) {
        let alert = UIAlertController(title: "Erreur", message: error, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scroll.minimumZoomScale=1;
        scroll.maximumZoomScale=6.0;
        //scroll.contentSize=CGSize(width: 400, height: 400);
        scroll.delegate=self;
        if let photo = photo {
            username.text = photo.username
            street.text = photo.location.address.fullName()
            date.text = "\(photo.date) \(photo.time ?? "")"
            size.text = photo.size()
            like.setLike(photo: photo)
            do {
                image?.image = try UIImage(data: Data(contentsOf: getPhotoURL(id: photo.id)))
                scroll.zoomScale = 1
            } catch {
                print("ERROR")
            }
        }
        
        /*like.isUserInteractionEnabled=true
        var likeGesture = UIGestureRecognizer(target: self, action: #selector(PhotoViewController.toggleLike))
        //likeGesture.delegate = self
        //likeGesture.numberOfTapsRequired = 1
        //likeGesture.allowedTouchTypes = [UITouchType.direct]
        like.addGestureRecognizer(likeGesture)
        print("readyyyyyyy")*/
  }
    
    private func setZoomToFitImage () {
        if let i = image.image {
            //scroll.contentMode = .scaleAspectFit
            //image.sizeToFit()
            //scroll.contentSize = CGSize(width: image.frame.size.width, height: image.frame.size.height)
            print("size scroll \(scroll.bounds.width) x \(scroll.bounds.height)")
            print("i \(i.size.width) x \(i.size.height)")
            let zoomWidth = scroll.bounds.width / i.size.width
            let zoomHeight = scroll.bounds.height / i.size.height
            let zoom = min(zoomWidth, zoomHeight)
            print ("zoom \(zoomWidth) \(zoomHeight) \(zoom)")
            scroll.minimumZoomScale = 1
            scroll.zoomScale = 1
            //scroll.contentOffset = CGPoint(x: i.size.width, y: i.size.height)
            //scroll.contentMode = .center
            //scroll.contentInset = UIEdgeInsetsMake(i.size.height/2, i.size.width/2, 0, 0)
            //scroll.contentInset = UIEdgeInsetsMake(scroll.bounds.height/2-20, scroll.bounds.width/2-20, 0, 0)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")
        //setZoomToFitImage()
        //let topInset = 50
        //scroll.contentInset = UIEdgeInsetsMake(CGFloat(topInset), 0, 0, 0)
        //scroll.bounds = CGRect(x: 0, y: 60, width: 100, height: 100)
    }
    
    override func viewDidLayoutSubviews () {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews")
        setZoomToFitImage()
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
    
    /*@IBAction func returnToList (segue: UIStoryboardSegue) {
        if let listView = segue.source as? ListViewController {
            listView.listView.reloadData()
        }
    }*/
    
    @IBAction func like (sender: UIButton) {
        if let autoLogin = getAutoLogin(), let photo = photo {
            like.setTitle("⏱", for: .normal)
            toggleLike (autoLogin: autoLogin, photoId: photo.id) {
                result, error in
                if let error = error {
                    self.display(error: error)
                }
                else if let result = result {
                    self.like.setLike(likesCount: result.likesCount, isLiked: result.isLiked)
                    self.photo?.update(from: result)
                }
            }
        }
    }
    
}
