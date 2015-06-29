//  VideoCollectionCell.swift
//  Pip Videos
//
//  Created by Alex Thompson on 11/06/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.

import UIKit
import MediaPlayer
import Alamofire

class VideoCollectionCell: UICollectionViewCell {
    var moviePlayer: MPMoviePlayerController!
    var url_video_remote: String!
    var url_video_local: String!
    var hasLocalVideo: Bool!{ didSet { updateUI() } }
    var total_url_video_local: String!
    var video_URL: NSURL!
    var canWatch: Bool!
    var indexPath: Int!
    var activityId: Int!
    var activityType = "Cms::Pipisode"
    var learnerId: Int!
    var token: String!
    var temp_url_video_location: String!
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
    
    @IBAction func PlayVideoButton(sender: AnyObject) {
        self.token = NSUserDefaults.standardUserDefaults().objectForKey("access_token") as! String
        if let currentLearner = NSUserDefaults.standardUserDefaults().objectForKey("learnerID") as? Int {
            self.learnerId = currentLearner
        }
        mixpanel.identify("\(learnerId!)");
        mixpanel.track("Watch video", properties: ["name": "\(url_video_local)"])
        if canWatch == true {
            if hasLocalVideo == true {
//                println("Play video! Path is \(url_video_local)")
                if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                    video_URL = directoryURL.URLByAppendingPathComponent(self.url_video_local)
                    
//                    println("Total local video url is \(video_URL)")
                } else {
//                    println("Problem finding local docs folder...")
                }
            }
            else {
//                println("Play video! Path is \(url_video_remote)")
                video_URL = NSURL(string: self.url_video_remote)!
            }
            self.moviePlayer = MPMoviePlayerController(contentURL: video_URL)
            self.moviePlayer.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            self.addSubview(self.moviePlayer.view)
            self.moviePlayer.controlStyle = MPMovieControlStyle.Fullscreen
            self.moviePlayer.fullscreen = true
            self.moviePlayer.play()
            Utility.postActivityDataToServers(self.token, learner_id: self.learnerId, activity_id: self.activityId, activity_type: self.activityType)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(userPressedPadlock, object: self)
            
            println("Popping up payment gate")
            mixpanel.identify("\(learnerId!)")
            mixpanel.track("Locked content", properties: ["name": "\(url_video_local)"])
        }
    }
    
    @IBAction func WriteOrDeleteVideoLocally(sender: AnyObject) {
        if hasLocalVideo == true {
//            DELETE LOCALLY STORED VIDEO
            println("About to remove local version")
            var filePath = Utility.createFilePathInDocsDir(url_video_local)
            filemanager.removeItemAtPath(filePath as String, error: nil)
            println("Video deleted")
            hasLocalVideo = false
            var img = UIImage(named: "download")
            DownloadButtonLabel.setBackgroundImage(img, forState: nil)
            
        } else {
//            WRITE TO DISC
            NSNotificationCenter.defaultCenter().postNotificationName(userDownloadsVideo, object: self, userInfo: ["url_video_local": "\(self.url_video_local)", "url_video_remote":"\(self.url_video_remote)", "indexPath":"\(indexPath)", "title":"\(VideoTitlaVar)"])
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
    
    func addSkipBackupAttributeToItemAtURL(URL:NSURL) ->Bool{
        let fileManager = NSFileManager.defaultManager()
        var error:NSError?
        let success:Bool = URL.setResourceValue(NSNumber(bool: true),forKey: NSURLIsExcludedFromBackupKey, error: &error)
        if !success{
            println("Error excluding \(URL.lastPathComponent) from backup \(error)")
        }
        println("Successfully removed backup flag")
        return success;
    }
    
}

