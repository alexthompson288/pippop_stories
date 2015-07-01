//
//  ReadingContentController.swift
//  Pippop Stories
//
//  Created by Alex Thompson on 30/06/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.
//

import Foundation
import UIKit


class ReadingContentController: UIViewController, UIPageViewControllerDataSource {
    
    var pageViewController: UIPageViewController!
    var pageImages: NSArray!
    var pageMedia = NSArray()
    var activityData = []
    var name = ""
    
    
    override func viewDidLoad() {
        println("Reading content VC Loaded.")
        println("Activity show view loaded. Activity data has \(activityData.count) pages")
        downloadPageImages()
        
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        
        var startVC = self.viewControllerAtIndex(0) as ContentViewController
        var viewControllers = NSArray(object: startVC)
        
        self.pageViewController.setViewControllers(viewControllers as [AnyObject], direction: .Forward, animated: true, completion: nil)
        
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.size.height)
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        
    }
    
    func downloadPageImages(){
        for page in activityData {
            var thisDict: NSDictionary = page as! NSDictionary
            Utility.writeImagesLocally(thisDict)
        }
    }
    
    @IBAction func BackToBooksButton(sender: AnyObject) {
        var vc: SubjectsCollectionController = self.storyboard?.instantiateViewControllerWithIdentifier("SubjectsCollectionID") as! SubjectsCollectionController
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        println("Memory Warning")
    }
    
    func viewControllerAtIndex(index: Int) -> ContentViewController
    {
        if ((self.activityData.count == 0) || (index >= self.activityData.count)) {
            return ContentViewController()
        }
        
        var vc: ContentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ContentViewController") as! ContentViewController
        var mediaType = ""
        println("Creating view controller number \(index). About to set data...")
        if let audioPresent = self.activityData[index]["url_audio_remote"] as? String{
            if audioPresent != "" {
                println("There is audio here...")
                mediaType = "audio"
                vc.url_audio_remote = self.activityData[index]["url_audio_remote"] as! String
                vc.url_audio_local = self.activityData[index]["url_audio_local"] as! String
            }
        }
        vc.mediaType = mediaType
        vc.imageFile = self.activityData[index]["url_image_remote"] as! String
        vc.localImageFile = self.activityData[index]["url_image_local"] as! String
        vc.dataDict = self.activityData[index] as! NSDictionary
        vc.pageIndex = index
        
        println("Returning content VC number \(index)")
        return vc
    }
    
    
    // MARK: - Page View Controller Data Source
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        
        var vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        
        
        if (index == 0 || index == NSNotFound)
        {
            return nil
            
        }
        
        index--
        return self.viewControllerAtIndex(index)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        
        if (index == NSNotFound)
        {
            return nil
        }
        
        index++
        
        if (index == self.activityData.count)
        {
            return nil
        }
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return self.activityData.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int
    {
        return 0
    }
    
}

