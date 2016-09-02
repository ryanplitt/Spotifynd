//
//  PlayerViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/29/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    var player: SPTAudioStreamingController?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateTableView), name: "queueUpdated", object: nil)
        player = SPTAudioStreamingController.sharedInstance()
        player?.delegate = self
        try! player?.startWithClientId("bbd379abea604abca005f4eca064d395")
        player?.loginWithAccessToken(AuthController.authToken)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
                print("The operation has completed")
            }
        }
    }
    
    @IBAction func playButtonTapped(sender: AnyObject) {
        player?.playSpotifyURI(QueueController.sharedController.spotifyndPlaylist?.playableUri.absoluteString, startingWithIndex: 0, startingWithPosition: 0, callback: { (error) in
            if error != nil {
                print("There was an error playing back the playlist")
            }
        })
    }
    @IBAction func pauseButtonTapped(sender: AnyObject) {
        player?.setIsPlaying(!(player?.playbackState.isPlaying)!, callback: { (error) in
            if error != nil {
                print("There was an error pausing. Probably because the new stuff. See SPTPlaybackState vs SPTAudioController")
            }
            print(self.player?.playbackState.isRepeating)
            print(self.player?.playbackState.isShuffling)
        })
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                print(error.localizedDescription)
            }
        })
    }
    
    func updateTableView(){
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QueueController.sharedController.queue.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = QueueController.sharedController.queue[indexPath.row].name
        cell.detailTextLabel?.text = QueueController.sharedController.queue[indexPath.row].artists.first!.name!
        
        return cell
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeMetadata metadata: SPTPlaybackMetadata!) {
        let image = metadata.currentTrack?.albumCoverArtUri
        print(image)
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
