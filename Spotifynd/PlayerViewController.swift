//
//  PlayerViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/29/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    static let sharedPlayer = PlayerViewController()
    
    var player: SPTAudioStreamingController?
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
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var sliderPlaybackBar: mySlider!
    @IBOutlet weak var repeatButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateTableView), name: "queueUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(scrollToSong), name: "indexPathChanged", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setupPlayer), name: "queueUpdated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(initializePlaylistForPlayback), name: "playerFailedInitialization", object: nil)
        
        player = SPTAudioStreamingController.sharedInstance()
        player?.delegate = self
        player?.playbackDelegate = self
        try! player?.startWithClientId("bbd379abea604abca005f4eca064d395")
        player?.loginWithAccessToken(AuthController.authToken)
        setupSlider()
    }
    
    func setupPlayer() {
        
        QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
            print("The operation has completed")
            self.initializePlaylistForPlayback({
                print(self.player?.playbackState)
            })
        }
        QueueController.sharedController.initializeFirstTrackForPlaying(player!) { (track) in
            self.titleLabel.text = track.name
            self.artistLabel.text = track.artists.first?.name
            QueueController.sharedController.getImageFromURL(track.album.largestCover.imageURL, completion: { (image) in
                self.albumImage.image = image
            })
            
        }
    }
    
    func setupSlider() {
        sliderPlaybackBar.value = 0
        sliderPlaybackBar.setThumbImage(UIImage(named: "thumb")!, forState: .Normal)
        sliderPlaybackBar.thumbTintColor = .blueColor()
    }
    
    func initializePlaylistForPlayback(completion: (() -> Void)?){
        let qualityOfService = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfService, 0)
        dispatch_async(backgroundQueue) { 
            SPTPlaylistSnapshot.playlistWithURI(QueueController.sharedController.spotifyndPlaylist?.uri, session: AuthController.session) { (error, playlistData) in
                let playlist = playlistData as! SPTPlaylistSnapshot
                let firstpage = playlist.firstTrackPage
                guard let firstSong = firstpage?.items?.first as? SPTPartialTrack else {return}
                guard firstSong.name == QueueController.sharedController.queue.first?.name else {
                    sleep(1)
                    print("The tracks didn't match")
                    self.initializePlaylistForPlayback(nil)
                    return
                }
                self.player!.playSpotifyURI(QueueController.sharedController.spotifyndPlaylist?.uri.absoluteString, startingWithIndex: 0, startingWithPosition: 0) { (error) in
                    if error != nil {
                        print("There was an error preparing the playlist")
                        sleep(1)
                        self.initializePlaylistForPlayback(nil)
                    }
                    self.player?.setIsPlaying(false, callback: { (error) in
                        if error != nil {
                            print("There was an error setting the player to pause.")
                        }
                    })
                    completion?()
                }
            }
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
            if self.indexPathRowofCurrentSong != nil {
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.indexPathRowofCurrentSong!, inSection: 0), atScrollPosition: .Middle, animated: true)
            }
        }
    }
    @IBAction func collapseButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { 
            HomeScreenViewController.load()
        }
    }
    
    func playPauseFuction(){
        self.player?.setIsPlaying(!(self.player?.playbackState.isPlaying)!, callback: { (error) in
            if error != nil {
                print("Could not change the playing/pausing state")
            }
            
        })
        
    }
    
    @IBAction func playButtonTapped(sender: AnyObject) {
        guard player != nil else { return }
        dispatch_async(dispatch_get_main_queue()) {
            if self.player?.playbackState == nil {
                self.initializePlaylistForPlayback({ 
                    self.playPauseFuction()
                })
            } else {
                self.playPauseFuction()
            }
        }
        guard player?.playbackState != nil else { return }
        if self.player?.playbackState.isPlaying == true {
            self.playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
        } else {
            self.playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
        }
        player?.setValue(false, forKey: "repeat")
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                print(error.localizedDescription)
            }
        })
    }
    
    @IBAction func repeatButtonTapped(sender: AnyObject) {
        // TODO:
        guard player != nil && player?.playbackState != nil else {return}
        if player?.playbackState.isRepeating == true {
            player?.setValue(false, forKey: "repeat")
        }
        if player?.playbackState.isRepeating == false {
            player?.setValue(true, forKey: "repeat")
        }
    }
    
    @IBAction func moreButtonTapped(sender: AnyObject) {
        let actionsheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let removeArtistTracks = UIAlertAction(title: "Remove Tracks From This Artist", style: .Default) { (_) in
            let currentArtistName = self.player?.metadata.currentTrack?.artistName
            self.player?.skipNext({ (error) in
                if error != nil {
                    print("There was an error skipping the track")
                }
            })
            QueueController.sharedController.removeTracksArtistFromQueue(currentArtistName!, completion: {
                    self.tableView.reloadData()
                })
        }
        
        let addMoreSongs = UIAlertAction(title: "Add More Songs Like This", style: .Default) { (_) in
            // TODO: Add More songs using QueueController function
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in
        }
        
        actionsheet.addAction(removeArtistTracks)
        actionsheet.addAction(addMoreSongs)
        actionsheet.addAction(cancel)
        
        presentViewController(actionsheet, animated: true) { 
            // completion
        }
        
        
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
        if let currentURI = player?.metadata.currentTrack?.uri {
            let uriArrays = QueueController.sharedController.queue.flatMap({$0.uri.absoluteString})
            self.indexPathRowofCurrentSong = uriArrays.indexOf(currentURI)
        }
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePosition position: NSTimeInterval) {
        if let duration = self.player?.metadata.currentTrack?.duration {
            self.sliderPlaybackBar.value = Float(Double(position)/Double(duration))
        }
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeRepeatStatus isRepeated: Bool) {
        if isRepeated {
        repeatButton.setImage(UIImage(named: "repeat"), forState: .Normal)
        } else {
            repeatButton.setImage(UIImage(named: "repeat-empty"), forState: .Normal)
        }
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
                self.indexPathRowofCurrentSong = indexPath.row
                cell.nowPlayingImage.hidden = false
            } else {
                cell.nowPlayingImage.hidden = true
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        player?.playSpotifyURI(QueueController.sharedController.spotifyndPlaylist?.uri.absoluteString, startingWithIndex: UInt(indexPath.row), startingWithPosition: 0, callback: { (error) in
            if error != nil {
                print("There was a problem playing the selected track")
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

class mySlider: UISlider {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func minimumValueImageRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectZero
    }
    
    override func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        return super.thumbRectForBounds(
            bounds, trackRect: rect, value: value)
    }
}
