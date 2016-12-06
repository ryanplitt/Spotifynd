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
    
    
    override func viewWillAppear(_ animated: Bool) {
        let indexForSegmentedController = UserDefaults.standard.object(forKey: SettingsTableViewController.topArtistsRangeIntDefaultsKey) as? Int ?? 2
        topArtistsRangeSegmentedController.selectedSegmentIndex = indexForSegmentedController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        artistsInLibraryCheckSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsTableViewController.artistsNSUserDefaultsKey)
        songsInLibraryCheckSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsTableViewController.songNSUserDefaultsKey)
    }

    
    @IBAction func artistsRangeSegmentValueChanged(_ sender: AnyObject) {
        let topAritstRangeDict = [0:"short_term",1:"medium_term",2:"long_term"]
        let onValue = topArtistsRangeSegmentedController.selectedSegmentIndex
        UserDefaults.standard.set(topAritstRangeDict[onValue], forKey: SettingsTableViewController.topArtistsRangeNSUserDefaultsKey)
        UserDefaults.standard.set(onValue, forKey: SettingsTableViewController.topArtistsRangeIntDefaultsKey)
    }
    
    @IBAction func artistsInLibraryCheckValueChanged(_ sender: AnyObject) {
        
        let value = artistsInLibraryCheckSwitch.isOn
        UserDefaults.standard.set(value, forKey: SettingsTableViewController.artistsNSUserDefaultsKey)
        if value {
            songsInLibraryCheckSwitch.isOn = true
            songsInLibraryCheckSwitch.isEnabled = false
        }
        if !value {
            songsInLibraryCheckSwitch.isEnabled = true
        }
    }
    
    @IBAction func songsInLibraryCheckValueChanged(_ sender: AnyObject) {
        let value = songsInLibraryCheckSwitch.isOn
        UserDefaults.standard.set(value, forKey: SettingsTableViewController.songNSUserDefaultsKey)
        if value {
            return
        }
    }

    @IBAction func logOutButtonTapped(_ sender: AnyObject) {
        let player = PlayerViewController.sharedPlayer.player
        
        guard let session = PlayerController.session else {
            print("There is no session to save")
            return
        }
        PlayerController.sharedController.saveSessionToUserDefaults(session)
        AuthViewController.SPTAuthSharedViewController?.clearCookies({
        })
        player?.logout()
        self.performSegue(withIdentifier: "toInitalViewController", sender: self)
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
