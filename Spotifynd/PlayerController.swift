
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
    
    
    // MARK: Shared Controller
    static let sharedController = PlayerController()
    
    
    // MARK: Auth Controller Properties
    static var session: SPTSession?
    static var authToken: String?
    static var sessionArchiveKey = "SessionArchiveKey"
    static var tokenExpirationDate: Date?
    
    

    // MARK: Player Properties
    var player: SPTAudioStreamingController?
    var indexPathRowofCurrentSong: Int? {
        didSet{
            NotificationCenter.default.post(name: Notification.Name(rawValue: "indexPathChanged"), object: nil)
        }
    }
    var currentSongAlbumArtwork: UIImage?
    
    
    
    // MARK: Initialize Player
    
    func initializePlayer() {
        player = SPTAudioStreamingController.sharedInstance()
        try! player?.start(withClientId: "bbd379abea604abca005f4eca064d395")
        player?.login(withAccessToken: PlayerController.authToken)
        self.initializeMPRemoteCommandCenterForQueue()
        player?.delegate = self
        player?.playbackDelegate = self
    }
    
    func setupPlayerFromQueue(_ completion: @escaping () -> Void) {
        QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
            self.initializePlaylistForPlayback({
                completion()
            })
        }
    }
    
    func initializePlaylistForPlayback(_ completion: (() -> Void)?){
        SPTPlaylistSnapshot.playlist(withURI: QueueController.sharedController.spotifyndPlaylist?.uri, session: PlayerController.session) { (error, playlistData) in
            let playlist = playlistData as! SPTPlaylistSnapshot
            self.player!.playSpotifyURI(playlist.uri.absoluteString, startingWith: 0, startingWithPosition: 0) { (error) in
                if error != nil {
                    print("There was an error preparing the playlist")
                    sleep(1)
                    self.initializePlaylistForPlayback(nil)
                    completion?()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "setupAppearance"), object: nil)
                }
            }
        }
    }
    
    func initializeFirstTrackForPlaying(_ completionFirstTrack: ((SPTTrack) -> Void)?){
        guard player != nil && QueueController.sharedController.queue.count > 0 else {
            sleep(1)
            initializeFirstTrackForPlaying(nil)
            return
        }
        SPTTrack.track(withURI: QueueController.sharedController.queue[0].uri, session: PlayerController.session) { (error, trackData) in
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
    
    func isSongInSavedTracks(_ completion: ((_ success: Bool) -> Void)?){
        guard let songURI = URL(string: (player?.metadata.currentTrack?.uri)!) else {
            return
        }
        let request = (try? SPTYourMusic.createRequest(forCheckingIfSavedTracksContains: [songURI], forUserWithAccessToken: PlayerController.authToken))
        SPTRequest.sharedHandler().perform(request) { (error, response, data) in
            if data != nil {
                guard let list = (try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)) as? [Bool] else {return}
                if list.first == false {
                    completion?(true)
                }
            }
        }
    }
    
    func addSongToSavedTracks(){
        guard let songURI = URL(string: (player?.metadata.currentTrack?.uri)!) else {return}
        let request = (try? SPTYourMusic.createRequest(forSavingTracks: [songURI], forUserWithAccessToken: PlayerController.authToken))
        SPTRequest.sharedHandler().perform(request) { (error, response, data) in
            if error != nil {
                print(error)
                print(error?.localizedDescription)
                print("There was a problem adding the song to the saved tracks")
            }
            if response != nil {
                print(response)
            }
        }
    }
    
    // MARK: - Remote Command Center
    func initializeMPRemoteCommandCenterForQueue() {
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let rcc = MPRemoteCommandCenter.shared()
        
        rcc.playCommand.isEnabled = true
        rcc.playCommand.addTarget (handler: { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.setIsPlaying(true, callback: { (error) in
                // completion
            })
            return .success
        })
        
        rcc.pauseCommand.isEnabled = true
        rcc.pauseCommand.addTarget (handler: { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.setIsPlaying(false, callback: { (error) in
                // completion
            })
            return .success
        })
        
        rcc.nextTrackCommand.isEnabled = true
        rcc.nextTrackCommand.addTarget (handler: { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.skipNext({ (error) in
                    let track = self.player?.metadata?.nextTrack
                    let imageURL = track?.albumCoverArtUri.substring(from: (track?.albumCoverArtUri.characters.index((track?.albumCoverArtUri.startIndex)!, offsetBy: 14))!)
                    guard let image = imageURL else {return}
                print(image)
                QueueController.sharedController.getImageFromURL(URL(string: "https://i.scdn.co/image/\(image)")!, completion: { (image) in
                        DispatchQueue.main.async(execute: {
                            PlayerController.sharedController.currentSongAlbumArtwork = image
                            PlayerController.sharedController.setMPNowPlayingInfoCenterForTrack(track)
                        })
                    })
            })
            return .success
        })
        
        rcc.previousTrackCommand.isEnabled = true
        rcc.previousTrackCommand.addTarget (handler: { (event) -> MPRemoteCommandHandlerStatus in
            self.player?.skipPrevious({ (error) in
                let track = self.player?.metadata?.prevTrack
                let imageURL = track?.albumCoverArtUri.substring(from: (track?.albumCoverArtUri.characters.index((track?.albumCoverArtUri.startIndex)!, offsetBy: 14))!)
                print(imageURL)
                guard let image = imageURL else {return}
                QueueController.sharedController.getImageFromURL(URL(string: "https://i.scdn.co/image/\(image)")!, completion: { (image) in
                    DispatchQueue.main.async(execute: {
                        PlayerController.sharedController.currentSongAlbumArtwork = image
                        PlayerController.sharedController.setMPNowPlayingInfoCenterForTrack(track)
                    })
                })
            })
            return .success
        })
        
        
    }
    
    func setMPNowPlayingInfoCenterForTrack(_ track: SPTPlaybackTrack?) {
        guard let track = track else { return }
        
        var trackInfo = [String: AnyObject]()
        if let artwork = self.currentSongAlbumArtwork {
            let mediaArtworkImage = MPMediaItemArtwork(image: artwork)
            trackInfo = [MPMediaItemPropertyTitle:track.name as AnyObject,
                         MPMediaItemPropertyArtist:(track.artistName as AnyObject),
                         MPMediaItemPropertyArtwork: mediaArtworkImage,
                         MPMediaItemPropertyPlaybackDuration: track.duration as AnyObject]
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = trackInfo
    }
    
    func setPositionOfTrackInMediaItemProperty(){
        guard let position = self.positionOfCurrentTrack else {return}
        MPNowPlayingInfoCenter.default().nowPlayingInfo?.updateValue(position, forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime)
    }
    
    // MARK: Player Controller Properties
    var isPlaying: Bool {
        get{
            return player?.playbackState?.isPlaying ?? false
        }
        set{
            NotificationCenter.default.post(name: Notification.Name(rawValue: "isPlayingValueChanged"), object: nil)
                setPositionOfTrackInMediaItemProperty()
        }
    }
    
    var positionOfCurrentTrack: TimeInterval? {
        didSet{
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updatingPostionOfTrack"), object: nil)
        }
    }
    
    // MARK: Player Delegate Functions
    
    
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController!) {
        _ = try? player?.stop()
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.isPlaying = isPlaying
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateUI"), object: nil)
    }
    
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateUI"), object: nil)
        if let currentURI = player?.metadata.currentTrack?.uri {
            let uriArrays = QueueController.sharedController.queue.flatMap({$0.uri.absoluteString})
            self.indexPathRowofCurrentSong = uriArrays.index(of: currentURI)
        }
        setMPNowPlayingInfoCenterForTrack(metadata.currentTrack)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        self.positionOfCurrentTrack = position
    }
    
    // MARK: Archiving/Unarchiving Data
    
    func saveSessionToUserDefaults(_ session: SPTSession) {
        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
        UserDefaults.standard.set(sessionData, forKey: PlayerController.sessionArchiveKey)
    }
}
