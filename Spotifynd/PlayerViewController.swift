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
    let player = PlayerController.sharedController.player
    
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setupInitialPlayerAppearance), name: "queueUpdated", object: nil)
        
        self.navigationController?.navigationBarHidden = true
        
        setupSlider()
        setupGestureRecognizers()
    }
    
    override func viewWillAppear(animated: Bool) {
        player?.delegate = self
        player?.playbackDelegate = self
        if player?.playbackState != nil {
            updateUI()
            setPlayPauseButton()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.navigationBarHidden = false
    }
    
    func setupInitialPlayerAppearance() {
        PlayerController.sharedController.initializeFirstTrackForPlaying { (track) in
            self.titleLabel.text = track.name
            self.artistLabel.text = track.artists.first?.name
            QueueController.sharedController.getImageFromURL(track.album.largestCover.imageURL, completion: { (image) in
                self.albumImage.image = image
            })
        }
    }
    
    func setupGestureRecognizers(){
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToDownSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        albumImage.addGestureRecognizer(swipeDown)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToRightSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        albumImage.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToLeftSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        albumImage.addGestureRecognizer(swipeLeft)
    }
    
    func setupPlayer(){
        PlayerController.sharedController.setupPlayer()
    }
    
    func initializePlaylistForPlayback(){
        PlayerController.sharedController.initializePlaylistForPlayback(nil)
        setPlayPauseButton()
    }
    
    
    func setupSlider() {
        sliderPlaybackBar.value = 0
        sliderPlaybackBar.thumbTintColor = .clearColor()
        sliderPlaybackBar.tintColor = UIColor ( red: 0.0042, green: 0.1546, blue: 1.0, alpha: 1.0 )
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
            
            SPTTrack.trackWithURI(NSURL(string: (self.player?.metadata.currentTrack?.uri)!), session: PlayerController.session) { (error, trackdata) in
                let track = trackdata as! SPTTrack
                let imageURL = track.album.largestCover.imageURL
                QueueController.sharedController.getImageFromURL(imageURL, completion: { (image) in
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.albumImage.image = image
                    })
                    
                })
            }
        }
    }
    
    func scrollToSong(){
        dispatch_async(dispatch_get_main_queue()) {
            if PlayerController.sharedController.indexPathRowofCurrentSong != nil {
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: PlayerController.sharedController.indexPathRowofCurrentSong!, inSection: 0), atScrollPosition: .Middle, animated: true)
            }
        }
    }
    
    @IBAction func collapseButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) { 
        }
    }
    
    func respondToDownSwipeGesture(gesture: UIGestureRecognizer) {
        self.dismissViewControllerAnimated(true) {
        }
    }
    
    func respondToRightSwipeGesture(gesture: UIGestureRecognizer) {
        self.backButtonTapped(self)
    }
    
    func respondToLeftSwipeGesture(gesture: UIGestureRecognizer) {
        self.nextButtonTapped(self)
    }
    

    
    @IBAction func playButtonTapped(sender: AnyObject) {
        guard player != nil else { return }
        dispatch_async(dispatch_get_main_queue()) {
            if self.player?.playbackState == nil {
                PlayerController.sharedController.initializePlaylistForPlayback({
                    PlayerController.sharedController.playPauseFuction()
                })
            } else {
                PlayerController.sharedController.playPauseFuction()
            }
        }
        player?.setValue(false, forKey: "repeat")
    }
    
    func setPlayPauseButton(){
        guard player?.playbackState != nil else {
            self.playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
            return
        }
        if self.player?.playbackState.isPlaying == true {
            self.playPauseButton.setImage(UIImage(named: "pause"), forState: .Normal)
        } else {
            self.playPauseButton.setImage(UIImage(named: "play"), forState: .Normal)
        }
    }
    
    @IBAction func nextButtonTapped(sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                print(error.localizedDescription)
            }
        })
        QueueController.sharedController.checkIfQueueMatchesSavedTracks()
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
//        actionsheet.addAction(addMoreSongs)
        actionsheet.addAction(cancel)
        
        presentViewController(actionsheet, animated: true) { 
            // completion
        }
        
        
    }
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        player?.skipPrevious({ (error) in
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
        guard let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath) as? QueueTableViewCell else {return UITableViewCell()}
        
        let song = QueueController.sharedController.queue[indexPath.row]
        let title = song.name
        let artist = song.artists.first!.name!
        
        cell.updateCellWithTrack(title, artist: artist)
        
        if player?.metadata != nil {
            if song.uri.absoluteString == player?.metadata.currentTrack?.uri {
                PlayerController.sharedController.indexPathRowofCurrentSong = indexPath.row
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
    
    
    func audioStreamingDidLogin(audioStreaming: SPTAudioStreamingController!) {
        self.updateUI()
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        setPlayPauseButton()
    }
    
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeMetadata metadata: SPTPlaybackMetadata!) {
        self.updateUI()
        if let currentURI = player?.metadata.currentTrack?.uri {
            let uriArrays = QueueController.sharedController.queue.flatMap({$0.uri.absoluteString})
            PlayerController.sharedController.indexPathRowofCurrentSong = uriArrays.indexOf(currentURI)
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
    
    func audioStreamingDidLogout(audioStreaming: SPTAudioStreamingController!) {
        _ = (try? player?.stop())
        navigationController?.popToRootViewControllerAnimated(true)
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
    
//    
//    override func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
//        return CGRect(x: CGFloat(value), y: 0, width: 1, height: 1)
//    }
}
