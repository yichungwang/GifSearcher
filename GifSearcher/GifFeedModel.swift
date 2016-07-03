//
//  GifFeedModule.swift
//  GifSearch
//
//  Created by Daydreamer on 6/29/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit

class GifFeedModule {
    
    private var maxgifs = Constants.searchResultsLimit
    var currentOffset = 0
    private var previousOffset = -1
    var gifsArray = [GifModel]()
    private var requesting: Bool = false
    private var type: feedType = .Trending
    
    enum feedType {
        case Trending, Search
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
    
    func requestFeed(limit: Int, offset: Int, rating: String?, terms: String?, comletionHandler:(succeed: Bool, total: Int?, error: String?) -> Void) {
        if requesting {
            comletionHandler(succeed: false, total: nil, error: nil)
            return
        }
        if previousOffset == currentOffset || currentOffset >= maxgifs {
            comletionHandler(succeed: false, total: nil, error: nil)
            return
        }
        requesting = true
        
        switch type {
            
        case .Trending:
            
            GifWebManager.sharedInstance.queryTrendingGifs(limit, offset: offset, completionHandler: {(gifs, error) -> Void in
                self.requesting = false
                if let gifs = gifs {
                    var newgifs = gifs
                    // check if there are duplicates
                    for newgif in newgifs {
                        if self.gifsArray.contains({ $0.id == newgif.id }) {
                            if let i = newgifs.indexOf({ $0.id == newgif.id }) {
                                newgifs.removeAtIndex(i)
                            }
                        }
                    }
                    self.previousOffset = self.currentOffset
                    self.currentOffset = self.currentOffset + newgifs.count
                    self.gifsArray.appendContentsOf(newgifs)
                    comletionHandler(succeed: true, total: newgifs.count, error: nil)
                } else {
                    comletionHandler(succeed: false, total: nil, error: error)
                }
            })
            
        case .Search:
            
            GifWebManager.sharedInstance.querySearchGifs(terms!, limit: limit, offset: offset, rating: rating, completionHandler: {(gifs, total, error) -> Void in
                self.requesting = false
                if let total = total where total < self.maxgifs {
                    self.maxgifs = total
                }
                if let gifs = gifs {
                    // check if there are duplicates
                    var newgifs = gifs
                    for newgif in newgifs {
                        if self.gifsArray.contains({ $0.id == newgif.id }) {
                            if let i = newgifs.indexOf({ $0.id == newgif.id }) {
                                newgifs.removeAtIndex(i)
                            }
                        }
                    }
                    self.previousOffset = self.currentOffset
                    self.currentOffset = self.currentOffset + newgifs.count
                    self.gifsArray.appendContentsOf(newgifs)
                    comletionHandler(succeed: true, total: newgifs.count, error: nil)
                } else {
                    comletionHandler(succeed: false, total: nil, error: error)
                }
            })
            
        }
        
    }
    
}