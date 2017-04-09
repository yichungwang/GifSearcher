//
//  Constants.swift
//  GifSearch
//
//  Created by Daydreamer on 6/29/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

struct Constants {
    
    static let cellPadding: CGFloat = 5.0
    static let screenHeight: CGFloat = UIScreen.main.bounds.height
    static let screenWidth: CGFloat = UIScreen.main.bounds.width
    
    static let Red = UIColor.init(red: 0.918, green: 0.263, blue: 0.208, alpha: 1.0)
    static let Green = UIColor.init(red: 0.204, green: 0.659, blue: 0.325, alpha: 1.0)
    
    static let noInternetOverlayTag: Int = 2000789
    static let dateTimeFormat = "yyyy-MM-dd HH:mm:ss"
    static let nonTrendedDateTimeFormat = "0000-00-00 00:00:00"
    
    // adjust here
    static let searchResultsLimit: Int = 400
    static let preferredSearchRating = "pg"
    static let preferredImageType = "fixed_width_downsampled"
    static let trendedIconName = "trendedIcon"
    static let trendedIconSize: CGFloat = 15
    
}
