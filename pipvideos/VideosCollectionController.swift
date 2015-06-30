import UIKit
import Alamofire
import AFNetworking
import StoreKit
import MediaPlayer

let userPressedPadlock = "user_pressed_padlock"
let userDownloadsVideo = "user_downloads_video"

class VideosCollectionController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var ErrorLabel: UILabel!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var AccessLabel: UILabel!
    @IBOutlet weak var AccessStarImage: UIImageView!
    @IBOutlet weak var PaymentView: UIView!
    @IBOutlet weak var VideosCollectionView: UICollectionView!
    var premium_access: Bool!
    var imageCache = NSCache()
    let manager = AFHTTPRequestOperationManager()
    let filemgr = NSFileManager.defaultManager()
    let homedir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    var data = []
    var products = [SKProduct]()
    var product = SKProduct()
    var accessToken = String()
    var learnerId = Int()
    var userFlow = ""
    var parentPass = false
    var shapes = ["circle","square","triangle"]
    var shape = ""
    var moviePlayer = MPMoviePlayerController()
    var alamoRequest: Alamofire.Request?
    var isDownloading = false { didSet { updateUI() } }
    var connected = false
//    var thisCell: VideoCollectionCell
    
    @IBOutlet weak var ParentGateView: UIView!
    @IBOutlet weak var ParentQuestionLabel: UILabel!
    @IBOutlet weak var CancelDownloadLabel: UIButton!
    
    @IBAction func ParentTriangleButton(sender: AnyObject) {
        if self.shape == "triangle"{
            println("Correct")
            self.parentPass = true
            self.ParentGateView.hidden = true
            self.continueUserFlow()
        } else {
            println("Wrong")
            self.ParentGateView.hidden = true
            
        }
    }
    
    
    @IBAction func ParentCircleButton(sender: AnyObject) {
        if self.shape == "circle"{
            println("Correct")
            self.parentPass = true
            self.ParentGateView.hidden = true
            self.continueUserFlow()
        } else {
            println("Wrong")
            self.ParentGateView.hidden = true
            
        }
    }
    
    
    @IBAction func ParentSquareButton(sender: AnyObject) {
        if self.shape == "square"{
            println("Correct")
            self.parentPass = true
            self.ParentGateView.hidden = true
            self.continueUserFlow()
        } else {
            println("Wrong")
            self.ParentGateView.hidden = true
            
        }
    }
    
    func continueUserFlow(){
        println("In continue user flow, user flow is \(self.userFlow)")
        if self.userFlow == "subscribe" {
            processPayment()
        } else if self.userFlow == "restore" {
            restorePurchase()
        }
    }
    
    func showParentGate() {
        self.ParentGateView.hidden = false
        var newShapes = Utility.shuffle(self.shapes)
        self.shape = newShapes[0]
        self.ParentQuestionLabel.text = "Touch the \(newShapes[0])"
    }


    override func viewWillAppear(animated: Bool) {
        self.ActivityIndicator.hidesWhenStopped = true
    }
    
    override func viewDidLoad() {
        
        println("998877 - There are \(self.VideosCollectionView.numberOfItemsInSection(0)) items in the section.")
        ParentGateView.hidden = true
        PaymentView.hidden = true
        
        self.accessToken = NSUserDefaults.standardUserDefaults().objectForKey("access_token") as! String

        //        var token = NSUserDefaults.standardUserDefaults().objectForKey("access_token") as! NSString
        //        println("Access token is \(token)")
        var premiumAccessVar = NSUserDefaults.standardUserDefaults().objectForKey("premium_access") as? Bool
        if let access = premiumAccessVar{
            
            println("Access status is \(access)")
            self.premium_access = access
            setPremiumAccessInfo()
        }
        
//        ADD OBSERVER TO POP UP PAYMENT GATEWAY
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showPaymentView", name: userPressedPadlock, object: nil)
        super.viewDidLoad()
        getProductIds()
        
//        SET DELEGATE FOR COLLECTION VIEW
        self.VideosCollectionView.delegate = self
        self.VideosCollectionView.dataSource = self
    }
    
    
    func updateUI(){
        dispatch_async(dispatch_get_main_queue()){
//            println("About to refresh table. Data count is \(self.data.count). Data is \(self.data)")
            self.moviePlayer.stop()
            self.VideosCollectionView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
     func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        println("Number of items function...: \(self.data.count)")
        return self.data.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        println("Deque cell \(indexPath.row)")
        var Mycell: VideoCollectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("VideoCollectionCellID", forIndexPath: indexPath) as! VideoCollectionCell
        let video:NSDictionary = data[indexPath.row] as! NSDictionary;
        var label = video["title"] as! NSString
        var description = video["description"] as! String
        var requires_subscription = video["requires_subscription"] as! Bool
        var canWatch: Bool!
        var urlImageRemote = video["url_image_remote"] as! String
        var urlImageLocal = video["url_image_local"] as! String
        var activityId = video["id"] as! Int
        
        if self.premium_access == true {
            canWatch = true
        } else if requires_subscription == false {
            canWatch = true
        } else {
            canWatch = false
        }
//        println("The video is \(label) and can watch is \(canWatch) and premium access is \(self.premium_access)")

        Mycell.indexPath = indexPath.row
        Mycell.canWatch = canWatch
        Mycell.VideoOverviewLabel.text = description
        Mycell.VideoTitle.text = (label as String)
        Mycell.VideoTitlaVar = (label as String)
        if canWatch == false {
            Mycell.VideoLockedImage.image = UIImage(named: "lock")
        } else if canWatch == true {
            Mycell.VideoLockedImage.image = UIImage(named: "")
        }
        Mycell.activityId = activityId
        
//        SET THE IMAGE ON THE BUTTON
        let cachedir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as! NSString
        var cachedImgURL = NSURL()
        if let cacheURLDir = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
//            println("The cached URL is \(cacheURLDir)")
            cachedImgURL = cacheURLDir.URLByAppendingPathComponent(urlImageLocal)
        }
        var cachedimgpath = "/\(cachedir)/\(urlImageLocal)"
//        println("Cached image path is \(cachedimgpath)")
        if filemgr.fileExistsAtPath(cachedimgpath){
//            println("There is an image saved here: \(cachedimgpath). Setting image.")
            var img = UIImage(named: cachedimgpath)
            Mycell.BookImage.image = img

        } else {
            //            GET IMAGE FROM NETWORK
            var urlImageRemotePath: NSURL = NSURL(string: urlImageRemote)!
            let request: NSURLRequest = NSURLRequest(URL: urlImageRemotePath)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                if error == nil {
                    //                    SAVE IMAGE TO CACHE AND DISPLAY
                    self.filemgr.createFileAtPath(cachedimgpath, contents: data,
                        attributes: nil)
                    var img = UIImage(named: cachedimgpath)
                    Mycell.BookImage.image = img

//                    println("Saved image to cached path \(cachedimgpath)")
                }
                else {
                    println("Error: \(error.localizedDescription)")
                }
            })
        }

        return Mycell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var requires_subscription = data[indexPath.row]["requires_subscription"] as! Bool
        var canWatch: Bool!

        if self.premium_access == true {
            canWatch = true
        } else if requires_subscription == false {
            canWatch = true
        } else {
            canWatch = false
        }
        if canWatch == true {
            var vc:ReadingContentController = self.storyboard?.instantiateViewControllerWithIdentifier("ReadingContentID") as! ReadingContentController
            var specData = data[indexPath.row]["bookpages"] as! NSArray
            vc.activityData = []
            vc.activityData = specData
            self.presentViewController(vc, animated: true, completion: nil)
        } else {
            showPaymentView()
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1,1,1)
        })
    }
    
    @IBAction func BackButton(sender: AnyObject) {
        println("Going back to subjects view...")
        if self.isDownloading == true {
            println("Will go back to subjects view...")
            dispatch_async(dispatch_get_main_queue()){
                if let req = self.alamoRequest {
                    req.cancel()
                    println("Request cancelled!")
                    self.alamoRequest = nil
                }
            }
        }

        var vc: SubjectsCollectionController = self.storyboard?.instantiateViewControllerWithIdentifier("SubjectsCollectionID") as! SubjectsCollectionController
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func getProductIds(){
        println("Getting product IDS")
        var productID:NSSet = NSSet(object: "pippop_monthly_5_via_books")
        var productRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: productID as Set<NSObject>)
        productRequest.delegate = self
        productRequest.start()
    }
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        println("add paymnet")
        
        for transaction:AnyObject in transactions {
            var trans = transaction as! SKPaymentTransaction
            println(trans.error)
            println("The transaction full response is \(trans)")
            
            switch trans.transactionState {
                
            case .Purchased, .Restored:
                println("buy, ok unlock iap here")
                println(product.productIdentifier)
                
                let prodID = product.productIdentifier as String
                switch prodID {
                case "pippop_monthly_5_via_books":
                    println("Buying the IAP")
                    println("Transaction identifier is \(trans.transactionIdentifier)")
                    unlockContent()
                    self.ActivityIndicator.hidesWhenStopped = true
                    mixpanel.identify("\(self.learnerId)")
                    mixpanel.track("Subscription success", properties: ["name": "\(prodID)"])
                default:
                    println("IAP not setup")
                    self.ErrorLabel.text = "Purchase unsuccessful this time. Sorry!"
                    self.ActivityIndicator.hidesWhenStopped = true
                    mixpanel.identify("\(self.learnerId)")
                    mixpanel.track("Subscription fail", properties: ["name": "\(prodID)"])
                }
                
                queue.finishTransaction(trans)
                break;
            case .Failed:
                println("buy error")
                queue.finishTransaction(trans)
                break;
            default:
                println("default")
                break;
                
            }
        }
    }
    
    func unlockContent(){
        println("Content unlocked flow begins...")
        self.premium_access = true
        NSUserDefaults.standardUserDefaults().setObject(true, forKey: "premium_access")
        self.PaymentView.hidden = true
        setPremiumAccessInfo()
        updateUI()
        updateSubscriptionsApi()
    }
    
    func updateSubscriptionsApi(){
        var receiptUrl = NSBundle.mainBundle().appStoreReceiptURL
        var receipt: NSData = NSData(contentsOfURL:receiptUrl!, options: nil, error: nil)!
        var receiptdata: NSString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        println("Receipt data is \(receiptdata)")
        
        let aManager = Manager.sharedInstance
        aManager.session.configuration.HTTPAdditionalHeaders = [
            "Authorization": "Token \(self.accessToken)" ]
        
        let URL =  Constants.SubscriptionsUrl
        var parameters = ["subscription": ["itunes_id": "\(receiptdata)"]]
        request(.POST, URL, parameters: parameters, encoding: .JSON)
            .responseJSON {
                (request, response, data, error) -> Void in
                
                println("REQUEST: \(request)")
                println("RESPONSE: \(response)")
                println("DATA: \(data)")
                println("ERROR: \(error)")
        }
    }
    
    func finishTransaction(trans:SKPaymentTransaction)
    {
        println("finish trans")
        SKPaymentQueue.defaultQueue().finishTransaction(trans)
    }
    
    
    func paymentQueue(queue: SKPaymentQueue!, removedTransactions transactions: [AnyObject]!)
    {
        println("remove trans");
    }
    
    
    func showPaymentView(){
        self.PaymentView.hidden = false
    }
    
    func processPayment(){
        self.ActivityIndicator.startAnimating()
        println("Process payment function...")
        var payment = SKPayment(product: self.product)
        if (SKPaymentQueue.canMakePayments()) {
            SKPaymentQueue.defaultQueue().addTransactionObserver(self)
            SKPaymentQueue.defaultQueue().addPayment(payment)
            
        } else {
            println("This device cannot do payments!")
        }
    }
    
    
    @IBAction func Subscribe(sender: AnyObject) {
        println("Subscribe button pressed")
        println("The product is \(self.product). Name is \(self.product.localizedTitle). Price is \(self.product.price)")
        self.userFlow = "subscribe"
        showParentGate()
    }
    
    
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        println("Response received from Apple is \(response)")
        var prods = response.products as Array
        if prods.count > 0 {
            "There are products coming back with the id name"
            for prod in prods {
                self.products.append(prod as! SKProduct)
            }
    //        NEED TO COMMENT BACK IN WHEN IAP LIVE
            self.product = self.products[0]
            println("The product saved is \(self.product). Name is \(self.product.localizedTitle). Price is \(self.product.price)")
        }
    }
    
    @IBAction func DismissPaymentView(sender: AnyObject) {
        self.PaymentView.hidden = true
    }
    
    func setPremiumAccessInfo(){
        if self.premium_access == true {
            self.AccessStarImage.image = UIImage(named: "star_a_150")
            self.AccessLabel.text = "Full access"
        } else {
            self.AccessStarImage.image = UIImage(named: "star_b_150")
            self.AccessLabel.text = "Limited access"
        }
    }

    @IBAction func playPromotionVideo(sender: AnyObject) {
        mixpanel.identify("\(learnerId)");
        mixpanel.track("Watch video", properties: ["name": "Marketing Video"])
        var marketingVideoUrl = NSURL(string: Constants.PromotionVideoUrl)!
        self.moviePlayer = MPMoviePlayerController(contentURL: marketingVideoUrl)
        self.moviePlayer.view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        view.addSubview(self.moviePlayer.view)
        self.moviePlayer.controlStyle = MPMovieControlStyle.Fullscreen
        self.moviePlayer.fullscreen = true
        self.moviePlayer.play()
    }
    
    @IBAction func restorePurchases(sender: AnyObject) {
        self.userFlow = "restore"
        showParentGate()
    }
    
    func restorePurchase(){
        if (SKPaymentQueue.canMakePayments()) {
            println("Starting restore function...")
            SKPaymentQueue.defaultQueue().addTransactionObserver(self)
            SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
        }
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Landscape.rawValue)
    }
    
}
