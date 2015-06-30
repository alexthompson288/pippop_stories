//
//  ContentViewController.swift
//  Pippop Stories
//
//  Created by Alex Thompson on 30/06/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.
//

//
//  ContentViewController.swift
//  pippopactivities
//
//  Created by Alex Thompson on 31/05/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class ContentViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var ContentImage: UIImageView!
    
    var pageIndex: Int!
    var imageFile: String!
    var localImageFile: String!
    var dataDict: NSDictionary!
    
    var activityViewController = UIActivityViewController()
    var learnerID = Int()
    
    @IBOutlet weak var ReadingImage: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        println("Local image file is \(localImageFile)")
        println("The dataDict is \(dataDict)")
        var filePath = Utility.createFilePathInDocsDir(localImageFile as String)
        var fileExists = Utility.checkIfFileExistsAtPath(filePath)
        if fileExists == true {
            println("Image is present called \(filePath)")
            self.ReadingImage.image = UIImage(named: filePath)
        } else {
            println("Unable to find image. Will write to write from network")
            writeImagesLocally(dataDict)
        }
        
        
        //        learnerID = NSUserDefaults.standardUserDefaults().objectForKey("learnerID") as! Int
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func writeImagesLocally(dataInput: NSDictionary) {
        var localImageFilename: NSString?
        localImageFilename = dataInput["url_image_local"] as? NSString
        var remoteImageFilename: NSString?
        remoteImageFilename = dataInput["url_image_remote"] as? NSString
        println("Remote image filename \(remoteImageFilename)")
        if let ImgLocal = localImageFilename {
            var imgPathAsString: String = ImgLocal as! String
            var imgPathAsStringExtra = Utility.createFilePathInDocsDir(imgPathAsString)
            println("Inside image local. \(imgPathAsStringExtra)")
            var fileExists = Utility.checkIfFileExistsAtPath(imgPathAsStringExtra)
            if fileExists == true {
                println("Local file exists at \(imgPathAsStringExtra)")
            } else {
                println("Local file does not exist. Was named \(ImgLocal). About to get remote url and pull from network")
                if let ImgRemote: NSString = remoteImageFilename {
                    println("Network location is \(ImgRemote)")
                    let URL = NSURL(string: ImgRemote as String)
                    println("Converted string to URL")
                    let qos = Int(QOS_CLASS_USER_INITIATED.value)
                    println("About to run async off main queue")
                    dispatch_async(dispatch_get_global_queue(qos, 0)){() -> Void in
                        let imageData = NSData(contentsOfURL: URL!)
                        println("Got image data. About to write it")
                        var localPath:NSString = Utility.documentsPathForFileName(ImgLocal as String)
                        imageData!.writeToFile(localPath as String, atomically: true)
                        println("Written image as data to \(localPath)")
                        dispatch_async(dispatch_get_main_queue()){
                            if Utility.checkIfFileExistsAtPath(localPath as String) == true {
                                println("File does exist. Reloading collection table")
                                self.ReadingImage.image = UIImage(named: localPath as String)
                            } else {
                                println("No luck with image local or remote")
                            }
                        }
                    }
                } else {
                    println("remote Image filename empty")
                }
            }
        }
    }
    
    
}

