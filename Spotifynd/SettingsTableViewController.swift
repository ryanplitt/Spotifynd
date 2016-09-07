//
//  SettingsTableViewController.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 9/5/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var topArtistsRangeSegmentedController: UISegmentedControl!
    @IBOutlet weak var artistsInLibraryCheckSwitch: UISwitch!
    @IBOutlet weak var songsInLibraryCheckSwitch: UISwitch!
    
    static let artistsNSUserDefaultsKey = "artistsNSUserDefaultsKey"
    static let songNSUserDefaultsKey = "songNSUserDefaultsKey"
    static let topArtistsRangeNSUserDefaultsKey = "TopArtistsRange"
    static let topArtistsRangeIntDefaultsKey = "TopArtistsRangeInt"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        topArtistsRangeSegmentedController.selectedSegmentIndex = NSUserDefaults.standardUserDefaults().integerForKey(SettingsTableViewController.topArtistsRangeIntDefaultsKey)
        artistsInLibraryCheckSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(SettingsTableViewController.artistsNSUserDefaultsKey)
        songsInLibraryCheckSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(SettingsTableViewController.songNSUserDefaultsKey)
    }

    
    @IBAction func artistsRangeSegmentValueChanged(sender: AnyObject) {
        let topAritstRangeDict = [0:"short_term",1:"medium_term",2:"long_term"]
        let onValue = topArtistsRangeSegmentedController.selectedSegmentIndex
        NSUserDefaults.standardUserDefaults().setObject(topAritstRangeDict[onValue], forKey: SettingsTableViewController.topArtistsRangeNSUserDefaultsKey)
        NSUserDefaults.standardUserDefaults().setInteger(onValue, forKey: SettingsTableViewController.topArtistsRangeIntDefaultsKey)
    }
    
    @IBAction func artistsInLibraryCheckValueChanged(sender: AnyObject) {
        
        let value = artistsInLibraryCheckSwitch.on
        NSUserDefaults.standardUserDefaults().setBool(value, forKey: SettingsTableViewController.artistsNSUserDefaultsKey)
        if value {
            songsInLibraryCheckSwitch.on = true
            songsInLibraryCheckSwitch.enabled = false
        }
        if !value {
            songsInLibraryCheckSwitch.enabled = true
        }
    }
    
    @IBAction func songsInLibraryCheckValueChanged(sender: AnyObject) {
        let value = songsInLibraryCheckSwitch.on
        NSUserDefaults.standardUserDefaults().setBool(value, forKey: SettingsTableViewController.songNSUserDefaultsKey)
        if value {
            return
        }
    }

    @IBAction func logOutButtonTapped(sender: AnyObject) {
        let player = PlayerViewController.sharedPlayer.player
        player?.logout()
        self.performSegueWithIdentifier("toInitalViewController", sender: self)
    }
    // MARK: - Table view data source

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
