//
//  SubjectsCollectionController.swift
//  Pip Videos
//
//  Created by Alex Thompson on 11/06/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.
//

import UIKit
import Alamofire
import AFNetworking
import Mixpanel
import StoreKit
import MediaPlayer

let mixpanel = Mixpanel.sharedInstanceWithToken("dd4de5662c2520e42dc263f722e5c554")

class SubjectsCollectionController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var imageCache = NSCache()
    let manager = AFHTTPRequestOperationManager()
    let filemgr = NSFileManager.defaultManager()
    let homedir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    @IBOutlet weak var SubjectsCollectionView: UICollectionView!
//    @IBOutlet weak var ActivitySpinner: UIActivityIndicatorView!
    var data = [] { didSet { updateUI() }}
    var learners = []
    var learnerName: String?
    var learnerID: Int?
    var access_token: String!
    var moviePlayer = MPMoviePlayerController()
    
    @IBOutlet weak var LoggedInAsLabel: UILabel!
    
    override func viewDidLoad() {
        self.access_token = NSUserDefaults.standardUserDefaults().objectForKey("access_token") as! String
        self.moviePlayer.stop()
        //        var token = NSUserDefaults.standardUserDefaults().objectForKey("access_token") as! NSString
        //        println("Access token is \(token)")
        super.viewDidLoad()
        setLearnersData()
        self.SubjectsCollectionView.delegate = self
        self.SubjectsCollectionView.dataSource = self
        loadData()
        updateAccessToken()
        trackMixpanelUsers()
    }
    
    func updateUI(){
        var name = NSUserDefaults.standardUserDefaults().objectForKey("learnerName") as? String
        if let thisName = name {
            self.LoggedInAsLabel.text = "Logged in as \(thisName)"
        }
        dispatch_async(dispatch_get_main_queue()){
//            println("About to refresh table. Data count is \(self.data.count). Data is \(self.data)")
            self.SubjectsCollectionView.reloadData()
        }
    }

    
    @IBAction func LogoutButton(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("email")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("password")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("access_token")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("learnerID")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("learnerName")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("premium_access")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("access_expiration")

        var vc: NewLoginController = self.storyboard?.instantiateViewControllerWithIdentifier("LoginControllerID") as! NewLoginController
        presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func ChangeLearnerButton(sender: AnyObject) {
        println("Change learner button pressed")
        mixpanel.identify("\(self.learnerID)")
        mixpanel.track("Changing learner", properties: ["name": "\(learnerID)"])

        
        let optionMenu = UIAlertController(title: nil, message: "Choose Learner", preferredStyle: .ActionSheet)
        optionMenu.popoverPresentationController?.sourceView = sender as! UIView
        
        for learner in learners {
            // 2
            var name = learner["name"] as! String
            var id = learner["id"] as! Int
            var premium_access = learner["premium_access"] as! Bool
            let chooseAction = UIAlertAction(title: "\(name)", style: .Default, handler: {
                (alert: UIAlertAction!) -> Void in
                println("New learner chosen: \(name)")
                NSUserDefaults.standardUserDefaults().setObject(name, forKey: "learnerName")
                NSUserDefaults.standardUserDefaults().setObject(id, forKey: "learnerID")
                NSUserDefaults.standardUserDefaults().setObject(premium_access, forKey: "premium_access")
                self.updateUI()
                self.trackMixpanelUsers()
            })
            optionMenu.addAction(chooseAction)
        }
        // 5
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    
    func loadData() {
//        self.ActivitySpinner.hidden = false
//        self.ActivitySpinner.startAnimating()
        println("Starting the loadData function")
        
        var filePath = Utility.createFilePathInDocsDir("data.plist")
        var fileExists = Utility.checkIfFileExistsAtPath(filePath)
        if fileExists {
            println("File exists at \(filePath)...")
            var thisDict = Utility.loadJSONDataAtFilePath(filePath)
            var thisData: NSArray = thisDict["storysets"] as! NSArray
            self.data = thisData
            println("Number of experiences is \(data.count)")
//            self.ActivitySpinner.stopAnimating()
//            self.ActivitySpinner.hidden = true
            return;
        } else {
            var url = Constants.BooksUrl
            println("File doesn't exist locally. Constant is \(url)")
            if let learner = self.learnerID {
                println("Getting JSON FROM SERVER FOR BOOKS")
                getJSON(url, token: self.access_token, learner_id: learner)
            }
            
        }
    }
    
    func getJSON(api:String, token: String, learner_id: Int) {
        let url = NSURL(string: api)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        
        request.HTTPBody = "{\n\"learner_id\": \(learner_id)\n}".dataUsingEncoding(NSUTF8StringEncoding);
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data: NSData!, response: NSURLResponse!, error: NSError!) in
            if error != nil {
                println("Error hitting API")
                return
            } else {
                println("Received data...\(data)")
                var encodedJSON:NSDictionary = Utility.dataToJSON(data)
                Utility.saveJSONWithArchiver(encodedJSON, savedName: "data.plist")
                self.loadData()
//                self.ActivitySpinner.stopAnimating()
//                self.ActivitySpinner.hidden = true
            }
        }
        task.resume()
    }
    
    func refreshRemoteData(){
        println("Refresh data func")
    }

    func refresh(){
        println("Inside refresh function. About to loadremoteData()...")
        refreshRemoteData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        println("Number of sections...")
        return self.data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        println("Looping over cells...")
        var Mycell: SubjectCollectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("SubjectCollectionCellID", forIndexPath: indexPath) as! SubjectCollectionCell
        let subject:NSDictionary = data[indexPath.row] as! NSDictionary;
        var subjectTitle = subject["title"] as! NSString;
        Mycell.SubjectTitleLabel.text = subjectTitle as String
        
        var urlImageRemote = subject["url_image_remote"] as! String
        println("Image remote url is \(urlImageRemote)")
        var urlImageOffline = subject["url_image_local"] as! String
        println("Offline image name is \(urlImageOffline)")
        var thisDescription = subject["description"] as! String
        Mycell.SubjectDescriptionLabel.text = thisDescription
        
//        CHECK IF IMAGE IN CACHE
        let cachedir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as! NSString
        var cachedImgURL = NSURL()
        if let cacheURLDir = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
            println("The cached URL is \(cacheURLDir)")
            cachedImgURL = cacheURLDir.URLByAppendingPathComponent(urlImageOffline)
        }
        var cachedimgpath = "/\(cachedir)/\(urlImageOffline)"
        println("Cached image path is \(cachedimgpath)")
        if filemgr.fileExistsAtPath(cachedimgpath){
            println("There is an image saved here: \(cachedimgpath). Setting image.")
            Mycell.SubjectImage.setImageWithURL(cachedImgURL);
        } else {
//            GET IMAGE FROM NETWORK
            var urlImageRemotePath: NSURL = NSURL(string: urlImageRemote)!
            let request: NSURLRequest = NSURLRequest(URL: urlImageRemotePath)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                if error == nil {
//                    SAVE IMAGE TO CACHE AND DISPLAY
                    self.filemgr.createFileAtPath(cachedimgpath, contents: data,
                        attributes: nil)
                    Mycell.SubjectImage.setImageWithURL(cachedImgURL);
                    println("Saved image to cached path \(cachedimgpath)")
                }
                else {
                    println("Error: \(error.localizedDescription)")
                }
            })
        }
        
        return Mycell;
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        mixpanel.identify("\(learnerID!)");
//        mixpanel.track("Chose a subject")
        var vc: VideosCollectionController = self.storyboard?.instantiateViewControllerWithIdentifier("VideoCollectionID") as! VideosCollectionController
        var specData = data[indexPath.row]["books"] as! NSArray
        vc.data = []
        vc.data = specData
        self.presentViewController(vc, animated: true, completion: nil)
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1,1,1)
        })
    }
    
    func setLearnersData(){
        var filepath = Utility.createFilePathInDocsDir("userData.plist")
        var dataPresent = Utility.checkIfFileExistsAtPath(filepath)
        if dataPresent{
            var data = Utility.loadJSONDataAtFilePath(filepath)
            var ownerName = data["name"] as! String
            var ownerId = data["id"] as! Int
            var ownerType = data["user_type"] as! String
            NSUserDefaults.standardUserDefaults().setObject(ownerName, forKey: "ownerName")
            NSUserDefaults.standardUserDefaults().setObject(ownerId, forKey: "ownerID")
            NSUserDefaults.standardUserDefaults().setObject(ownerType, forKey: "ownerType")

            
            learners = data["learners"] as! NSArray
            if let currentLearner = NSUserDefaults.standardUserDefaults().objectForKey("learnerID") as? Int {
                println("Setting learner ID value")
                self.learnerID = currentLearner
                self.learnerName = NSUserDefaults.standardUserDefaults().objectForKey("learnerName") as? String
            } else {
                for learner in learners {
                    var name: String = learner["name"] as! String
                    println("Learner name is \(name)")
                }
                var firstLearner:NSDictionary = learners[0] as! NSDictionary
                var name = firstLearner["name"] as! String
                var id = firstLearner["id"] as! Int
                var premium_access = firstLearner["premium_access"] as! Bool
                println("Premium access is...\(premium_access)")
                NSUserDefaults.standardUserDefaults().setObject(name, forKey: "learnerName")
                NSUserDefaults.standardUserDefaults().setObject(id, forKey: "learnerID")
                NSUserDefaults.standardUserDefaults().setObject(premium_access, forKey: "premium_access")
                self.learnerID = NSUserDefaults.standardUserDefaults().objectForKey("learnerID") as? Int
                learnerName = NSUserDefaults.standardUserDefaults().objectForKey("learnerName") as? String
            }
        }
        
        if let name = learnerName {
            self.LoggedInAsLabel.text = "Logged in as \(name)"
        }
    }
    
    @IBAction func updateData(sender: AnyObject) {
        var url = Constants.BooksUrl
        var thisLearner = NSUserDefaults.standardUserDefaults().objectForKey("learnerID") as! Int
        println("Updating data manually \(url). Learner id is \(thisLearner)")
        println("Getting JSON FROM SERVER FOR BOOKS")
        getJSON(url, token: self.access_token, learner_id: thisLearner)
    }
    
    
    func updateAccessToken(){
        var email = NSUserDefaults.standardUserDefaults().objectForKey("email") as? String
        var password = NSUserDefaults.standardUserDefaults().objectForKey("password") as? String
        Alamofire.request(.POST, Constants.TokenUrl, parameters: ["email": email!, "password": password!]).responseJSON { (_, _, JSON, _) in
            println("The data is response for update token is \(JSON)")
            if let tokenData:NSDictionary = JSON as? NSDictionary {
                var expires = tokenData["token_expiration_date"] as! NSString
                var token = tokenData["access_token"] as! NSString
                NSUserDefaults.standardUserDefaults().setObject(expires, forKey: "access_expiration")
                NSUserDefaults.standardUserDefaults().setObject(token, forKey: "access_token")
                println("Updated the expiration date of the token in User defaults...")
                Utility.saveJSONWithArchiver(tokenData, savedName: "userData.plist")
                var thisLearners: NSArray = tokenData["learners"] as! NSArray
                if let thisLearnerID = self.learnerID {
                    for learner in thisLearners {
                        if thisLearnerID == learner["id"] as! Int {
                            println("Updated the premium status of the saved learner")
                            var thisPremiumAccess = learner["premium_access"] as! Bool
                            NSUserDefaults.standardUserDefaults().setObject(thisPremiumAccess, forKey: "premium_access")
                        }
                    }
                }
                
            }
        }

    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Landscape.rawValue)
    }
    
    func trackMixpanelUsers(){
        
        var email = NSUserDefaults.standardUserDefaults().objectForKey("email") as! String
        var userID = NSUserDefaults.standardUserDefaults().objectForKey("ownerID") as! Int
        var ownerName = NSUserDefaults.standardUserDefaults().objectForKey("ownerName") as! String
        var thisLearnerName = NSUserDefaults.standardUserDefaults().objectForKey("learnerName") as! String
        var learnerID = NSUserDefaults.standardUserDefaults().objectForKey("learnerID") as! Int
        var ownerType = NSUserDefaults.standardUserDefaults().objectForKey("ownerType") as! String
        println("Sending out mixpanel message with email: \(email), learnerID: \(learnerID), date: \(NSDate())")
        mixpanel.identify("\(learnerID)");
        mixpanel.people.set(["$email":"\(email)", "$first_name":"\(thisLearnerName)", "$created": "\(NSDate())", "owner_name":"\(ownerName)", "owner_id":"\(userID)", "owner_type":"\(ownerType)"])
        mixpanel.track("Opened app")
    }
    
    
}

