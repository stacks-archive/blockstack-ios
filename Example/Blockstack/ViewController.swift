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

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var resetKeychainButton: UIButton!
    @IBOutlet var signInButton: UIButton!

    override func viewDidLoad() {
        self.updateUI()
    }
    
    @IBAction func signIn() {
        // Address of deployed example web app
        Blockstack.shared.signIn(redirectURI: "https://pedantic-mahavira-f15d04.netlify.com/redirect.html",
                                 appDomain: URL(string: "https://pedantic-mahavira-f15d04.netlify.com")!, scopes: ["store_write", "publish_data"]) { authResult in
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
        Blockstack.shared.signOut()
        self.updateUI()
    }
    
    @IBAction func resetDeviceKeychain(_ sender: Any) {
        Blockstack.shared.promptClearDeviceKeychain(redirectUri: "myBlockstackApp") { error in
            if let error = error {
                print("sign out failed, error: \(error)")
            } else {
                print("sign out success")
            }
        }
    }
    
    @IBAction func putFileTapped(_ sender: Any) {
        // Put file example
        let alert = UIAlertController(title: "Put File", message: "Type a message to put in the file:", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Hello world!"
        }
        self.present(alert, animated: true, completion: nil)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? "Default Text"
            Blockstack.shared.putFile(to: "testFile", text: text, encrypt: false) { (publicURL, error) in
                if error != nil {
                    print("put file error")
                } else {
                    print("put file success \(publicURL!)")
                }
            }
        })
    }
    
    @IBAction func getFileTapped(_ sender: Any) {
        // Read data from Gaia
        Blockstack.shared.getFile(at: "testFile") { response, error in
            if error != nil {
                print("get file error")
            } else {
                print("get file success")
                print(response as Any)

                let text = response as? String ?? "Invalid Content: Try putting something first!"
                let alert = UIAlertController(title: "Get File", message: text, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func multiplayerGetFileTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Multiplayer Get File", message: "What is the Blockstack ID of the other user?\n\nNote: this will only work if the other user has PUT the file using this sample app.", preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "i.e. testuser.id"
        }
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            guard let userID = alert.textFields?.first?.text else {
                let errorAlert = UIAlertController(title: "Oops!", message: "You must enter a valid ID.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(errorAlert, animated: true)
                return
            }
            // Read data from Gaia
            Blockstack.shared.getFile(at: "testFile", username: userID) { response, error in
                if error != nil {
                    print("get file error")
                } else {
                    print("get file success")
                    print(response as Any)
                    let text = response as? String ?? "Oops--something went wrong."
                    let errorAlert = UIAlertController(title: "Get File Result", message: text, preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true)
                }
            }
        })
        self.present(alert, animated: true)
    }
    
    private func updateUI() {
        DispatchQueue.main.async {
            if Blockstack.shared.isSignedIn() {
                // Read user profile data
                let retrievedUserData = Blockstack.shared.loadUserData()
                print(retrievedUserData?.profile?.name as Any)
                self.nameLabel.text =
                    retrievedUserData?.profile?.name ?? "Nameless User"
                self.optionsContainerView.isHidden = false
                self.signInButton.isHidden = true
                self.resetKeychainButton.isHidden = true
            } else {
                self.optionsContainerView.isHidden = true
                self.signInButton.isHidden = false
                self.resetKeychainButton.isHidden = false
            }
        }
    }
    
    func checkIfSignedIn() {
        Blockstack.shared.isSignedIn() ? print("currently signed in") : print("not signed in")
    }
}

