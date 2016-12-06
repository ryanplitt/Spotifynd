//
//  PlayerViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/29/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
    @IBOutlet weak var sliderPlaybackBar: UISlider!
    @IBOutlet weak var repeatButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: NSNotification.Name(rawValue: "queueUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToSong), name: NSNotification.Name(rawValue: "indexPathChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupPlayer), name: NSNotification.Name(rawValue: "setupPlayer"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupInitialPlayerAppearance), name: NSNotification.Name(rawValue: "setupAppearance"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: NSNotification.Name(rawValue: "updateUI"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setPlayPauseButton), name: NSNotification.Name(rawValue: "isPlayingValueChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSlider), name: NSNotification.Name(rawValue: "updatingPostionOfTrack"), object: nil)
        
        setupGestureRecognizers()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupSlider()
        if player?.playbackState != nil {
            updateUI()
            setPlayPauseButton()
        }
    }
    
    
    func setupGestureRecognizers(){
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToDownSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        albumImage.addGestureRecognizer(swipeDown)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToRightSwipeGesture))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        albumImage.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToLeftSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        albumImage.addGestureRecognizer(swipeLeft)
    }
    
    
    func setupInitialPlayerAppearance() {
        PlayerController.sharedController.initializeFirstTrackForPlaying { (track) in
            self.titleLabel.text = track.name
            self.artistLabel.text = (track.artists?.first as AnyObject).name
            guard let url = track.album?.largestCover?.imageURL else {return}
            QueueController.sharedController.getImageFromURL(url, completion: { (image) in
                self.albumImage.image = image
            })
        }
    }
    
    func setupPlayer(){
        PlayerController.sharedController.setupPlayerFromQueue { 
            
        }
    }
    
    func initializePlaylistForPlayback(){
        PlayerController.sharedController.initializePlaylistForPlayback(nil)
        setPlayPauseButton()
    }
    
    
    func setupSlider() {
        sliderPlaybackBar.value = 0
        sliderPlaybackBar.tintColor = UIColor ( red: 0.0042, green: 0.1546, blue: 1.0, alpha: 1.0 )
        sliderPlaybackBar.setThumbImage(UIImage(named: "thumb0"), for: UIControlState())
    }
    
    func updateSlider(){
        guard let position = PlayerController.sharedController.positionOfCurrentTrack,
            let duration = PlayerController.sharedController.player?.metadata.currentTrack?.duration else {return}
        sliderPlaybackBar.value = Float(position/duration)
    }
    
    
    
    func updateUI() {
        updateTableView()
        if self.player?.metadata == nil || self.player?.metadata.currentTrack == nil {
                        self.albumImage.image = nil
        } else {
            
            self.nextButton.isEnabled = self.player?.metadata.nextTrack != nil
            self.backButton.isEnabled = self.player?.metadata.prevTrack != nil
            self.titleLabel.text = self.player?.metadata.currentTrack?.name
            self.artistLabel.text = self.player?.metadata.currentTrack?.artistName
            
            SPTTrack.track(withURI: URL(string: (self.player?.metadata.currentTrack?.uri)!), session: PlayerController.session) { (error, trackdata) in
                let track = trackdata as! SPTTrack
                let imageURL = track.album?.largestCover?.imageURL
                guard let image = imageURL else {return}
                QueueController.sharedController.getImageFromURL(image, completion: { (image) in
                    DispatchQueue.main.async(execute: { 
                        self.albumImage.image = image
                        PlayerController.sharedController.currentSongAlbumArtwork = image
                        guard let playbackTrack = self.player?.metadata?.currentTrack else {return}
                        PlayerController.sharedController.setMPNowPlayingInfoCenterForTrack(playbackTrack)
                    })
                })
            }
        }
    }
    
    func scrollToSong(){
        DispatchQueue.main.async {
            if PlayerController.sharedController.indexPathRowofCurrentSong != nil {
                self.tableView.scrollToRow(at: IndexPath(row: PlayerController.sharedController.indexPathRowofCurrentSong!, section: 0), at: .middle, animated: true)
            }
        }
    }
    
    func toggleRepeat(){
        if !(PlayerController.sharedController.player?.playbackState?.isRepeating)! {
            repeatButton.setImage(UIImage(named: "repeat"), for: UIControlState())
        } else {
            repeatButton.setImage(UIImage(named: "repeat-empty"), for: UIControlState())
        }
    }
    
    @IBAction func collapseButtonTapped(_ sender: AnyObject) {
        self.dismiss(animated: true) { 
        }
    }
    
    func respondToDownSwipeGesture(_ gesture: UIGestureRecognizer) {
        self.dismiss(animated: true) {
        }
    }
    
    func respondToRightSwipeGesture(_ gesture: UIGestureRecognizer) {
        self.backButtonTapped(self)
    }
    
    func respondToLeftSwipeGesture(_ gesture: UIGestureRecognizer) {
        self.nextButtonTapped(self)
    }
    
    
    
    @IBAction func playButtonTapped(_ sender: AnyObject) {
        guard player != nil else { return }
        DispatchQueue.main.async {
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
            self.playPauseButton.setImage(UIImage(named: "pause"), for: UIControlState())
            return
        }
        if self.player?.playbackState.isPlaying == true {
            self.playPauseButton.setImage(UIImage(named: "pause"), for: UIControlState())
        } else {
            self.playPauseButton.setImage(UIImage(named: "play"), for: UIControlState())
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: AnyObject) {
        player?.skipNext({ (error) in
            if error != nil {
                print(error?.localizedDescription)
            }
        })
    }
    
    @IBAction func repeatButtonTapped(_ sender: AnyObject) {
        // TODO:
        guard player != nil && player?.playbackState != nil else {return}
        if player?.playbackState.isRepeating == true {
            player?.setValue(false, forKey: "repeat")
            self.toggleRepeat()
        }
        if player?.playbackState.isRepeating == false {
            player?.setValue(true, forKey: "repeat")
            self.toggleRepeat()
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: AnyObject) {
        let actionsheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let removeArtistTracks = UIAlertAction(title: "Remove Tracks From This Artist", style: .default) { (_) in
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
        
        let addMoreSongs = UIAlertAction(title: "Add More Songs Like This", style: .default) { (_) in
            QueueController.sharedController.addMoreSongsBasedOnThisArtist()
        }
        
        let addToSaved = UIAlertAction(title: "Add Song To Saved Tracks", style: .default) { (_) in
            PlayerController.sharedController.addSongToSavedTracks()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }
        
        actionsheet.addAction(removeArtistTracks)
//      actionsheet.addAction(addMoreSongs)
        
        PlayerController.sharedController.isSongInSavedTracks { (success) in
            if success{
                actionsheet.addAction(addToSaved)
            }
        }
        
        
        actionsheet.addAction(cancel)
        
        present(actionsheet, animated: true) { 
            // completion
        }
        
        
    }
    
    @IBAction func backButtonTapped(_ sender: AnyObject) {
        player?.skipPrevious({ (error) in
            if error != nil {
                print(error?.localizedDescription)
            }
        })
    }
    
    func updateTableView(){
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return QueueController.sharedController.queue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "queueCell", for: indexPath) as? QueueTableViewCell else {return UITableViewCell()}
        
        let song = QueueController.sharedController.queue[indexPath.row]
        let title = song.name!
        let artist = (song.artists.first! as! SPTPartialArtist).name!
        
        cell.updateCellWithTrack(title, artist: artist)
        
        if player?.metadata != nil {
            if song.uri.absoluteString == player?.metadata.currentTrack?.uri {
                PlayerController.sharedController.indexPathRowofCurrentSong = indexPath.row
                cell.nowPlayingImage.isHidden = false
            } else {
                cell.nowPlayingImage.isHidden = true
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player?.playSpotifyURI(QueueController.sharedController.spotifyndPlaylist?.uri.absoluteString, startingWith: UInt(indexPath.row), startingWithPosition: 0, callback: { (error) in
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
