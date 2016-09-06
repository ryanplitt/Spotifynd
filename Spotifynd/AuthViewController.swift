//
//  AuthViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/26/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController, SPTAuthViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logginWithSpotifyButtonTapped(sender: AnyObject) {
        showSpotifyAuthViewController()
    }
    
    func showSpotifyAuthViewController() {
        SPTAuth.defaultInstance().clientID = "bbd379abea604abca005f4eca064d395"
        SPTAuth.defaultInstance().redirectURL = NSURL(string: "spotifynd://callback")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPrivateScope, "user-top-read"]
        
        let windowAuthVC = SPTAuthViewController.authenticationViewController()
        windowAuthVC.delegate = self
        windowAuthVC.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        windowAuthVC.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        self.definesPresentationContext = true
        
        self.presentViewController(windowAuthVC, animated: true, completion: nil)
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
