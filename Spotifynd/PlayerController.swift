
//
//  PlayerController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 9/6/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation
import MediaPlayer


class PlayerController {
    
    
    // MARK: Auth Controller Properties
    static var session: SPTSession?
//    let playerVC = PlayerViewController()
    static var authToken: String?
    static var sessionArchiveKey = "SessionArchiveKey"
    
    
    // MARK: Shared Controller
    static let sharedController = PlayerController()
    
    // MARK: Player Properties
    var player: SPTAudioStreamingController?
    var indexPathRowofCurrentSong:Int? {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("indexPathChanged", object: nil)
        }
    }
    var currentSongAlbumArtwork: UIImage?
    
    
    
    // MARK: Initialize Player
    
    func initializePlayer() {
        player = SPTAudioStreamingController.sharedInstance()
        try! player?.startWithClientId("bbd379abea604abca005f4eca064d395")
        player?.loginWithAccessToken(PlayerController.authToken)
        self.initializeMPRemoteCommandCenterForQueue()
    }
    
    func setupPlayerFromQueue(completion: () -> Void) {
        QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
            print("The operation has completed")
            self.initializePlaylistForPlayback({
                print("playing?: \(self.player?.playbackState.isPlaying)")
                completion()
            })
        }
        
        
    }
    
    func initializePlaylistForPlayback(completion: (() -> Void)?){
        SPTPlaylistSnapshot.playlistWithURI(QueueController.sharedController.spotifyndPlaylist?.uri, session: PlayerController.session) { (error, playlistData) in
            let playlist = playlistData as! SPTPlaylistSnapshot
            let firstpage = playlist.firstTrackPage
            guard let firstSong = firstpage?.items?.first as? SPTPartialTrack else {return}
            if firstSong.name == QueueController.sharedController.queue.first?.name  {
                self.player!.playSpotifyURI(playlist.uri.absoluteString, startingWithIndex: 0, startingWithPosition: 0) { (error) in
                    if error != nil {
                        print("There was an error preparing the playlist")
                        sleep(1)
                        self.initializePlaylistForPlayback(nil)
                    }
                    self.player?.setIsPlaying(false, callback: { (error) in
                        if error != nil {
                            print("There was an error setting the player to pause.")
                        }
                        completion?()
                        NSNotificationCenter.defaultCenter().postNotificationName("setupAppearance", object: nil)
                    })
                }
            }else {
                sleep(1)
                print("The tracks didn't match")
                self.initializePlaylistForPlayback(nil)
                return
            }
        }
    }
    
    func initializeFirstTrackForPlaying(completionFirstTrack: ((SPTTrack) -> Void)?){
        guard player != nil && QueueController.sharedController.queue.count > 0 else {
            sleep(1)
            initializeFirstTrackForPlaying(nil)
            return
        }
        SPTTrack.trackWithURI(QueueController.sharedController.queue[0].uri, session: PlayerController.session) { (error, trackData) in
            let track = trackData as! SPTTrack
            completionFirstTrack?(track)
        }
    }
    
    func playPauseFuction(){
        self.player?.setIsPlaying(!(self.player?.playbackState.isPlaying)!, callback: { (error) in
            if error != nil {
                print("Could not change the playing/pausing state")
            }
        })
        print(player?.metadata?.currentTrack?.name)
    }
    
    func isSongInSavedTracks(completion: ((success: Bool) -> Void)?){
        guard let songURI = NSURL(string: (player?.metadata.currentTrack?.uri)!) else {
            return
        }
        let request = (try? SPTYourMusic.createRequestForCheckingIfSavedTracksContains([songURI], forUserWithAccessToken: PlayerController.authToken))
        SPTRequest.sharedHandler().performRequest(request) { (error, response, data) in
            if data != nil {
                guard let list = (try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)) as? [Bool] else {return}
                if list.first == false {
                    completion?(success: true)
                }
            }
        }
    }
    
    func addSongToSavedTracks(){
        guard let songURI = NSURL(string: (player?.metadata.currentTrack?.uri)!) else {return}
        let request = (try? SPTYourMusic.createRequestForSavingTracks([songURI], forUserWithAccessToken: PlayerController.authToken))
        SPTRequest.sharedHandler().performRequest(request) { (error, response, data) in
            if error != nil {
                print(error)
                print(error.localizedDescription)
                print("There was a problem adding the song to the saved tracks")
            }
            if response != nil {
                print(response)
            }
        }
    }
    
    // MARK: - Remote Command Center
    func initializeMPRemoteCommandCenterForQueue() {
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        let rcc = MPRemoteCommandCenter.sharedCommandCenter()
        
        rcc.playCommand.enabled = true
        rcc.playCommand.addTargetWithHandler { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.setIsPlaying(true, callback: { (error) in
                // completion
            })
            return .Success
        }
        
        rcc.pauseCommand.enabled = true
        rcc.pauseCommand.addTargetWithHandler { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.setIsPlaying(false, callback: { (error) in
                // completion
            })
            return .Success
        }
        
        rcc.nextTrackCommand.enabled = true
        rcc.nextTrackCommand.addTargetWithHandler { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.skipNext({ (error) in
                // completion
            })
            return .Success
        }
        
        rcc.previousTrackCommand.enabled = true
        rcc.previousTrackCommand.addTargetWithHandler { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.skipPrevious({ (error) in
                // completion
            })
            return .Success
        }
        
    }
    
    func setMPNowPlayingInfoCenterForTrack(track: SPTTrack?) {
        guard let track = track else { return }
        
        var trackInfo = [String: AnyObject]()
        if let artwork = self.currentSongAlbumArtwork {
            let mediaArtworkImage = MPMediaItemArtwork(image: artwork)
            trackInfo = [MPMediaItemPropertyTitle:track.name,
                         MPMediaItemPropertyArtist:(track.artists.first?.name)!,
                         MPMediaItemPropertyArtwork: mediaArtworkImage]
//               MPMediaItemPropertyGenre:(track)
        }
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo
    }
    
    
    
    // MARK: Archiving/Unarchiving Data
    
    func saveSessionToUserDefaults(session: SPTSession) {
        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
        NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: PlayerController.sessionArchiveKey)
    }
    
    
    
}
