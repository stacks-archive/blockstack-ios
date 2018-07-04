//
//  ViewController.swift
//  Blockstack
//
//  Created by Yukan Liao on 03/27/2018.
//

import UIKit
import Blockstack
import SafariServices

class ViewController: UIViewController {

    @IBOutlet var signInButton: UIButton?
    @IBOutlet var nameLabel: UILabel?

    @IBAction func signIn() {
        Blockstack.shared.signIn(redirectURI: "http://localhost:8080/redirect.html",
                                 appDomain: URL(string: "http://localhost:8080")!) { authResult in
            switch authResult {
                case .success(let userData):
                    print("sign in success")
                    self.handleSignInSuccess(userData: userData)
                case .cancelled:
                    print("sign in cancelled")
                case .failed(let error):
                    print("sign in failed, error: ", error ?? "n/a")
            }
        }
    }
    
    func handleSignInSuccess(userData: UserData) {
        print(userData.profile?.name as Any)
        
        // Read user profile data
        let retrievedUserData = Blockstack.shared.loadUserData()
        print(retrievedUserData?.profile?.name as Any)
        
        DispatchQueue.main.async {
            let name: String? = retrievedUserData?.profile?.name ?? "Nameless Person"
            self.nameLabel?.text = "Hello, \(name!)"
            self.signInButton?.isHidden = true
        }
        
        // Store data on Gaia
        let content: Dictionary<String, String> = ["property": "value"]
        
        Blockstack.shared.putFile(path: "test.json", content: content) { (publicURL, error) in
            if error != nil {
                print("put file error")
            } else {
                print("put file success \(publicURL!)")
                
                // Read data from Gaia
                Blockstack.shared.getFile(path: "test.json", completion: { (response, error) in
                    if error != nil {
                        print("get file error")
                    } else {
                        print("get file success")
                        print(response as Any)
                    }
                })
            }
        }
        
        // Check if signed in
        // checkIfSignedIn()
    }
    
    @IBAction func signOut(_ sender: Any) {
        // Sign user out
        Blockstack.shared.signOut(redirectURI: "http://localhost:8080/redirect.html") { error in
            if let error = error {
                print("sign out failed, error: \(error)")
            } else {
                print("sign out success")
            }
        }
    }
    
    func checkIfSignedIn() {
        Blockstack.shared.isSignedIn() ? print("currently signed in") : print("not signed in")
    }
}

