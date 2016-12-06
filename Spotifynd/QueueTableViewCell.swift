//
//  QueueTableViewCell.swift
//  Spotifynd
//
//  Created by Ryan Plitt on 9/2/16.
//  Copyright © 2016 Ryan Plitt. All rights reserved.
//

import UIKit

class QueueTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var nowPlayingImage: UIImageView!
    
    func updateCellWithTrack(_ title: String, artist: String){
        artistLabel.text = artist
        titleLable.text = title
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
