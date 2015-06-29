//
//  Constants.swift
//  pippopactivities
//
//  Created by Alex Thompson on 02/06/2015.
//  Copyright (c) 2015 Alex Thompson. All rights reserved.
//

import Foundation

struct Constants {
    static let developmentBaseUrl = "http://staging.pippoplearning.com/"
    static let productionBaseUrl = "https://pippoplearning.com/"
    static let apiUrl = "https://pippoplearning.com/api/v3/digitalexperiences"
    static let homedir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    static let BucketName = "pippopugc"
    static let s3BaseUrl = "https://s3-eu-west-1.amazonaws.com"
    static let RailsImageUrl = "https://www.pippoplearning.com/api/v3/learnerimagecreate"
    static let TokenUrl = "https://www.pippoplearning.com/api/v3/tokens"
    static let UserCreationUrl = "https://www.pippoplearning.com/api/v3/users"
    static let LearnerImagesUrl = "https://www.pippoplearning.com/api/v3/learnerimages"
    static let SubmitStar = "https://www.pippoplearning.com/api/v3/learnervotes"
    static let PipisodesUrl = "https://www.pippoplearning.com/api/v3/pipisodes"
    static let SubscriptionsUrl = "https://www.pippoplearning.com/api/v3/apple8subscriptions"
    static let PerformancesUrl = "https://www.pippoplearning.com/api/v3/performances"
    static let PromotionVideoUrl = "https://s3-us-west-2.amazonaws.com/pipresources/pippop_marketing_inapp_video.mp4"
}
