//
//  GifSearchResultViewController.swift
//  GifSearch
//
//  Created by Daydreamer on 7/1/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class GifSearchResultViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, GifCollectionViewLayoutDelegate {
    
    var searchTerms: String!
    private var gifFeed = GifFeedModule(type: .Search)
    private var collectionView: UICollectionView!
    private let rating = Constants.preferredSearchRating
    private var loaded: Bool = false
    private var reachability: NetworkReachabilityManager!
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if searchTerms == nil {
            searchTerms = ""
        }
        if searchTerms.characters.count > 15 {
            self.title = searchTerms.substringWithRange(Range<String.Index>(searchTerms.startIndex.advancedBy(0)..<searchTerms.startIndex.advancedBy(14))) + "..."
        } else {
            self.title = searchTerms
        }
        self.view.backgroundColor = UIColor.whiteColor()
        
        // collection view
        let layout = GifCollectionViewLayout()
        layout.delegate = self
        
        collectionView = UICollectionView.init(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.contentInset = UIEdgeInsetsMake(Constants.cellPadding, Constants.cellPadding, Constants.cellPadding, Constants.cellPadding)
        collectionView.registerClass(GifCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.view.addSubview(collectionView)
        
        // reachability
        reachability = NetworkReachabilityManager()
        reachability.startListening()
        reachability.listener = { status -> Void in
            switch status {
            case .NotReachable:
                self.updateNoInternetOverlay()
            case .Reachable(.EthernetOrWiFi), .Reachable(.WWAN):
                (self.loaded == false) ? self.loadFeed() : self.loadMoreFeed()
                UIView.animateWithDuration(0.4, animations: {
                    self.noInternetOverlay.backgroundColor = Constants.Green
                    }, completion: { done -> Void in
                        UIView.animateWithDuration(0.3, animations: {
                            var rect = self.noInternetOverlay.frame
                            rect.size.height = 0
                            self.noInternetOverlay.frame = rect
                        })
                })
            default: break
            }
        }
        
    }
    
    // MARK: Subview & Orientation
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.willRotateToInterfaceOrientation(UIApplication.sharedApplication().statusBarOrientation, duration: 0)
    }
    
    func updateNoInternetOverlay() {
        self.noInternetOverlay.backgroundColor = Constants.Red
        if UIApplication.sharedApplication().statusBarOrientation == .Portrait || UIApplication.sharedApplication().statusBarOrientation == .PortraitUpsideDown {
            self.noInternetOverlay.frame = CGRectMake(0, 64, ((Constants.screenHeight < Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), 40)
        } else {
            self.noInternetOverlay.frame = CGRectMake(0, 32 + ((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 32 : 0), ((Constants.screenHeight > Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), 40)
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if !reachability.isReachable {
            updateNoInternetOverlay()
        }
        var rect = collectionView.frame
        if toInterfaceOrientation == .Portrait || UIApplication.sharedApplication().statusBarOrientation == .PortraitUpsideDown {
            if collectionView.frame.height < collectionView.frame.width {
                rect.size.width = collectionView.frame.height
                rect.size.height = collectionView.frame.width
            }
        } else {
            if collectionView.frame.height > collectionView.frame.width {
                rect.size.width = collectionView.frame.height
                rect.size.height = collectionView.frame.width
            }
        }
        collectionView.frame = rect
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Feeds
    
    func loadFeed() {
        gifFeed.requestFeed(20, offset: 0, rating: rating, terms: searchTerms, comletionHandler: { (succeed, _, error) -> Void in
            if succeed {
                self.loaded = true
                self.collectionView.reloadData()
                self.loadMoreFeed()
            } else if let error = error {
                let alert = self.alertControllerWithMessage(error)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
    func loadMoreFeed() {
        gifFeed.requestFeed(20, offset: gifFeed.currentOffset, rating: rating, terms: searchTerms, comletionHandler: { (succeed, total, error) -> Void in
            if succeed, let total = total {
                self.collectionView.performBatchUpdates({
                    
                    var indexPaths = [NSIndexPath]()
                    for i in (self.gifFeed.currentOffset - total)..<self.gifFeed.currentOffset {
                        let indexPath = NSIndexPath.init(forItem: i, inSection: 0)
                        indexPaths.append(indexPath)
                    }
                    self.collectionView.insertItemsAtIndexPaths(indexPaths)
                    
                    }, completion: { done -> Void in
                        
                })
            } else if let error = error {
                let alert = self.alertControllerWithMessage(error)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: UIScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if CGRectIntersectsRect(collectionView.bounds, CGRectMake(0, collectionView.contentSize.height - Constants.screenHeight / 2, CGRectGetWidth(collectionView.frame), Constants.screenHeight / 2)) && collectionView.contentSize.height > 0 && reachability.isReachable { // to load more feed or not
            loadMoreFeed()
        }
    }
    
    // MARK: UICollectionView Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifFeed.gifsArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! GifCollectionViewCell
        cell.gif = gifFeed.gifsArray[indexPath.item]
        return cell
    }
    
    // MARK: GifCollectionViewLayout Delegate
    
    func collectionView(collectionView: UICollectionView, heightForGifAtIndexPath indexPath: NSIndexPath, fixedWidth: CGFloat) -> CGFloat {
        let gif = gifFeed.gifsArray[indexPath.item]
        let gifHeight = gif.height * fixedWidth / gif.width
        return gifHeight
    }
    
}