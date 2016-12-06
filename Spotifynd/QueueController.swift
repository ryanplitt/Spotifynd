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
            NotificationCenter.default.post(name: Notification.Name(rawValue: "queueUpdated"), object: nil)
        }
    }
    
    var timeStampOfPlaylistMade: Date?
    
    // MARK: Queue Management
    
    func removeTracksArtistFromQueue(_ artistName: String, completion: () -> Void) {
        var tracksToRemove: [SPTPartialTrack] = []
        let removeTrackGroup = DispatchGroup()
        for song in queue {
            if (song.artists.first as AnyObject).name  == artistName {
                tracksToRemove.append(song)
                let index = queue.index(of: song)
                guard index != nil else { return }
                queue.remove(at: index!)
            }
        }
    }
    
    func setQueueFromArtist(_ artistURI: String, completion: (() -> Void)?){
        self.getSPTArtistFromURI(artistURI) { (artist) in // Step 1
            self.getRelatedArtists(artist, completion: { (artistsArray) in // Step 2
                self.getTopTracksForArtists(artistsArray, completion: { (arrayOfTracks) in // Step 3
                    self.randomizeArrayOfTracks(arrayOfTracks, completion: { (randomizedArray) in // Step 4
                        self.checkIfQueueMatchesSavedArtists(randomizedArray, completion: { (newArrayOfTracks) in
                            self.checkIfArrayMatchesSavedTracks(newArrayOfTracks, completion: { (newArray) in
                                self.queue = newArray
                                completion?()
                            })
                        })
                    })
                })
            })
        }
    }
    
    // Step 1: Get Artist
    func getSPTArtistFromURI(_ artistURI: String, completion: @escaping (SPTArtist) -> Void){
        SPTArtist.artist(withURI: URL(string: artistURI), session: PlayerController.session) { (error, artistInfo) in
            if error != nil {
                print(error)
                print(error?.localizedDescription)
                print("There was an error obtaining the artist from the URI")
            }
            let artist = artistInfo as! SPTArtist
            completion (artist)
        }
    }
    
    //Step 2: Get Related Artists From Artist
    func getRelatedArtists(_ artist: SPTArtist, completion: @escaping ([SPTArtist]) -> Void) {
        artist.requestRelatedArtists(withAccessToken: PlayerController.authToken) { (error, artistsList) in
            if error != nil {
                print(error?.localizedDescription)
                completion([])
                return
            }
            let artists = artistsList as! [SPTArtist]
            completion(artists)
        }
    }
    
    //Step 3: Get Artist Top Tracks For Artist
    func getTopTracksForArtists(_ artists: [SPTArtist], completion: @escaping (_ arrayOfTracks: [SPTTrack]) -> Void){
        var tracks: [SPTTrack] = []
        let topArtistGroup = DispatchGroup()
        var counter: Int = 0
        for artist in artists {
            topArtistGroup.enter()
            self.getArtistTopTracks(artist, completion: { (tracksArray) in
                tracks = tracks + tracksArray
                counter += 1
                topArtistGroup.leave()
            })
        }
        topArtistGroup.notify(queue: DispatchQueue.main) { 
            if counter == artists.count {
                completion(tracks)
            }
        }
    }
    
    //Helper Method for Step 3
    func getArtistTopTracks(_ artist: SPTArtist, numberOfTracks: Int = 3, completion: @escaping (_ tracksArray: [SPTTrack]) -> Void){
        let artistTopTrackGroup = DispatchGroup()
        artist.requestTopTracks(forTerritory: "US", withAccessToken: PlayerController.authToken) { (error, trackslist) in
            artistTopTrackGroup.enter()
            if error != nil {
                print(error?.localizedDescription)
                completion([])
                return
            }
            var tracks = trackslist as! [SPTTrack]
            tracks = Array(tracks.prefix(numberOfTracks))
            artistTopTrackGroup.leave()
            artistTopTrackGroup.notify(queue: DispatchQueue.main, execute: { 
                completion(tracks)
            })
            
        }
    }
    
    //Step 4: Randomize the array of tracks
    func randomizeArrayOfTracks(_ arrayOfTracks: [SPTTrack], completion: @escaping (_ randomizedArray:[SPTTrack]) -> Void) {
        var randomizedArray: [SPTTrack] = []
        let trackRandomizingGroup = DispatchGroup()
        for track in arrayOfTracks {
            trackRandomizingGroup.enter()
            randomizedArray.insert(track, at: Int(arc4random_uniform(UInt32(randomizedArray.count))))
            trackRandomizingGroup.leave()
        }
        trackRandomizingGroup.notify(queue: DispatchQueue.main) { 
            completion(randomizedArray)
        }
    }
    
    //Step 5: Check if queue matches the Newmu playlist
    func checkIfQueueIsInPlaylist(_ completion: @escaping (_ success: Bool) -> Void){
        SPTPlaylistSnapshot.playlist(withURI: QueueController.sharedController.spotifyndPlaylist?.uri, session: PlayerController.session) { (error, playlistData) in
            let playlist = playlistData as! SPTPlaylistSnapshot
            let firstpage = playlist.firstTrackPage
            guard let firstSong = firstpage?.items?.first as? SPTPartialTrack else {return}
            if firstSong.name == QueueController.sharedController.queue.first?.name {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    
    func createSpotifyPlaylistFromQueueArray() {
        SPTPlaylistList.createPlaylist(withName: "NewMu", publicFlag: false, session: PlayerController.session) { (error, playlistSnapshot) in
            if error != nil {
                print("There was an error making the playlist")
            }
            playlistSnapshot?.addTracks(toPlaylist: self.queue, withAccessToken: PlayerController.authToken, callback: { (error) in
                if error != nil {
                    print("There was an error adding the tracks to the new playlist")
                }
            })
            print(playlistSnapshot?.uri)
            self.spotifyndPlaylist = playlistSnapshot
            UserDefaults.standard.set(playlistSnapshot?.uri.absoluteString, forKey: QueueController.nsUserDefaultsURIKey)
        }
    }
    
    func updateExistingSpotifyPlaylistFromQueueArray(_ completion: (() -> Void)?) {
        guard spotifyndPlaylist != nil else {
            sleep(1)
            updateExistingSpotifyPlaylistFromQueueArray(nil)
            return
        }
                self.spotifyndPlaylist?.replaceTracks(inPlaylist: self.queue, withAccessToken: PlayerController.authToken, callback: { (error) in
                    if error != nil {
                        print("There was an error replacing the playlist..")
                    } else {
                        print("Request Sent")
                    }
                    completion?()
                })
    }
    
    
    func checkIfSpotifyndPlaylistExists(_ completion: ((_ success: Bool) -> Void)?) {
        guard let uriString = UserDefaults.standard.object(forKey: QueueController.nsUserDefaultsURIKey) as? String,
            let uri = URL(string: uriString) else {
                print("There was no URI")
                completion?(false)
                return
        }
        guard SPTPlaylistSnapshot.isPlaylistURI(uri) else {
            print("The URI was not a matching playlist")
            completion?(false)
            return
        }
        setupSpotifyndPlaylist(uri) { 
            completion?(true)
        }
    }
    
    func setupSpotifyndPlaylist(_ uri: URL, completion: @escaping () -> Void) {
        SPTPlaylistSnapshot.playlist(withURI: uri, session: PlayerController.session) { (error, playlistSnapshotData) in
            let playlistSnapshot = playlistSnapshotData as! SPTPlaylistSnapshot
            self.spotifyndPlaylist = playlistSnapshot
            completion()
        }
    }
    
    func addMoreSongsBasedOnThisArtist() {
        guard let currentTrack = PlayerController.sharedController.player?.metadata?.currentTrack else {return}
//        let arrayOfURI = queue.flatMap({$0.uri.absoluteURL})
//        guard let index = arrayOfURI.indexOf(NSURL(string:currentTrack.uri)!) else {return}
        self.setQueueFromArtist(currentTrack.artistUri) {
            //completion
        }
    }
    
    func addSongsToEndOfSpotifyndPlaylist(_ arrayOfTracks: [SPTTrack]){
        QueueController.sharedController.spotifyndPlaylist?.addTracksWithPosition(toPlaylist: arrayOfTracks, withPosition: Int32(self.queue.count), session: PlayerController.session, callback: { (error) in
            if error != nil {
                print(error)
                print(error?.localizedDescription)
                print("There was a problem adding the new tracks to the playlist")
            }
        })
    }
    
    func queueSongToArray(_ track: SPTTrack) {
        queue.append(track)
    }
    
    func removeTrackFromQueue(_ track: SPTTrack) {
        let index = queue.index(of: track)
        guard index != nil else {
            print("Could not find track in queue.")
            return
        }
        queue.remove(at: index!)
    }
    
    func checkIfArrayMatchesSavedTracks(_ arrayOfTracks: [SPTTrack], completion: @escaping (_ newArrayOfTracks: [SPTTrack]) -> Void){
        if UserDefaults.standard.bool(forKey: SettingsTableViewController.songNSUserDefaultsKey) == true {
            let matchedSavedTracksGroup = DispatchGroup()
            var newArrayOfTracks: [SPTTrack] = []
            for song in arrayOfTracks {
                matchedSavedTracksGroup.enter()
                let request = (try? SPTYourMusic.createRequest(forCheckingIfSavedTracksContains: [song], forUserWithAccessToken: PlayerController.authToken))
                SPTRequest.sharedHandler().perform(request) { (error, response, data) in
                    
                    if data != nil {
                        guard let list = (try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)) as? [Bool] else {return}
                        if list.first == false {
                            newArrayOfTracks.append(song)
                            matchedSavedTracksGroup.leave()
                        } else {
                            matchedSavedTracksGroup.leave()
                        }
                    } else {
                        matchedSavedTracksGroup.leave()
                    }
                }
            }
            matchedSavedTracksGroup.notify(queue: DispatchQueue.main) {
                completion(newArrayOfTracks)
            }
        } else {
            completion(arrayOfTracks)
        }
    }
    
    func checkIfQueueMatchesSavedArtists(_ arrayOfTracks: [SPTTrack], completion: @escaping (_ newArray: [SPTTrack]) -> Void){
        if UserDefaults.standard.bool(forKey: SettingsTableViewController.artistsNSUserDefaultsKey) == true {
            let matchedSavedArtistsGroup = DispatchGroup()
            var newArrayOfTracks: [SPTTrack] = []
            for song in arrayOfTracks {
               matchedSavedArtistsGroup.enter()
                let request = (try? SPTYourMusic.createRequest(forCheckingIfSavedTracksContains: [song], forUserWithAccessToken: PlayerController.authToken))
                SPTRequest.sharedHandler().perform(request) { (error, response, data) in
                    
                    if data != nil {
                        guard let list = (try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)) as? [Bool] else {return}
                        
                        if list.first == true {
                            for newSong in newArrayOfTracks {
                                if (newSong.artists.first as AnyObject).identifier == (song.artists.first as AnyObject).identifier {
                                    if let index = newArrayOfTracks.index(of: newSong){
                                        newArrayOfTracks.remove(at: index)
                                    }
                                }
                            }
                        }
                        matchedSavedArtistsGroup.leave()
                    } else {
                        completion(arrayOfTracks)
                    }
                    
                }
            }
            matchedSavedArtistsGroup.notify(queue: DispatchQueue.main) {
                completion(newArrayOfTracks)
            }
        } else {
            completion(arrayOfTracks)
        }
    }
    
    
    // MARK: Helper Functions
    func getImageFromURL(_ imageURL: URL, completion: ((_ image: UIImage) -> Void)?){
        let data = try? Data(contentsOf: imageURL)
        guard data != nil else {
            print("There doesn't appear to be any image")
            return
        }
        guard let image = UIImage(data: data!) else {
            print("Could not transfer data into image")
            return
        }
        completion?(image)
    }
    
}
