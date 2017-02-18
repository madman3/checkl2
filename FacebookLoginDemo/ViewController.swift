//
//  ViewController.swift
//  FacebookLoginDemo
//
//  Created by Abhinay Varma on 18/02/17.
//  Copyright © 2017 Abhinay Varma. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile","email"]
        loginButton.delegate = self
        loginButton.center = view.center
        view.addSubview(loginButton)
        
        ref = FIRDatabase.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if FBSDKAccessToken.current() != nil {
            launchHomeScreen()
        }
    }

    @IBAction func loginButtonAction(_ sender: Any) {
    }

    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if FBSDKAccessToken.current() != nil {
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if let error = error {
                    print(error)
                    return
                }
                self.getFacebookProfileInfo()
                self.launchHomeScreen()
            }
        }
    }
    
    func launchHomeScreen() {
        if let homeScreenVC = self.storyboard?.instantiateViewController(withIdentifier: "successfullScene") as? HomeScreenViewController {
            self.present(homeScreenVC, animated: true, completion: nil)
        }
    }
    
    func getFacebookProfileInfo() {
        let request = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        let connection = FBSDKGraphRequestConnection();
        connection.add(request, completionHandler: { connection, result, error in
            if (result != nil) {
                if let userData = result as? [String: String] {
                    let user = UserModel()
                    user.userName = userData["name"]
                    user.email = userData["email"]
                    user.gender = userData["gender"]
                    user.id = userData["id"]
                    self.ref.child("users").child(user.id!).setValue(["username": user.userName, "email": user.email, "gender": user.gender, "location": "NA"])
                }
            }
        })
    }
}

