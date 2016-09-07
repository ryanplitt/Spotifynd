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
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "topArtistLoaded", object: nil))
        }
    }
    static var range: String?
    
    static func searchForArtist(name: String, completion: () -> Void){
        SPTSearch.performSearchWithQuery(name, queryType: .QueryTypeArtist, accessToken: PlayerController.authToken) { (error, list) in
            if error != nil {
                print(error.localizedDescription)
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
        dispatch_async(dispatch_get_main_queue()) {
            if NSUserDefaults.standardUserDefaults().objectForKey(SettingsTableViewController.topArtistsRangeNSUserDefaultsKey) == nil {
                SearchController.range = "long_term"
            } else {
                SearchController.range = NSUserDefaults.standardUserDefaults().objectForKey(SettingsTableViewController.topArtistsRangeNSUserDefaultsKey) as! String
            }
            var responseResponse: NSURLResponse?
            var responseData: NSData?
            var listPage = SPTListPage?()
            var request: NSURLRequest?
            do {
                request = try SPTRequest.createRequestForURL(NSURL(string: "https://api.spotify.com/v1/me/top/artists"), withAccessToken: PlayerController.authToken, httpMethod: "GET", values: ["time_range":SearchController.range!,"limit":20], valueBodyIsJSON: true, sendDataAsQueryString: true)
            } catch {
                print("error getting request")
            }
            let artistFetchGroup = dispatch_group_create()
            dispatch_group_enter(artistFetchGroup)
            SPTRequest.sharedHandler().performRequest(request) { (error, response, data) in
                guard data != nil else {print("data was nil") ; return}
                responseResponse = response
                responseData = data
                dispatch_group_leave(artistFetchGroup)
            }
            dispatch_group_notify(artistFetchGroup, dispatch_get_main_queue(), {
                print("Group Dispatch working")
                do {
                    listPage = try SPTListPage(fromData: responseData, withResponse: responseResponse, expectingPartialChildren: false, rootObjectKey: nil)
                    SearchController.topArtists = listPage?.items.flatMap({$0}) as! [SPTArtist]
                } catch { print("There was an error setting ListPage") }
            })
        }
    }
}