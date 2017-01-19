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
        progressField.text = "Test de la connection"
        if let username = userNameField.text, let password = passwordField.text {
            let credentials = Credentials(userName: username, password: password)
            DispatchQueue.global().async {
                let access = WebDavAccess(credentials: credentials, error: {
                    error in
                    self.progressField.text = "Mauvais identifiants"
                })
                access.list("") {
                    content in
                    DispatchQueue.main.async {
                        if content.contains ("prefpol") {
                            saveCredentials(credentials)
                            self.navigationController!.popViewController(animated: true)
                            let previousViewController = self.navigationController?.viewControllers.last as! ViewController
                            previousViewController.updateSendButton()
                        }
                        else {
                            self.progressField.text = "Utilisateur mal configuré"
                        }
                    }
                }
            }
        }
    }
    
}
