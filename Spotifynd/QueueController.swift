//
//  QueueController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/31/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation


class QueueController {
    
    
    var spotifyndPlaylist: SPTPlaylistSnapshot
    
    let nsUserDefaultsURIKey = "uriKey"
    static let sharedController = QueueController()
    var allPlaylistsArray: [SPTPartialPlaylist] = []
    
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
    
    func setQueueFromArtist(artistURI: String){
        let queuingSongs = dispatch_group_create()
        dispatch_group_enter(queuingSongs)
        SPTArtist.artistWithURI(NSURL(string: artistURI), session: AuthController.session, callback: { (error, artistInfo) in
            let artist = artistInfo as! SPTArtist
            QueueController.sharedController.getRelatedArtists(artist, completion: { (artistsArray) in
                for individualArtist in artistsArray {
                    QueueController.sharedController.getArtistsTopTracks(individualArtist, completion: { (trackArray) in
                        for track in trackArray {
                            QueueController.sharedController.queue.insert(track, atIndex: Int(arc4random_uniform(UInt32(self.queue.count))))
                        }
                    })
                }
                dispatch_group_leave(queuingSongs)
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
            NSUserDefaults.standardUserDefaults().setObject(playlistSnapshot.uri, forKey: self.nsUserDefaultsURIKey)
        }
    }
    
    
    func checkIfSpotifyndPlaylistExists(completion: ((uri: NSURL?) -> Void)?) {
        guard let uri = NSUserDefaults.standardUserDefaults().objectForKey(self.nsUserDefaultsURIKey) as? NSURL else {
            print("There was no URI")
            completion?(uri: nil)
            return
        }
        guard SPTPlaylistSnapshot.isPlaylistURI(uri) else {
            print("The URI was not a matching playlist")
            completion?(uri: nil)
            return
        }
        completion?(uri: uri)
    }
    
    func setupSpotifyndPlaylist(uri: NSURL) {
        SPTPlaylistSnapshot.playlistWithURI(uri, session: AuthController.session) { (error, playlistSnapshotData) in
            let playlistSnapshot = playlistSnapshotData as! SPTPlaylistSnapshot
            self.spotifyndPlaylist = playlistSnapshot
        }
    }
    
}