//
//  QueueController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/31/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation


class QueueController {
    
    var spotifyndPlaylist: SPTPlaylistSnapshot?
    
    static let nsUserDefaultsURIKey = "uriKey"
    static let sharedController = QueueController()
    
    var queue: [SPTTrack] = [] {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("queueUpdated", object: nil)
        }
    }
    
    func getRelatedArtists(artist: SPTArtist, completion: ([SPTArtist]) -> Void) {
        artist.requestRelatedArtistsWithAccessToken(AuthController.authToken) { (error, artistsList) in
            if error != nil {
                print(error.localizedDescription)
                completion([])
                return
            }
            let artists = artistsList as! [SPTArtist]
            completion(artists)
        }
    }
    
    func getArtistsTopTracks(artist: SPTArtist, numberOfTracks: Int = 5, completion: ([SPTTrack]) -> Void){
        artist.requestTopTracksForTerritory("US", withAccessToken: AuthController.authToken) { (error, trackslist) in
            if error != nil {
                print(error.localizedDescription)
                completion([])
                return
            }
            var tracks = trackslist as! [SPTTrack]
            tracks = Array(tracks.prefix(numberOfTracks))
            completion(tracks)
        }
    }
    
    func queueSongToArray(track: SPTTrack) {
        queue.append(track)
    }
    
    func removeTrackFromQueue(track: SPTTrack) {
        let index = queue.indexOf(track)
        guard index != nil else {
            print("Could not find track in queue.")
            return
        }
        queue.removeAtIndex(index!)
    }
    
    func removeTracksArtistFromQueue(track: SPTTrack) {
        let artistOfTrack = track.artists.first as! SPTPartialArtist
        for song in queue {
            if song.artists.first as! SPTPartialArtist == artistOfTrack {
                let index = queue.indexOf(song)
                guard index != nil else { return }
                queue.removeAtIndex(index!)
            }
        }
    }
    
    func setQueueFromArtist(artistURI: String, completion: (() -> Void)?){
        //        let queuingSongs = dispatch_group_create()
        var tempQueue: [SPTTrack] = []
        var tempCount: Int = 0
        
        SPTArtist.artistWithURI(NSURL(string: artistURI), session: AuthController.session, callback: { (error, artistInfo) in
            let artist = artistInfo as! SPTArtist
            QueueController.sharedController.getRelatedArtists(artist, completion: { (artistsArray) in
                for individualArtist in artistsArray {
                    QueueController.sharedController.getArtistsTopTracks(individualArtist, completion: { (trackArray) in
                        let songGroup = dispatch_group_create()
                        
                        for track in trackArray {
                            dispatch_group_enter(songGroup)
                            tempQueue.insert(track, atIndex: Int(arc4random_uniform(UInt32(tempQueue.count))))
                            dispatch_group_leave(songGroup)
                        }
                        tempCount += 1
                        dispatch_group_notify(songGroup, dispatch_get_main_queue(), {
                            if tempCount == artistsArray.count {
                            self.queue = tempQueue
                            completion?()
                            }
                        })
                    })
                }
            })
        })
    }
    
    
    func createSpotifyPlaylistFromQueueArray() {
        SPTPlaylistList.createPlaylistWithName("Spotifynd", publicFlag: false, session: AuthController.session) { (error, playlistSnapshot) in
            if error != nil {
                print("There was an error making the playlist")
            }
            playlistSnapshot.addTracksToPlaylist(self.queue, withAccessToken: AuthController.authToken, callback: { (error) in
                if error != nil {
                    print("There was an error adding the tracks to the new playlist")
                }
            })
            print(playlistSnapshot.uri)
            NSUserDefaults.standardUserDefaults().setObject(playlistSnapshot.uri.absoluteString, forKey: QueueController.nsUserDefaultsURIKey)
        }
    }
    
    func updateExistingSpotifyPlaylistFromQueueArray(completion: (() -> Void)?) {
        guard spotifyndPlaylist != nil else {
            sleep(1)
            updateExistingSpotifyPlaylistFromQueueArray(nil)
            return
        }
        spotifyndPlaylist?.replaceTracksInPlaylist(queue, withAccessToken: AuthController.authToken, callback: { (error) in
            if error != nil {
                print("There was an error replacing the playlist..")
            }
            completion?()
        })
    }
    
    
    func checkIfSpotifyndPlaylistExists(completion: ((success: Bool) -> Void)?) {
        guard let uriString = NSUserDefaults.standardUserDefaults().objectForKey(QueueController.nsUserDefaultsURIKey) as? String,
            let uri = NSURL(string: uriString) else {
                print("There was no URI")
                completion?(success: false)
                return
        }
        guard SPTPlaylistSnapshot.isPlaylistURI(uri) else {
            print("The URI was not a matching playlist")
            completion?(success: false)
            return
        }
        setupSpotifyndPlaylist(uri) { 
            completion?(success: true)
        }
    }
    
    func setupSpotifyndPlaylist(uri: NSURL, completion: () -> Void) {
        SPTPlaylistSnapshot.playlistWithURI(uri, session: AuthController.session) { (error, playlistSnapshotData) in
            let playlistSnapshot = playlistSnapshotData as! SPTPlaylistSnapshot
            self.spotifyndPlaylist = playlistSnapshot
            completion()
        }
    }
    
    func getImageFromURL(imageURL: NSURL, completion: ((image: UIImage) -> Void)?){
        let data = NSData(contentsOfURL: imageURL)
        guard data != nil else {
            print("There doesn't appear to be any image")
            return
        }
        guard let image = UIImage(data: data!) else {
            print("Could not transfer data into image")
            return
        }
        completion?(image: image)
    }
    
    func initializeFirstTrackForPlaying(player: SPTAudioStreamingController, completionFirstTrack: (SPTTrack) -> Void){
        SPTTrack.trackWithURI(queue[0].uri, session: AuthController.session) { (error, trackData) in
            let track = trackData as! SPTTrack
            completionFirstTrack(track)
        }
    }
}