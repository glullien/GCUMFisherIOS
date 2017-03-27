//
//  LoginViewController.swift
//  GCUM Fisher
//
//  Created by Gurvan Lullien on 18/01/2017.
//  Copyright © 2017 Gurvan Lullien. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var userNameField : UITextField!
    @IBOutlet weak var passwordField : UITextField!
    @IBOutlet weak var progressField : UILabel!
    
    @IBAction func go(sender: UIButton) {
        testConnection()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameField.delegate = self
        passwordField.delegate = self
        userNameField.becomeFirstResponder()
    }
    
    override func viewWillAppear (_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool  {
        if textField == userNameField {
            passwordField.becomeFirstResponder()
        }
        else {
            testConnection()
        }
        return true
    }
    
    func testConnection () {
        if let username = userNameField.text, let password = passwordField.text {
            if ((username.characters.count != 0) && (password.characters.count != 0)){
                progressField.text = "Test de la connection"
                getAutoLogin(username: username, password: password) {
                    (autoLogin, error) in
                    if let error = error {
                        self.progressField.text = error
                    }
                    else {
                        saveAutoLogin(autoLogin!)
                        self.navigationController!.popViewController(animated: true)
                        let previousViewController = self.navigationController?.viewControllers.last as! ViewController
                        previousViewController.updateSendButton()
                    }
                }
            }
        }
    }
    
}
