//
//  HomeScreenViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/28/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class HomeScreenViewController: UIViewController, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, SearchResultsControllerDelegate, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {

    
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playPauseButtonOutlet: UIButton!
    @IBOutlet weak var miniPlayerView: UIView!
    
    
    @IBOutlet weak var tableView: UITableView!
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateTableView), name: "topArtistLoaded", object: nil)
        SearchController.sharedController.getUsersTopArtistsForHomeScreen()
        setupSearchController()
        tableView.tableHeaderView = searchController?.searchBar
        QueueController.sharedController.checkIfSpotifyndPlaylistExists { (success) in
            if success {
                print(success)
            } else {
                QueueController.sharedController.createSpotifyPlaylistFromQueueArray()
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        let player = PlayerController.sharedController.player
        player?.delegate = self
        player?.playbackDelegate = self
        setupMiniPlayer()
        setPlayPauseButton()
    }
    
    func setupSearchController(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultsController = storyboard.instantiateViewControllerWithIdentifier("resultsVC") as! SearchResultsTableViewController
        
        searchController = UISearchController(searchResultsController: resultsController)
        
        guard let searchController = searchController else {return}
        
        resultsController.delegate = self
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.placeholder = "Search for an Artist"
        searchController.definesPresentationContext = true
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
            resultsController = searchController.searchResultsController as? SearchResultsTableViewController else {return}
        
        dispatch_async(dispatch_get_main_queue()) {
            SearchController.searchForArtist(text, completion: { 
                resultsController.tableView.reloadData()
            })
        }
    }
    
    func didSelectedCell(partialArtist: SPTPartialArtist) {
        self.dismissViewControllerAnimated(true) {
            self.searchController?.searchBar.text = ""
            self.performSegueWithIdentifier("fromSearch", sender: partialArtist)
        }
        
    }
    // MARK: Mini Player Setup & Controls
    
    func setupMiniPlayer(){
        guard PlayerController.sharedController.player != nil &&
            PlayerController.sharedController.player?.playbackState != nil else {
                miniPlayerView.hidden = true
                return
        }
        miniPlayerView.hidden = false
        updateUIforMiniPlayer()
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToUpSwipeGesture))
        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        miniPlayerView.addGestureRecognizer(swipeUp)
        
        let tapOn = UITapGestureRecognizer(target: self, action: #selector(respondToTapGesture))
        miniPlayerView.addGestureRecognizer(tapOn)
    }
    

    
    func respondToUpSwipeGesture(gesture: UIGestureRecognizer) {
        self.performSegueWithIdentifier("fromMiniPlayer", sender: self)
    }
    
    func respondToTapGesture(gestur: UIGestureRecognizer) {
        self.performSegueWithIdentifier("fromMiniPlayer", sender: self)
    }
    
    func updateUIforMiniPlayer(){
        guard let player = PlayerController.sharedController.player else {return}
        guard let currentSong = player.metadata?.currentTrack else {return}
        
        titleLabel.text = currentSong.name
        artistLabel.text = currentSong.artistName
        guard let session = PlayerController.session else {return}
        SPTTrack.trackWithURI(NSURL(string: (currentSong.uri)), session: session) { (error, trackdata) in
            let track = trackdata as! SPTTrack
            let imageURL = track.album.largestCover.imageURL
            QueueController.sharedController.getImageFromURL(imageURL, completion: { (image) in
                self.albumArtImageView.image = image
            })
        }
    }
    
    @IBAction func playPauseButtonTapped(sender: AnyObject) {
        guard let player = PlayerController.sharedController.player else {return}
        guard player.playbackState != nil else {return}
        player.setIsPlaying(!player.playbackState.isPlaying) { (error) in
            if error != nil {
                print("There was an error with the Play Pause Mini Player Button")
                self.setPlayPauseButton()
            }
        }
    }
    
        func setPlayPauseButton(){
        guard let player = PlayerController.sharedController.player else {return}
        guard player.playbackState != nil else {
            self.playPauseButtonOutlet.setImage(UIImage(named: "pause"), forState: .Normal)
            return
        }
        if player.playbackState.isPlaying == true {
            self.playPauseButtonOutlet.setImage(UIImage(named: "pause"), forState: .Normal)
        } else {
            self.playPauseButtonOutlet.setImage(UIImage(named: "play"), forState: .Normal)
        }
    }
    
    // MARK: Audio Streaming Delegates
    
    
    func audioStreamingDidLogin(audioStreaming: SPTAudioStreamingController!) {
        updateUIforMiniPlayer()
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeMetadata metadata: SPTPlaybackMetadata!) {
        updateUIforMiniPlayer()
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        setPlayPauseButton()
    }
    
    // MARK: - Table View Functions
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Top Artists"
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchController.topArtists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("artistCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = SearchController.topArtists[indexPath.row].name
        
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "fromTopArtistCell" {
            guard let indexPath = tableView.indexPathForSelectedRow else {return}
            let artist = SearchController.topArtists[indexPath.row]
            QueueController.sharedController.setQueueFromArtist(artist.uri.absoluteString, completion: nil)
        }
        
        if segue.identifier == "fromSearch" {
            let artist = sender as! SPTPartialArtist
            QueueController.sharedController.setQueueFromArtist(artist.uri.absoluteString, completion: nil)
        }
    }
}
