//
//  HomeScreenViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 8/28/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class HomeScreenViewController: UIViewController, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var searchController: UISearchController?

    override func viewDidLoad() {
        super.viewDidLoad()
        SearchController.sharedController.getUsersTopArtistsForHomeScreen()
        setupSearchController()
        tableView.tableHeaderView = searchController?.searchBar
        guard AuthViewController.session != nil else {
            let authVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("authVC")
            let topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
            guard let topViewC = topVC else {
                print("There was no topVC")
                return
            }
            topViewC.presentViewController(authVC, animated: true, completion: nil)
            return
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateTableView), name: "topArtistLoaded", object: nil)
    }

    func setupSearchController(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultsController = storyboard.instantiateViewControllerWithIdentifier("resultsVC")
        
        searchController = UISearchController(searchResultsController: resultsController)
        
        guard let searchController = searchController else {return}
        
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.placeholder = "Search for an Artist"
        searchController.definesPresentationContext = true
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let text = searchController.searchBar.text,
            resultsController = searchController.searchResultsController as? SearchResultsTableViewController else {return}
        
        dispatch_async(dispatch_get_main_queue()) {
            SearchController.searchForArtist(text, completion: { 
                resultsController.tableView.reloadData()
            })
            
        }
    }
    
    func updateTableView() {
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Top Artists"
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchController.topArtists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("artistCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = SearchController.topArtists[indexPath.row].name
        
        return cell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
