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
    
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SPTAuth.defaultInstance().tokenSwapURL = NSURL(string: "https://evening-inlet-81851.herokuapp.com/swap")
        SPTAuth.defaultInstance().tokenRefreshURL = NSURL(string: "https://evening-inlet-81851.herokuapp.com/refresh")
        SPTAuth.defaultInstance().clientID = "bbd379abea604abca005f4eca064d395"
        SPTAuth.defaultInstance().redirectURL = NSURL(string: "spotifynd://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope,SPTAuthPlaylistReadPrivateScope, SPTAuthUserLibraryModifyScope ,SPTAuthPlaylistModifyPrivateScope, "user-top-read"]
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.returnFromAppDelegateAuthSession), name: "authSuccessful", object: nil )
    }
    
    override func viewWillLayoutSubviews() {
        if let sessionData = NSUserDefaults.standardUserDefaults().objectForKey(PlayerController.sessionArchiveKey) as? NSData{
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as! SPTSession
            if session.isValid() {
                let activitiyViewController = ActivityViewController(message: "Loading...")
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(activitiyViewController, animated: true, completion: { 
                        PlayerController.session = session
                        PlayerController.authToken = session.accessToken
                        dispatch_async(dispatch_get_main_queue()) {
                            self.performSegueWithIdentifier("toHomeScreen", sender: self)
                            PlayerController.sharedController.initializePlayer()
                        }
                    })
                })
            }
            else {
                let activitiyViewController = ActivityViewController(message: "Loading...")
                dispatch_async(dispatch_get_main_queue(), { 
                    self.presentViewController(activitiyViewController, animated: true, completion: { 
                        SPTAuth.defaultInstance().renewSession(session, callback: { (error, session) in
                            guard error == nil  else {return}
                            print("Renew Session Successfully")
                            PlayerController.session = session
                            PlayerController.authToken = session.accessToken
                            PlayerController.tokenExpirationDate = session.expirationDate
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                self.performSegueWithIdentifier("toHomeScreen", sender: self)
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
            dispatch_async(dispatch_get_main_queue()) {
                self.performSegueWithIdentifier("toHomeScreen", sender: self)
                PlayerController.sharedController.initializePlayer()
            }
        }
    }
    
    
    @IBAction func logginWithSpotifyButtonTapped(sender: AnyObject) {

        showSpotifyAuthViewController()
        print(SPTAuth.spotifyApplicationIsInstalled())
        print(SPTAuth.supportsApplicationAuthentication())
        print(SPTAuth.defaultInstance().allowNativeLogin)
        print(SPTAuth.defaultInstance().hasTokenSwapService)
        print(SPTAuth.defaultInstance().hasTokenRefreshService)
    }
    
    func showSpotifyAuthViewController() {

        
        let windowAuthVC = SPTAuthViewController.authenticationViewController()
            AuthViewController.SPTAuthSharedViewController = windowAuthVC
            windowAuthVC.delegate = self
            windowAuthVC.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            windowAuthVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
            self.definesPresentationContext = true
            
            self.presentViewController(windowAuthVC, animated: false, completion: nil)

    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        print("There was an error logging in. \(error.localizedDescription)")
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        PlayerController.session = session
        PlayerController.authToken = session.accessToken
        PlayerController.sharedController.saveSessionToUserDefaults(session)
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("toHomeScreen", sender: self)
            PlayerController.sharedController.initializePlayer()
        }
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func setupActivityIndicator(){
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
    }
    
    func returnFromAppDelegateAuthSession(){
        activityIndicator.startAnimating()
        if PlayerController.session != nil {
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("toHomeScreen", sender: self)
            PlayerController.sharedController.initializePlayer()
        }
        print(PlayerController.session?.expirationDate)
        print(NSDate())
        } else {
            activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Error Logging In", message: "There was a problem using your Spotify app to log you in. Please use the apps login screen to log into Spotify. Note that closing the spotify app before using the app may fix this in the future", preferredStyle: .Alert)
            let okay = UIAlertAction(title: "Okay", style: .Default, handler: { (_) in
                self.showSpotifyAuthViewController()
            })
            alert.addAction(okay)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
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
