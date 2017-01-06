//
//  SetLocationViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 04/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class SetLocationViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchField : UITextField!
    @IBOutlet weak var resultsView : UITableView!
    
    var results = [Address]()
    
    private var cancelFlag: OpenParisStreetsCancelFlag!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resultsView.delegate = self
        resultsView.dataSource = self
        
        searchField.becomeFirstResponder()
    }
    
    override func viewWillAppear (_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func searchFieldModified(sender: UITextField) {
        if let oldCancelFlag = cancelFlag {
            oldCancelFlag.cancel()
        }
        let pattern = sender.text!
        if pattern.isEmpty {
            self.results = [Address]()
            self.resultsView.reloadData()
        }
        else {
            let newCancelFlag = OpenParisStreetsCancelFlag()
            cancelFlag = newCancelFlag
            DispatchQueue.global().async {
                searchOpenParisStreets(for: pattern, handler: {
                    (found) in
                    DispatchQueue.main.async {
                        self.results = found
                        self.resultsView.reloadData()
                    }
                }, cancelFlag: newCancelFlag)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = resultsView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row].fullName()
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = results[indexPath.row]
        navigationController!.popViewController(animated: true)
        let previousViewController = self.navigationController?.viewControllers.last as! ViewController
        previousViewController.forceAddress(address)
    }

    
}
