//
//  Auth&SearchController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/29/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import Foundation

class SearchController {
    
    static let sharedController = SearchController()
    
    static var transferedResult: SPTPartialArtist = SPTPartialArtist()
    static var results: [SPTPartialArtist] = []
    static var topArtists: [SPTArtist] = [] {
        didSet{
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "topArtistLoaded"), object: nil))
        }
    }
    static var range: String?
    
    static func searchForArtist(_ name: String, completion: @escaping () -> Void){
        SPTSearch.perform(withQuery: name, queryType: .queryTypeArtist, accessToken: PlayerController.authToken) { (error, list) in
            if error != nil {
                print(error?.localizedDescription)
                completion()
                return
            }
            let page = list as! SPTListPage
            let artists = page.items as? [SPTPartialArtist]
            guard let artistList = artists else {return}
            results = artistList
            completion()
        }
    }
    
    func getUsersTopArtistsForHomeScreen(){
        DispatchQueue.main.async {
            if UserDefaults.standard.object(forKey: SettingsTableViewController.topArtistsRangeNSUserDefaultsKey) == nil {
                SearchController.range = "long_term"
            } else {
                SearchController.range = UserDefaults.standard.object(forKey: SettingsTableViewController.topArtistsRangeNSUserDefaultsKey) as! String
            }
            var responseResponse: URLResponse?
            var responseData: Data?
            var listPage: SPTListPage?
            var request: URLRequest?
            do {
                request = try SPTRequest.createRequest(for: URL(string: "https://api.spotify.com/v1/me/top/artists"), withAccessToken: PlayerController.authToken, httpMethod: "GET", values: ["time_range":SearchController.range!,"limit":20], valueBodyIsJSON: true, sendDataAsQueryString: true)
            } catch {
                print("error getting request")
            }
            let artistFetchGroup = DispatchGroup()
            artistFetchGroup.enter()
            SPTRequest.sharedHandler().perform(request) { (error, response, data) in
                guard data != nil else {print("data was nil") ; return}
                responseResponse = response
                responseData = data
                artistFetchGroup.leave()
            }
            artistFetchGroup.notify(queue: DispatchQueue.main, execute: {
                print("Group Dispatch working")
                do {
                    listPage = try SPTListPage(from: responseData, with: responseResponse, expectingPartialChildren: false, rootObjectKey: nil)
                    SearchController.topArtists = listPage?.items.flatMap({$0}) as! [SPTArtist]
                } catch { print("There was an error setting ListPage") }
            })
        }
    }
}
