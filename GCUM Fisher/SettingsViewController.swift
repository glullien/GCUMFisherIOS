//
//  SettingsViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 19/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController : UIViewController {
    
    let allSizes = [ImageSize.Small, ImageSize.Medium, ImageSize.Maximal]

    @IBOutlet weak var sizeControl : UISegmentedControl!
    @IBOutlet weak var qualityTextLabel : UILabel!
    @IBOutlet weak var qualitySlider : UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let size = getImageSize()
        if let sizeIndex = allSizes.index(of: size) {
            sizeControl.selectedSegmentIndex = sizeIndex
        }
        
        let quality = getImageQuality()
        qualitySlider.value = Float(quality)
        qualityTextLabel.text = "\(Int(quality)) %"
  }
    
    override func viewWillAppear (_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func changeSize(){
        let selected = sizeControl.selectedSegmentIndex
        let size = allSizes[selected]
        saveImageSize(size)
    }

    @IBAction func changeQuality(){
        let quality = Int(qualitySlider.value)
        qualityTextLabel.text = "\(quality) %"
        saveImageQuality(quality)
    }


}
