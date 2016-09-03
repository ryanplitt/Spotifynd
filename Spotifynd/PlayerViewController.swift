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
    var indexOfCurrentSong: NSIndexPath?
    var indexPathRowofCurrentSong:Int? {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("indexPathChanged", object: nil)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateTableView), name: "queueUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(scrollToSong), name: "indexPathChanged", object: nil)
        player = SPTAudioStreamingController.sharedInstance()
        player?.delegate = self
        player?.playbackDelegate = self
        try! player?.startWithClientId("bbd379abea604abca005f4eca064d395")
        player?.loginWithAccessToken(AuthController.authToken)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
            dispatch_async(dispatch_get_main_queue()) {
                print("The operation has completed")
            }
        }
        QueueController.sharedController.initializeFirstTrackForPlaying(player!) { (track) in
            self.titleLabel.text = track.name
            self.artistLabel.text = track.artists.first?.name
            QueueController.sharedController.getImageFromURL(track.album.largestCover.imageURL, completion: { (image) in
                self.albumImage.image = image
            })
            self.initializePlaylistForPlayback({
                print(self.player?.playbackState)
            })
        }
    }
    
    func initializePlaylistForPlayback(completion: () -> Void){
        self.player!.playSpotifyURI(QueueController.sharedController.spotifyndPlaylist?.uri.absoluteString, startingWithIndex: 0, startingWithPosition: 0) { (error) in
            if error != nil {
                print("There was an error preparing the playlist")
            }
            completion()
        }
    }
    
    func updateUI() {
        updateTableView()
        if self.player?.metadata == nil || self.player?.metadata.currentTrack == nil {
            //            self.albumImage.image = nil
        } else {
            
            self.nextButton.enabled = self.player?.metadata.nextTrack != nil
            self.backButton.enabled = self.player?.metadata.prevTrack != nil
            self.titleLabel.text = self.player?.metadata.currentTrack?.name
            self.artistLabel.text = self.player?.metadata.currentTrack?.artistName
            
            SPTTrack.trackWithURI(NSURL(string: (self.player?.metadata.currentTrack?.uri)!), session: AuthController.session) { (error, trackdata) in
                let track = trackdata as! SPTTrack
                let imageURL = track.album.largestCover.imageURL
                QueueController.sharedController.getImageFromURL(imageURL, completion: { (image) in
                    self.albumImage.image = image
                })
            }
            
        }
        
    }
    
    func scrollToSong(){
        dispatch_async(dispatch_get_main_queue()) {
            guard let indexpath = self.indexOfCurrentSong else {return}
            self.tableView.scrollToRowAtIndexPath(indexpath, atScrollPosition: .Top, animated: true)
            
        }
    }
    
    func playPauseFuction(){
        self.player?.setIsPlaying(!(self.player?.playbackState.isPlaying)!, callback: { (error) in
            if error != nil {
                print("Could not change the playing/pausing state")
            }
            if self.player?.playbackState.isPlaying == true {
                self.playPauseButton.setTitle("Pause", forState: .Normal)
            } else {
                self.playPauseButton.setTitle("Play", forState: .Normal)
            }
        })
    }
    
    @IBAction func playButtonTapped(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.player?.playbackState == nil {
                self.initializePlaylistForPlayback({ 
                    self.playPauseFuction()
                })
            } else {
                self.playPauseFuction()
            }
        }
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                print(error.localizedDescription)
            }
        })
    }
    
    func audioStreamingDidLogin(audioStreaming: SPTAudioStreamingController!) {
        self.updateUI()
    }
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        player?.skipPrevious({ (error) in
            if error != nil {
                print(error.localizedDescription)
            }
        })
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeMetadata metadata: SPTPlaybackMetadata!) {
        self.updateUI()
    }
    
    func updateTableView(){
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QueueController.sharedController.queue.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath) as? QueueTableViewCell else {return UITableViewCell()}
        
        let song = QueueController.sharedController.queue[indexPath.row]
        let title = song.name
        let artist = song.artists.first!.name!
        
        cell.updateCellWithTrack(title, artist: artist)
        
        if player?.metadata != nil {
            if song.uri.absoluteString == player?.metadata.currentTrack?.uri {
                self.indexOfCurrentSong = indexPath
                self.indexPathRowofCurrentSong = indexPath.row
                cell.nowPlayingImage.hidden = false
            } else {
                cell.nowPlayingImage.hidden = true
            }
        }
        return cell
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
