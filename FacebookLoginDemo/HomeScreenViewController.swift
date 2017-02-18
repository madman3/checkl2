//
//  HomeScreenViewController.swift
//  FacebookLoginDemo
//
//  Created by Abhinay Varma on 18/02/17.
//  Copyright © 2017 Abhinay Varma. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import ImagePicker
import CoreLocation
import GooglePlaces
import Firebase

class HomeScreenViewController: UIViewController, CLLocationManagerDelegate {

    static let GOOGLE_API_KEY: String = "AIzaSyDI4EX535S7qJN1Cemu4L_OJgjQWSvPUck"
    
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    var ref: FIRDatabaseReference!
    var checkIn = CheckInModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        GMSPlacesClient.provideAPIKey(HomeScreenViewController.GOOGLE_API_KEY)
        ref = FIRDatabase.database().reference()
        placesClient = GMSPlacesClient.shared()
        getCurrentPlace()
        getFacebookProfileInfo()
//        locationManager.delegate = self
//        if CLLocationManager.authorizationStatus() == .notDetermined {
//            locationManager.requestWhenInUseAuthorization()
//        }
//        locationManager.distanceFilter = kCLDistanceFilterNone
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
        self.ref.child("users").child(FBSDKAccessToken.current().userID).setValue(["username": "lalit"])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCurrentPlace() {
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    print("Place name = \(place.name)")
                    self.locationLabel.text = place.formattedAddress
                    self.checkIn.location = place.formattedAddress
                    self.ref.child("users/\(FBSDKAccessToken.current().userID)/location").setValue(place.formattedAddress)
                }
            }
        })
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
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let locationCoordinates = manager.location?.coordinate
//        locationLabel.text = "\(locationCoordinates!.latitude), \(locationCoordinates!.longitude)"
//        
//        let geoCoder = CLGeocoder()
//        
//        geoCoder.reverseGeocodeLocation(manager.location!, completionHandler: {placemarks, error in
//            let placemark = placemarks?[0]
//            if placemark != nil {
//                self.locationLabel.text = "\(placemark?.subLocality ?? ""), \(placemark?.subLocality ?? "")"
//            }
//        })
//    }
    
    @IBAction func postButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func signoutButtonAction(_ sender: Any) {
        FBSDKAccessToken.setCurrent(nil)
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func pickImageAction(_ sender: Any) {
    }
    
    @IBAction func uploadButtonAction(_ sender: Any) {
        let imagePickerController = ImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.imageLimit = 1
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func findLocationAction(_ sender: Any) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }

    @IBAction func submitButtonAction(_ sender: Any) {
        checkIn.message = messageTextView.text
        self.ref.child("images").child(FBSDKAccessToken.current().userID).childByAutoId().setValue(["address": checkIn.location, "message": checkIn.message, "image_url": checkIn.imageUrl])
    }
}

extension HomeScreenViewController: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if images.count > 0 {
            imageView.image = images[0]
        }
        let storageRef = FIRStorage.storage().reference()
        let imagesRef = storageRef.child("images")
        let fileName = "checkInImage.jpg"
        let checkinRef = imagesRef.child(fileName)
        
        let data = UIImageJPEGRepresentation(images[0], 0.6)
        let uploadTask = checkinRef.put(data!, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                print(error ?? "error")
                return
            }
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata.downloadURL
            self.checkIn.imageUrl = downloadURL()?.absoluteString
        }
        print(uploadTask)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        
    }
}

extension HomeScreenViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        locationLabel.text = place.formattedAddress
        self.checkIn.location = place.formattedAddress
        self.ref.child("users/\(FBSDKAccessToken.current().userID!)/location").setValue(place.formattedAddress)
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
