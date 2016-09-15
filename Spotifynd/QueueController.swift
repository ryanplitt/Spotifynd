//
//  QueueController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/31/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation


class QueueController {
    
    // MARK: Queue Properties
    var spotifyndPlaylist: SPTPlaylistSnapshot?
    
    static let nsUserDefaultsURIKey = "uriKey"
    static let sharedController = QueueController()
    
    var queue: [SPTTrack] = [] {
        didSet{
            NSNotificationCenter.defaultCenter().postNotificationName("queueUpdated", object: nil)
        }
    }
    
    var timeStampOfPlaylistMade: NSDate?
    
    // MARK: Home Screen Functions
    
    
    // MARK: Queue Management
    
    func removeTracksArtistFromQueue(artistName: String, completion: () -> Void) {
        var tracksToRemove: [SPTPartialTrack] = []
        let removeTrackGroup = dispatch_group_create()
        for song in queue {
            if song.artists.first?.name  == artistName {
                tracksToRemove.append(song)
                let index = queue.indexOf(song)
                guard index != nil else { return }
                queue.removeAtIndex(index!)
            }
        }
        dispatch_group_notify(removeTrackGroup, dispatch_get_main_queue()) { 
            self.spotifyndPlaylist?.removeTracksFromPlaylist(tracksToRemove, withAccessToken: PlayerController.authToken, callback: { (error) in
                if error != nil {
                    print("There was an error removing the tracks from the playlist")
                }
                completion()
            })
        }
    }
    
    func setQueueFromArtist(artistURI: String, completion: (() -> Void)?){
        self.getSPTArtistFromURI(artistURI) { (artist) in // Step 1
            self.getRelatedArtists(artist, completion: { (artistsArray) in // Step 2
                self.getTopTracksForArtists(artistsArray, completion: { (arrayOfTracks) in // Step 3
                    self.randomizeArrayOfTracks(arrayOfTracks, completion: { (randomizedArray) in // Step 4
//                        self.checkIfQueueIsInPlaylist({ (success) in // Step 5
                                self.queue = randomizedArray
                                completion?()
                    })
                })
            })
        }
    }
    
    // Step 1: Get Artist
    func getSPTArtistFromURI(artistURI: String, completion: (SPTArtist) -> Void){
        SPTArtist.artistWithURI(NSURL(string: artistURI), session: PlayerController.session) { (error, artistInfo) in
            if error != nil {
                print(error)
                print(error.localizedDescription)
                print("There was an error obtaining the artist from the URI")
            }
            let artist = artistInfo as! SPTArtist
            completion (artist)
        }
    }
    
    //Step 2: Get Related Artists From Artist
    func getRelatedArtists(artist: SPTArtist, completion: ([SPTArtist]) -> Void) {
        artist.requestRelatedArtistsWithAccessToken(PlayerController.authToken) { (error, artistsList) in
            if error != nil {
                print(error.localizedDescription)
                completion([])
                return
            }
            let artists = artistsList as! [SPTArtist]
            completion(artists)
        }
    }
    
    //Step 3: Get Artist Top Tracks For Artist
    func getTopTracksForArtists(artists: [SPTArtist], completion: (arrayOfTracks: [SPTTrack]) -> Void){
        var tracks: [SPTTrack] = []
        let topArtistGroup = dispatch_group_create()
        var counter: Int = 0
        for artist in artists {
            dispatch_group_enter(topArtistGroup)
            self.getArtistTopTracks(artist, completion: { (tracksArray) in
                tracks = tracks + tracksArray
                counter += 1
                dispatch_group_leave(topArtistGroup)
            })
        }
        dispatch_group_notify(topArtistGroup, dispatch_get_main_queue()) { 
            if counter == artists.count {
                completion(arrayOfTracks: tracks)
            }
        }
    }
    
    //Helper Method for Step 3
    func getArtistTopTracks(artist: SPTArtist, numberOfTracks: Int = 3, completion: (tracksArray: [SPTTrack]) -> Void){
        let artistTopTrackGroup = dispatch_group_create()
        artist.requestTopTracksForTerritory("US", withAccessToken: PlayerController.authToken) { (error, trackslist) in
            dispatch_group_enter(artistTopTrackGroup)
            if error != nil {
                print(error.localizedDescription)
                completion(tracksArray: [])
                return
            }
            var tracks = trackslist as! [SPTTrack]
            tracks = Array(tracks.prefix(numberOfTracks))
            dispatch_group_leave(artistTopTrackGroup)
            dispatch_group_notify(artistTopTrackGroup, dispatch_get_main_queue(), { 
                completion(tracksArray: tracks)
            })
            
        }
    }
    
    //Step 4: Randomize the array of tracks
    func randomizeArrayOfTracks(arrayOfTracks: [SPTTrack], completion: (randomizedArray:[SPTTrack]) -> Void) {
        var randomizedArray: [SPTTrack] = []
        let trackRandomizingGroup = dispatch_group_create()
        for track in arrayOfTracks {
            dispatch_group_enter(trackRandomizingGroup)
            randomizedArray.insert(track, atIndex: Int(arc4random_uniform(UInt32(randomizedArray.count))))
            dispatch_group_leave(trackRandomizingGroup)
        }
        dispatch_group_notify(trackRandomizingGroup, dispatch_get_main_queue()) { 
            completion(randomizedArray: randomizedArray)
        }
    }
    
    //Step 5: Check if queue matches the Newmu playlist
    func checkIfQueueIsInPlaylist(completion: (success: Bool) -> Void){
        SPTPlaylistSnapshot.playlistWithURI(QueueController.sharedController.spotifyndPlaylist?.uri, session: PlayerController.session) { (error, playlistData) in
            let playlist = playlistData as! SPTPlaylistSnapshot
            let firstpage = playlist.firstTrackPage
            guard let firstSong = firstpage?.items?.first as? SPTPartialTrack else {return}
            if firstSong.name == QueueController.sharedController.queue.first?.name {
                completion(success: true)
            } else {
                completion(success: false)
            }
        }
    }
    
    
    func createSpotifyPlaylistFromQueueArray() {
        SPTPlaylistList.createPlaylistWithName("\(NSUUID())", publicFlag: false, session: PlayerController.session) { (error, playlistSnapshot) in
            if error != nil {
                print("There was an error making the playlist")
            }
            playlistSnapshot.addTracksToPlaylist(self.queue, withAccessToken: PlayerController.authToken, callback: { (error) in
                if error != nil {
                    print("There was an error adding the tracks to the new playlist")
                }
            })
            print(playlistSnapshot.uri)
            self.spotifyndPlaylist = playlistSnapshot
            NSUserDefaults.standardUserDefaults().setObject(playlistSnapshot.uri.absoluteString, forKey: QueueController.nsUserDefaultsURIKey)
        }
    }
    
    func updateExistingSpotifyPlaylistFromQueueArray(completion: (() -> Void)?) {
        guard spotifyndPlaylist != nil else {
            sleep(1)
            updateExistingSpotifyPlaylistFromQueueArray(nil)
            return
        }
                self.spotifyndPlaylist?.replaceTracksInPlaylist(self.queue, withAccessToken: PlayerController.authToken, callback: { (error) in
                    if error != nil {
                        print("There was an error replacing the playlist..")
                    } else {
                        print("Request Sent")
                    }
                    completion?()
                })
//        let tracks = self.queue.flatMap({$0.uri.absoluteString})
//        let jsonDictionary = ["uris":tracks]
//        SPTUser.requestCurrentUserWithAccessToken(PlayerController.authToken) { (error, userData) in
//            let user = userData as! SPTUser
//            print(user)
//            
//            let request = (try? SPTRequest.createRequestForURL(NSURL(string: "https://api.spotify.com/v1/users/\(user.canonicalUserName)/playlists/2A7O6eT1jAjO0DQ7KoXuf8/tracks"), withAccessToken: PlayerController.authToken, httpMethod: "PUT", values: jsonDictionary, valueBodyIsJSON: true, sendDataAsQueryString: false))
//            SPTRequest.sharedHandler().performRequest(request) { (error, response, data) in
//                completion?()
//            }
//        }
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
        SPTPlaylistSnapshot.playlistWithURI(uri, session: PlayerController.session) { (error, playlistSnapshotData) in
            let playlistSnapshot = playlistSnapshotData as! SPTPlaylistSnapshot
            self.spotifyndPlaylist = playlistSnapshot
            completion()
        }
    }
    
    func addMoreSongsBasedOnThisArtist() {
        //                guard let currentTrack = PlayerController.sharedController.player?.metadata?.currentTrack else {return}
        //                let arrayOfURI = queue.flatMap({$0.uri.absoluteURL})
        //                guard let index = arrayOfURI.indexOf(NSURL(string:currentTrack.uri)!) else {return}
        //                self.setQueueFromArtist(currentTrack.artistUri, startingIndex: index) {
        //                    //completion
        //                }
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
    
    // TODO: - 
    func checkIfQueueMatchesSavedTracks(){
        for song in queue {
            let request = (try? SPTYourMusic.createRequestForCheckingIfSavedTracksContains([song], forUserWithAccessToken: PlayerController.authToken))
            SPTRequest.sharedHandler().performRequest(request) { (error, response, data) in
                if data != nil {
                    guard let list = (try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)) as? [Bool] else {return}
                    if list.first == true {
                        self.removeTrackFromQueue(song)
                    }
                }
            }
        }
    }
    
    func checkIfQueueMatchesSavedArtists(){
        for song in queue {
            let request = (try? SPTYourMusic.createRequestForCheckingIfSavedTracksContains([song], forUserWithAccessToken: PlayerController.authToken))
            SPTRequest.sharedHandler().performRequest(request) { (error, response, data) in
                if data != nil {
                    guard let list = (try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)) as? [Bool] else {return}
                    if list.first == true {
                        let artistsSong = song
                        for song in self.queue {
                            if song.artists.first?.identifier == artistsSong.artists.first?.identifier {
                                self.removeTrackFromQueue(song)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Helper Functions
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
    
}
