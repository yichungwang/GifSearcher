//
//  GifFeedModel.swift
//  GifSearch
//
//  Created by Daydreamer on 6/29/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit

class GifFeedModel {
    
    fileprivate var maxgifs = Constants.searchResultsLimit
    var currentOffset = 0
    fileprivate var previousOffset = -1
    var gifsArray = [GifModel]()
    fileprivate var requesting: Bool = false
    fileprivate var type: feedType = .trending
    
    enum feedType {
        case trending, search
    }
    
    init(type: feedType) {
        self.type = type
    }
    
    func clearFeed() {
        maxgifs = Constants.searchResultsLimit
        gifsArray = []
        requesting = false
        currentOffset = 0
        previousOffset = -1
    }
    
    func requestFeed(_ limit: Int, offset: Int, rating: String?, terms: String?, comletionHandler:@escaping (_ succeed: Bool, _ total: Int?, _ error: String?) -> Void) {
        if requesting {
            comletionHandler(false, nil, nil)
            return
        }
        if previousOffset == currentOffset || currentOffset >= maxgifs {
            comletionHandler(false, nil, nil)
            return
        }
        requesting = true
        
        switch type {
            
        case .trending:
            
            GifWebManager.sharedInstance.queryTrendingGifs(limit, offset: offset, completionHandler: {(gifs, error) -> Void in
                self.requesting = false
                if let gifs = gifs {
                    var newgifs = gifs
                    // check if there are duplicates
                    for newgif in newgifs {
                        if self.gifsArray.contains(where: { $0.id == newgif.id }) {
                            if let i = newgifs.index(where: { $0.id == newgif.id }) {
                                newgifs.remove(at: i)
                            }
                        }
                    }
                    self.previousOffset = self.currentOffset
                    self.currentOffset = self.currentOffset + newgifs.count
                    self.gifsArray.append(contentsOf: newgifs)
                    comletionHandler(true, newgifs.count, nil)
                } else {
                    comletionHandler(false, nil, error)
                }
            })
            
        case .search:
            
            GifWebManager.sharedInstance.querySearchGifs(terms!, limit: limit, offset: offset, rating: rating, completionHandler: {(gifs, total, error) -> Void in
                self.requesting = false
                if let total = total, total < self.maxgifs {
                    self.maxgifs = total
                }
                if let gifs = gifs {
                    // check if there are duplicates
                    var newgifs = gifs
                    for newgif in newgifs {
                        if self.gifsArray.contains(where: { $0.id == newgif.id }) {
                            if let i = newgifs.index(where: { $0.id == newgif.id }) {
                                newgifs.remove(at: i)
                            }
                        }
                        if newgif.width == 0 || newgif.height == 0 {
                            if let i = newgifs.index(where: { $0.id == newgif.id }) {
                                newgifs.remove(at: i)
                            }
                        }
                    }
                    self.previousOffset = self.currentOffset
                    self.currentOffset = self.currentOffset + newgifs.count
                    self.gifsArray.append(contentsOf: newgifs)
                    comletionHandler(true, newgifs.count, nil)
                } else {
                    comletionHandler(false, nil, error)
                }
            })
            
        }
        
    }
    
}
