//
//  HomeScreenViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/28/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class HomeScreenViewController: UIViewController, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, SearchResultsControllerDelegate {

    
    @IBOutlet weak var albumArtImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playPauseButtonOutlet: UIButton!
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    
    
    @IBOutlet weak var tableView: UITableView!
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: NSNotification.Name(rawValue: "topArtistLoaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setPlayPauseButton), name: NSNotification.Name(rawValue: "isPlayingValueChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIforMiniPlayer), name: NSNotification.Name(rawValue: "updateUI"), object: nil)
        setupNavBar()
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
    
    func setupNavBar(){
        let image = UIImage(named: "NewMuNoLogo2")
        let imageView = UIImageView(image: image)
        self.navigationItem.titleView = imageView
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SearchController.sharedController.getUsersTopArtistsForHomeScreen()
        setupMiniPlayer()
        setPlayPauseButton()
    }
    
    func setupSearchController(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultsController = storyboard.instantiateViewController(withIdentifier: "resultsVC") as! SearchResultsTableViewController
        
        searchController = UISearchController(searchResultsController: resultsController)
        
        guard let searchController = searchController else {return}
        
        resultsController.delegate = self
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.placeholder = "Search for an Artist"
        searchController.definesPresentationContext = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
            let resultsController = searchController.searchResultsController as? SearchResultsTableViewController else {return}
        
        DispatchQueue.main.async {
            SearchController.searchForArtist(text, completion: { 
                resultsController.tableView.reloadData()
            })
        }
    }
    
    func didSelectedCell(_ partialArtist: SPTPartialArtist) {
        self.dismiss(animated: true) {
            self.searchController?.searchBar.text = ""
            self.performSegue(withIdentifier: "fromSearch", sender: partialArtist)
        }
        
    }
    // MARK: Mini Player Setup & Controls
    
    func setupMiniPlayer(){
        guard PlayerController.sharedController.player != nil &&
            PlayerController.sharedController.player?.playbackState != nil else {
                miniPlayerView.isHidden = true
                return
        }
        miniPlayerView.isHidden = false
        updateUIforMiniPlayer()
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToUpSwipeGesture))
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        miniPlayerView.addGestureRecognizer(swipeUp)
        
        let tapOn = UITapGestureRecognizer(target: self, action: #selector(respondToTapGesture))
        miniPlayerView.addGestureRecognizer(tapOn)
    }
    

    
    func respondToUpSwipeGesture(_ gesture: UIGestureRecognizer) {
        self.performSegue(withIdentifier: "fromMiniPlayer", sender: self)
    }
    
    func respondToTapGesture(_ gestur: UIGestureRecognizer) {
        self.performSegue(withIdentifier: "fromMiniPlayer", sender: self)
    }
    
    func updateUIforMiniPlayer(){
        guard let player = PlayerController.sharedController.player else {return}
        guard let currentSong = player.metadata?.currentTrack else {return}
        
        titleLabel.text = currentSong.name
        artistLabel.text = currentSong.artistName
        guard let session = PlayerController.session else {return}
        SPTTrack.track(withURI: URL(string: (currentSong.uri)), session: session) { (error, trackdata) in
            let track = trackdata as! SPTTrack
            guard let imageURL = track.album?.largestCover?.imageURL else {return}
            QueueController.sharedController.getImageFromURL(imageURL, completion: { (image) in
                self.albumArtImageView.image = image
            })
        }
    }
    
    @IBAction func playPauseButtonTapped(_ sender: AnyObject) {
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
            self.playPauseButtonOutlet.setImage(UIImage(named: "pause"), for: UIControlState())
            return
        }
        if player.playbackState.isPlaying == true {
            self.playPauseButtonOutlet.setImage(UIImage(named: "pause"), for: UIControlState())
        } else {
            self.playPauseButtonOutlet.setImage(UIImage(named: "play"), for: UIControlState())
        }
    }
    
    // MARK: - Table View Functions
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Top Artists"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchController.topArtists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell", for: indexPath)
        
        cell.textLabel?.text = SearchController.topArtists[indexPath.row].name
        
        return cell
    }
    
    func checkTimeForSegue(_ segueIdentifier: String, sender: AnyObject?, completion: ((_ success: Bool) -> Void)?){
            if QueueController.sharedController.timeStampOfPlaylistMade == nil {
                QueueController.sharedController.timeStampOfPlaylistMade = Date()
                completion?(true)
            }else {
                let timeDifference = QueueController.sharedController.timeStampOfPlaylistMade?.timeIntervalSinceNow
            guard timeDifference < -60 else {
                let alertController = UIAlertController(title: "We're Sorry", message: "Due to Spotify restrictions you can only change your playlist every 60 seconds. Please wait \(Int(60 + timeDifference!)) seconds longer.", preferredStyle: .alert)
                let okay = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
                let tryAgain = UIAlertAction(title: "Try Again", style: .default, handler: { (_) in
                    self.performSegue(withIdentifier: segueIdentifier, sender: sender)
                })
                
                alertController.addAction(okay)
                alertController.addAction(tryAgain)
                
                print(timeDifference)
                present(alertController, animated: true, completion: nil)
                completion?(false)
                return
            }
            QueueController.sharedController.timeStampOfPlaylistMade = Date()
                completion?(true)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromTopArtistCell" {
            checkTimeForSegue(segue.identifier!, sender: sender as AnyObject?, completion: { (success) in
                if success {
                    guard let indexPath = self.tableView.indexPathForSelectedRow else {return}
                    let artist = SearchController.topArtists[indexPath.row]
                    PlayerController.sharedController.player?.setIsPlaying(false, callback: { (error) in
                        DispatchQueue.main.async(execute: {
                            QueueController.sharedController.setQueueFromArtist(artist.uri.absoluteString, completion: {
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "setupPlayer"), object: nil)
                            })
                        })
                    })
                }
                
            })
        }
        if segue.identifier == "fromSearch" {
            checkTimeForSegue(segue.identifier!,sender: sender as AnyObject?, completion: { (success) in
                if success {
                    let artist = sender as! SPTPartialArtist
                    QueueController.sharedController.setQueueFromArtist(artist.uri.absoluteString, completion: { 
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "setupPlayer"), object: nil)
                    })
                }
            })
        }
    }
}
