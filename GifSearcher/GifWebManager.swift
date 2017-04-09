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
    
    fileprivate let baseURL = "https://api.giphy.com/"
    fileprivate let giphyAPIKey = "dc6zaTOxFJmzC"
    fileprivate var alamofireManager: Alamofire.SessionManager!
    
    fileprivate init() {
        let configuration = URLSessionConfiguration.default
        alamofireManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    func queryTrendingGifs(_ limit: Int, offset: Int, completionHandler:@escaping (_ gifs: [GifModel]?, _ error: String?) -> Void) {
        
        alamofireManager.request(baseURL + "v1/gifs/trending", method: .get, parameters: ["api_key" : giphyAPIKey, "limit" : "\(limit)", "offset" : "\(offset)"], encoding: URLEncoding.default).responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let result):
                let resultJSON = JSON.init(result)
                if let gifdata = resultJSON["data"].array {
                    var gifs = [GifModel]()
                    for gifJSON in gifdata {
                        let gif = GifModel.init(data: gifJSON)
                        gifs.append(gif)
                    }
                    completionHandler(gifs, nil)
                } else {
                    completionHandler(nil, "Something is wrong")
                }
            case .failure(let error):
                completionHandler(nil, error.localizedDescription)
            }
        
        })
    }
    
    func querySearchGifs(_ q: String, limit: Int, offset: Int, rating: String?, completionHandler:@escaping (_ gifs: [GifModel]?, _ total: Int?, _ error: String?) -> Void) {
        var ratingStr: String = ""
        if let rating = rating {
            ratingStr = rating
        }
        
        alamofireManager.request(baseURL + "v1/gifs/search", method: .get, parameters: ["api_key" : giphyAPIKey, "limit" : "\(limit)", "offset" : "\(offset)", "rating": ratingStr, "q" : q], encoding: URLEncoding.default, headers: nil).responseJSON(completionHandler: { response in
            
            switch response.result {
            case .success(let result):
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
                    completionHandler(gifs, total, nil)
                } else {
                    completionHandler(nil, nil, "Something is wrong")
                }
            case .failure(let error):
                completionHandler(nil, nil, error.localizedDescription)
            }
            
        })
    }

}
