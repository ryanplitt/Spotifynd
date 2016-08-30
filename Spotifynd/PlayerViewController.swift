//
//  PlayerViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/29/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    var player: SPTAudioStreamingController?
    

    @IBOutlet weak var albumImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        player = SPTAudioStreamingController.sharedInstance()
        player?.delegate = self
        try! player?.startWithClientId("bbd379abea604abca005f4eca064d395")
        player?.loginWithAccessToken(AuthController.authToken)
        }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playButtonTapped(sender: AnyObject) {
        player?.playSpotifyURI("spotify:track:4jDmJ51x1o9NZB5Nxxc7gY", startingWithIndex: 0, startingWithPosition: 0, callback: { (error) in
            if error != nil {
                print("There was an error playing the track. \(error.localizedDescription)")
            }
            self.player?.queueSpotifyURI("spotify:track:7kJlTKjNZVT26iwiDUVhRm", callback: { (error) in
                if error != nil {
                    print(error.localizedDescription)
                }
            })
        })
    }
    @IBAction func pauseButtonTapped(sender: AnyObject) {
        player?.setIsPlaying(!(player?.playbackState.isPlaying)!, callback: { (error) in
            if error != nil {
                print("There was an error pausing. Probably because the new stuff. See SPTPlaybackState vs SPTAudioController")
            }
        })
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                print(error.localizedDescription)
            }
        })
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
