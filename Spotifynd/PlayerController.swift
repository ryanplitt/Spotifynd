
//
//  PlayerController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 9/6/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation


class PlayerController {
    
    
    // MARK: Auth Controller Properties
    static var session: SPTSession?
    static var authToken: String?
    
    
    // MARK: Shared Controller
    static let sharedController = PlayerController()
    
    // MARK: Player Properties
    var player: SPTAudioStreamingController?
    var indexPathRowofCurrentSong:Int? {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("indexPathChanged", object: nil)
        }
    }
    
    // MARK: Initialize Player
    
    
    func initializePlayer() {
        player = SPTAudioStreamingController.sharedInstance()
        try! player?.startWithClientId("bbd379abea604abca005f4eca064d395")
        player?.loginWithAccessToken(PlayerController.authToken)
    }
    
    func setupPlayer() {
        
        QueueController.sharedController.updateExistingSpotifyPlaylistFromQueueArray {
            print("The operation has completed")
            self.initializePlaylistForPlayback({
                print(self.player?.playbackState)
            })
        }
        
        
    }
    
    func initializePlaylistForPlayback(completion: (() -> Void)?){
        let qualityOfService = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfService, 0)
        dispatch_async(backgroundQueue) {
            SPTPlaylistSnapshot.playlistWithURI(QueueController.sharedController.spotifyndPlaylist?.uri, session: PlayerController.session) { (error, playlistData) in
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
    
    func initializeFirstTrackForPlaying(completionFirstTrack: (SPTTrack) -> Void){
        SPTTrack.trackWithURI(QueueController.sharedController.queue[0].uri, session: PlayerController.session) { (error, trackData) in
            let track = trackData as! SPTTrack
            completionFirstTrack(track)
        }
    }
    
    func playPauseFuction(){
        self.player?.setIsPlaying(!(self.player?.playbackState.isPlaying)!, callback: { (error) in
            if error != nil {
                print("Could not change the playing/pausing state")
            }
        })
    }

    
}