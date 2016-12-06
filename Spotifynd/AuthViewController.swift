//
//  AuthViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/26/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController, SPTAuthViewDelegate {

    
    static var SPTAuthSharedViewController: SPTAuthViewController?
    
    var hasValidSession: Bool?
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SPTAuth.defaultInstance().tokenSwapURL = URL(string: "https://evening-inlet-81851.herokuapp.com/swap")
        SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "https://evening-inlet-81851.herokuapp.com/refresh")
        SPTAuth.defaultInstance().clientID = "bbd379abea604abca005f4eca064d395"
        SPTAuth.defaultInstance().redirectURL = URL(string: "spotifynd://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope,SPTAuthPlaylistReadPrivateScope, SPTAuthUserLibraryModifyScope ,SPTAuthPlaylistModifyPrivateScope, "user-top-read"]
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnFromAppDelegateAuthSession), name: NSNotification.Name(rawValue: "authSuccessful"), object: nil )
    }
    
    override func viewWillLayoutSubviews() {
        if let sessionData = UserDefaults.standard.object(forKey: PlayerController.sessionArchiveKey) as? Data{
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as! SPTSession
            if session.isValid() {
                let activitiyViewController = ActivityViewController(message: "Loading...")
                DispatchQueue.main.async(execute: {
                    self.present(activitiyViewController, animated: true, completion: { 
                        PlayerController.session = session
                        PlayerController.authToken = session.accessToken
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "toHomeScreen", sender: self)
                            PlayerController.sharedController.initializePlayer()
                        }
                    })
                })
            }
            else {
                let activitiyViewController = ActivityViewController(message: "Loading...")
                DispatchQueue.main.async(execute: { 
                    self.present(activitiyViewController, animated: true, completion: { 
                        SPTAuth.defaultInstance().renewSession(session, callback: { (error, session) in
                            guard error == nil  else {return}
                            print("Renew Session Successfully")
                            PlayerController.session = session
                            PlayerController.authToken = session?.accessToken
                            PlayerController.tokenExpirationDate = session?.expirationDate
                            DispatchQueue.main.async {
                                
                                self.performSegue(withIdentifier: "toHomeScreen", sender: self)
                                PlayerController.sharedController.initializePlayer()
                            }
                        })
                    })
                })
            }
        }
    }
    
    func checkSessionAuth(){
        guard let auth = SPTAuth.defaultInstance() else {print("The Auth Instance was nil") ; return}
        guard let session = auth.session else {print("The session was nil") ; return }
                if session.isValid() {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toHomeScreen", sender: self)
                PlayerController.sharedController.initializePlayer()
            }
        }
    }
    
    
    @IBAction func logginWithSpotifyButtonTapped(_ sender: AnyObject) {

        showSpotifyAuthViewController()
        print(SPTAuth.spotifyApplicationIsInstalled())
        print(SPTAuth.supportsApplicationAuthentication())
        print(SPTAuth.defaultInstance().allowNativeLogin)
        print(SPTAuth.defaultInstance().hasTokenSwapService)
        print(SPTAuth.defaultInstance().hasTokenRefreshService)
    }
    
    func showSpotifyAuthViewController() {

        
        let windowAuthVC = SPTAuthViewController.authentication()
            AuthViewController.SPTAuthSharedViewController = windowAuthVC
            windowAuthVC?.delegate = self
            windowAuthVC?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            windowAuthVC?.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            self.modalPresentationStyle = UIModalPresentationStyle.currentContext
            self.definesPresentationContext = true
            
            self.present(windowAuthVC!, animated: false, completion: nil)

    }
    
    func authenticationViewController(_ authenticationViewController: SPTAuthViewController!, didFailToLogin error: Error!) {
        print("There was an error loggin in. \(error.localizedDescription)")
    }
    
    func authenticationViewController(_ authenticationViewController: SPTAuthViewController!, didLoginWith session: SPTSession!) {
        PlayerController.session = session
        PlayerController.authToken = session.accessToken
        PlayerController.sharedController.saveSessionToUserDefaults(session)
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toHomeScreen", sender: self)
            PlayerController.sharedController.initializePlayer()
        }
    }
    
    func authenticationViewControllerDidCancelLogin(_ authenticationViewController: SPTAuthViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupActivityIndicator(){
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
    }
    
    func returnFromAppDelegateAuthSession(){
        activityIndicator.startAnimating()
        if PlayerController.session != nil {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toHomeScreen", sender: self)
            PlayerController.sharedController.initializePlayer()
        }
        print(PlayerController.session?.expirationDate)
        print(Date())
        } else {
            activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Error Logging In", message: "There was a problem using your Spotify app to log you in. Please use the apps login screen to log into Spotify. Note that closing the spotify app before using the app may fix this in the future", preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                self.showSpotifyAuthViewController()
            })
            alert.addAction(okay)
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func prepareForUnwind(_ segue: UIStoryboardSegue){
        
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     if segue.identifier == "toHomeScreen" {
     print("A string")
     }
     
     
     }
     */
}
