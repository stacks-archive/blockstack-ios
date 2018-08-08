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
    @IBOutlet weak var putFileButton: UIButton!
    
    override func viewDidLoad() {
        self.updateUI()
    }
    
    @IBAction func signIn() {
        // Address of deployed example web app
        Blockstack.shared.signIn(redirectURI: "https://heuristic-brown-7a88f8.netlify.com/redirect.html",
                                 appDomain: URL(string: "https://heuristic-brown-7a88f8.netlify.com")!) { authResult in
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
        
        self.updateUI()
        
        // Check if signed in
        // checkIfSignedIn()
    }
    
    @IBAction func signOut(_ sender: Any) {
        // Sign user out
        Blockstack.shared.signOut(redirectURI: "myBlockstackApp") { error in
            if let error = error {
                print("sign out failed, error: \(error)")
            } else {
                self.updateUI()
                print("sign out success")
            }
        }
    }
    
    @IBAction func putFileTapped(_ sender: Any) {
        // Put file example
        Blockstack.shared.putFile(to: "test.json", content: "Hello World", encrypt: true) { (publicURL, error) in
            if error != nil {
                print("put file error")
            } else {
                print("put file success \(publicURL!)")

                // Read data from Gaia
                Blockstack.shared.getFile(at: "test.json", decrypt: true, completion: { (response, error) in
                    if error != nil {
                        print("get file error")
                    } else {
                        print("get file success")
                        print(response as Any)
                    }
                })
            }
        }
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            if Blockstack.shared.isSignedIn() {
                // Read user profile data
                let retrievedUserData = Blockstack.shared.loadUserData()
                print(retrievedUserData?.profile?.name as Any)
                let name = retrievedUserData?.profile?.name ?? "Nameless Person"
                self.nameLabel?.text = "Hello, \(name)"
                self.nameLabel?.isHidden = false
                self.signInButton?.isHidden = true
                self.putFileButton.isHidden = false
            } else {
                self.nameLabel?.isHidden = true
                self.signInButton?.isHidden = false
                self.putFileButton.isHidden = true
            }
        }
    }
    
    func checkIfSignedIn() {
        Blockstack.shared.isSignedIn() ? print("currently signed in") : print("not signed in")
    }
}

