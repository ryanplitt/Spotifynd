
//
//  PlayerController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 9/6/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation
import MediaPlayer


class PlayerController: NSObject, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    
    // MARK: Auth Controller Properties
    static var session: SPTSession?
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
        player?.delegate = self
        player?.playbackDelegate = self
    }
    
    func setupPlayerFromQueue(completion: () -> Void) {
        QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
            self.initializePlaylistForPlayback({
                completion()
            })
        }
    }
    
    func initializePlaylistForPlayback(completion: (() -> Void)?){
        SPTPlaylistSnapshot.playlistWithURI(QueueController.sharedController.spotifyndPlaylist?.uri, session: PlayerController.session) { (error, playlistData) in
            let playlist = playlistData as! SPTPlaylistSnapshot
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
                    let track = self.player?.metadata?.nextTrack
                    let imageURL = track?.albumCoverArtUri.substringFromIndex((track?.albumCoverArtUri.startIndex.advancedBy(14))!)
                    guard let image = imageURL else {return}
                QueueController.sharedController.getImageFromURL(NSURL(string: "https://i.scdn.co/image/\(image)")!, completion: { (image) in
                        dispatch_async(dispatch_get_main_queue(), {
                            PlayerController.sharedController.currentSongAlbumArtwork = image
                            PlayerController.sharedController.setMPNowPlayingInfoCenterForTrack(track)
                        })
                    })
            })
            return .Success
        }
        
        rcc.previousTrackCommand.enabled = true
        rcc.previousTrackCommand.addTargetWithHandler { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.skipNext({ (error) in
                let track = self.player?.metadata?.prevTrack
                let imageURL = track?.albumCoverArtUri.substringFromIndex((track?.albumCoverArtUri.startIndex.advancedBy(14))!)
                print(imageURL)
                guard let image = imageURL else {return}
                QueueController.sharedController.getImageFromURL(NSURL(string: "https://i.scdn.co/image/\(image)")!, completion: { (image) in
                    dispatch_async(dispatch_get_main_queue(), {
                        PlayerController.sharedController.currentSongAlbumArtwork = image
                        PlayerController.sharedController.setMPNowPlayingInfoCenterForTrack(track)
                    })
                })
            })
            return .Success
        }
        
        
    }
    
    func setMPNowPlayingInfoCenterForTrack(track: SPTPlaybackTrack?) {
        guard let track = track else { return }
        
        var trackInfo = [String: AnyObject]()
        if let artwork = self.currentSongAlbumArtwork {
            let mediaArtworkImage = MPMediaItemArtwork(image: artwork)
            trackInfo = [MPMediaItemPropertyTitle:track.name,
                         MPMediaItemPropertyArtist:(track.artistName),
                         MPMediaItemPropertyArtwork: mediaArtworkImage,
                         MPMediaItemPropertyPlaybackDuration: track.duration]
        }
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = trackInfo
    }
    
    func setPositionOfTrackInMediaItemProperty(){
        guard let position = self.positionOfCurrentTrack else {return}
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo?.updateValue(position, forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
    }
    
    // MARK: Player Controller Properties
    var isPlaying: Bool {
        get{
            return player?.playbackState?.isPlaying ?? false
        }
        set{
            NSNotificationCenter.defaultCenter().postNotificationName("isPlayingValueChanged", object: nil)
                setPositionOfTrackInMediaItemProperty()
        }
    }
    
    var positionOfCurrentTrack: NSTimeInterval? {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("updatingPostionOfTrack", object: nil)
        }
    }
    
    // MARK: Player Delegate Functions
    
    
    func audioStreamingDidLogout(audioStreaming: SPTAudioStreamingController!) {
        _ = (try? player?.stop())
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.isPlaying = isPlaying
        NSNotificationCenter.defaultCenter().postNotificationName("updateUI", object: nil)
    }
    
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeMetadata metadata: SPTPlaybackMetadata!) {
        NSNotificationCenter.defaultCenter().postNotificationName("updateUI", object: nil)
        if let currentURI = player?.metadata.currentTrack?.uri {
            let uriArrays = QueueController.sharedController.queue.flatMap({$0.uri.absoluteString})
            self.indexPathRowofCurrentSong = uriArrays.indexOf(currentURI)
        }
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePosition position: NSTimeInterval) {
        self.positionOfCurrentTrack = position
    }
    
    // MARK: Archiving/Unarchiving Data
    
    func saveSessionToUserDefaults(session: SPTSession) {
        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
        NSUserDefaults.standardUserDefaults().setObject(sessionData, forKey: PlayerController.sessionArchiveKey)
    }
    
    
    
}
