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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SPTAuth.defaultInstance().clientID = "bbd379abea604abca005f4eca064d395"
        SPTAuth.defaultInstance().redirectURL = NSURL(string: "spotifynd://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope,SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPrivateScope, "user-top-read"]
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.returnFromAppDelegateAuthSession), name: "authSuccessful", object: nil )
    }
    
    
    @IBAction func logginWithSpotifyButtonTapped(sender: AnyObject) {
        showSpotifyAuthViewController()
        print(SPTAuth.spotifyApplicationIsInstalled())
        print(SPTAuth.supportsApplicationAuthentication())
        print(SPTAuth.defaultInstance().allowNativeLogin)
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
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("toHomeScreen", sender: self)
            PlayerController.sharedController.initializePlayer()
        }
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func returnFromAppDelegateAuthSession(){
        if PlayerController.session != nil {
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("toHomeScreen", sender: self)
            PlayerController.sharedController.initializePlayer()
        }
        print(PlayerController.session?.expirationDate)
        print(NSDate())
        } else {
            let alert = UIAlertController(title: "Error Logging In", message: "There was a problem using your Spotify app to log you in. Please use the apps login screen to log into Spotify/nNote that closing the spotify app before using the app may fix this in the future", preferredStyle: .Alert)
            let okay = UIAlertAction(title: "Okay", style: .Default, handler: nil)
            alert.addAction(okay)
            presentViewController(alert, animated: true, completion: { 
                self.showSpotifyAuthViewController()
            })
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
