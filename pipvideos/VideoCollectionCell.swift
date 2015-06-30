//  VideoCollectionCell.swift
//  Pip Videos
//
//  Created by Alex Thompson on 11/06/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.

import UIKit
import MediaPlayer
import Alamofire

class VideoCollectionCell: UICollectionViewCell {
    var url_video_remote: String!
    var url_video_local: String!
    var hasLocalVideo: Bool!{ didSet { updateUI() } }
    var total_url_video_local: String!
    var video_URL: NSURL!
    var canWatch: Bool!
    var indexPath: Int!
    var activityId: Int!
    var activityType = "Cms::Book"
    var learnerId: Int!
    var token: String!
    var filemanager = NSFileManager.defaultManager()
    var VideoTitlaVar: String!
    var connected = false

    @IBOutlet weak var ContainerView: RoundedCornerView!
    @IBOutlet weak var DownloadButtonLabel: UIButton!
    @IBOutlet weak var VideoTitle: UILabel!
    @IBOutlet weak var VideoOverviewLabel: UILabel!
    @IBOutlet weak var VideoLocalIcon: UIImageView!
    @IBOutlet weak var PlayVideoLabel: UIButton!
    @IBOutlet weak var VideoLockedImage: UIImageView!
    
    @IBOutlet weak var BookImage: UIImageView!
    @IBAction func PlayVideoButton(sender: AnyObject) {
    }
    
    @IBAction func WriteOrDeleteVideoLocally(sender: AnyObject) {
        if hasLocalVideo == true {
//            DELETE LOCALLY STORED VIDEO
            
        } else {
//            WRITE TO DISC
        }
    }
    
    func updateUI(){
        if hasLocalVideo == true {
            var img = UIImage(named: "delete")
            self.ContainerView.backgroundColor = ColourValues.greenColor
            DownloadButtonLabel.setBackgroundImage(img, forState: nil)
            VideoLocalIcon.image = UIImage(named: "offline")
        } else {
            var img = UIImage(named: "download")
            DownloadButtonLabel.setBackgroundImage(img, forState: nil)
            self.ContainerView.backgroundColor = ColourValues.yellowColor
            VideoLocalIcon.image = UIImage(named: "")
        }
    }
    
    
}

