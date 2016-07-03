//
//  GifWebManager.swift
//  GifSearch
//
//  Created by Daydreamer on 6/29/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class GifWebManager {
    
    static let sharedInstance = GifWebManager()
    
    private let baseURL = "https://api.giphy.com/"
    private let giphyAPIKey = "dc6zaTOxFJmzC"
    private var alamofireManager: Alamofire.Manager!
    
    private init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        alamofireManager = Alamofire.Manager(configuration: configuration)
    }
    
    func queryTrendingGifs(limit: Int, offset: Int, completionHandler:(gifs: [GifModel]?, error: String?) -> Void) {
        alamofireManager.request(.GET, baseURL + "v1/gifs/trending", parameters: ["api_key" : giphyAPIKey, "limit" : "\(limit)", "offset" : "\(offset)"], encoding: .URL, headers: nil).responseJSON(completionHandler: { response in
            
            switch response.result {
            case .Success(let result):
                let resultJSON = JSON.init(result)
                if let gifdata = resultJSON["data"].array {
                    var gifs = [GifModel]()
                    for gifJSON in gifdata {
                        let gif = GifModel.init(data: gifJSON)
                        gifs.append(gif)
                    }
                    completionHandler(gifs: gifs, error: nil)
                } else {
                    completionHandler(gifs: nil, error: "Something is wrong")
                }
            case .Failure(let error):
                completionHandler(gifs: nil, error: error.localizedDescription)
            }
        
        })
    }
    
    func querySearchGifs(q: String, limit: Int, offset: Int, rating: String?, completionHandler:(gifs: [GifModel]?, total: Int?, error: String?) -> Void) {
        var ratingStr: String = ""
        if let rating = rating {
            ratingStr = rating
        }
        alamofireManager.request(.GET, baseURL + "v1/gifs/search", parameters: ["api_key" : giphyAPIKey, "limit" : "\(limit)", "offset" : "\(offset)", "rating": ratingStr, "q" : q], encoding: .URL, headers: nil).responseJSON(completionHandler: { response in
            
            switch response.result {
            case .Success(let result):
                let resultJSON = JSON.init(result)
                var total: Int?
                if let pagination = resultJSON["pagination"].dictionary {
                    if let totalcount = pagination["total_count"]?.int {
                       total = totalcount
                    }
                }
                if let gifdata = resultJSON["data"].array {
                    var gifs = [GifModel]()
                    for gifJSON in gifdata {
                        let gif = GifModel.init(data: gifJSON)
                        gifs.append(gif)
                    }
                    completionHandler(gifs: gifs, total: total, error: nil)
                } else {
                    completionHandler(gifs: nil, total: nil, error: "Something is wrong")
                }
            case .Failure(let error):
                completionHandler(gifs: nil, total: nil, error: error.localizedDescription)
            }
            
        })
    }

}