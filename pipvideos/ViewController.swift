//
//  ViewController.swift
//  pipvideos
//
//  Created by Alex Thompson on 30/01/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.
//

import UIKit
import MediaPlayer
import Alamofire

class ViewController: UIViewController {
    
    var moviePlayer: MPMoviePlayerController!
    
    var video_url:String = ""
    var video_offline_url:NSString = ""
    var video_title:String = ""
    var video_filename:String = ""
    var video_image:String = ""
    var video_description:String = ""
    var video_learningobjective:String = ""
    

    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as? NSString
    
    
    @IBOutlet weak var DownloadProgressBar: UIProgressView!
    @IBOutlet weak var VideoTitleLabel: UILabel!
    
    @IBOutlet weak var DownloadButton: UIButton!
    
    @IBOutlet weak var VideoImageData: UIImageView!
    
    @IBOutlet weak var VideoDescriptionText: UILabel!
    
    @IBAction func PlayVideoButton(sender: AnyObject) {
        println("Play video")
        println("Video offline url is \(self.video_offline_url)")
        var filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(self.video_offline_url as String){
            println("file exists at this path")
            println(self.video_offline_url)
            var totalurl = NSURL()
            if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                println("Video filename... \(self.video_filename)")
                println(directoryURL)
                println("directory url")
                totalurl = directoryURL.URLByAppendingPathComponent(self.video_filename)
                println("Total url")
                println(totalurl)
            }
            self.moviePlayer = MPMoviePlayerController(contentURL: totalurl)
            println("end of function")
        }else{
            println("no file at this path")
            println("Use web URL")
            var video_URL: NSURL = NSURL(string: video_url)!
            self.moviePlayer = MPMoviePlayerController(contentURL: video_URL)
        }
        
        self.moviePlayer.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        self.view.addSubview(self.moviePlayer.view)
        
        self.moviePlayer.controlStyle = MPMovieControlStyle.Fullscreen
        println(video_url)
        self.moviePlayer.fullscreen = true
        self.moviePlayer.play()
    }
    
    @IBAction func DownloadVideo(sender: AnyObject) {
        var filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(self.video_offline_url as String){
            
            filemanager.removeItemAtPath(self.video_offline_url as String, error: nil)
            println("Video deleted")
            self.DownloadButton.setTitle("Download", forState: .Normal)
            self.video_offline_url = ""
            
        } else {
        
            println("Starting download...")
            let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
                (temporaryURL, response) in
                
                if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                    println("Video filename... \(self.video_filename)")
                    println(directoryURL)
                    println("directory url")
                    var totalurl = directoryURL.URLByAppendingPathComponent(self.video_filename)
                    println("Total url")
                    println(totalurl)
                    self.video_offline_url = totalurl.absoluteString!
                    println("Video offline URL is \(self.video_offline_url)")
                    return directoryURL.URLByAppendingPathComponent("\(self.video_filename)")
                }
                println("Downloaded...")
                println(temporaryURL)
                return temporaryURL
            }

            
            Alamofire.download(.GET, video_url, destination).progress {
                (_, totalBytesRead, totalBytesExpectedToRead) in
                println("Total bytes read \(totalBytesRead)")
                println("Desitination is \(destination)")
                dispatch_async(dispatch_get_main_queue()) {
                    self.DownloadProgressBar.setProgress(Float(totalBytesRead) / Float(totalBytesExpectedToRead), animated: true)
                    self.DownloadButton.setTitle("Downloading...", forState: .Normal)
                    
                    if totalBytesRead == totalBytesExpectedToRead {
                        self.DownloadProgressBar.removeFromSuperview()
                        self.DownloadButton.setTitle("Delete", forState: .Normal)
                        self.video_offline_url = "/\(self.documentsPath!)/\(self.video_filename)"
                        
                    }
                    
                    
                }
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = video_title
        
        self.video_offline_url = "/\(documentsPath!)/\(self.video_filename)"
        println("VIDEO OFFLINE URL IS \(self.video_offline_url)")
        
        var filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(self.video_offline_url as String){
            self.DownloadButton.setTitle("Delete", forState: .Normal)
        } else {
            self.DownloadButton.setTitle("Download", forState: .Normal)
        }
        
        self.VideoDescriptionText.text = video_description

        var video_image_URL: NSURL = NSURL(string: self.video_image)!
        
        let request: NSURLRequest = NSURLRequest(URL: video_image_URL)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
            if error == nil {
                println("image success")
                self.VideoImageData.image = UIImage(data: data)!
            }
            else {
                println("Error: \(error.localizedDescription)")
            }
        })


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

