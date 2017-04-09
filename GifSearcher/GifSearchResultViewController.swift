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
    fileprivate var gifFeed = GifFeedModel(type: .search)
    fileprivate var collectionView: UICollectionView!
    fileprivate let rating = Constants.preferredSearchRating
    fileprivate var loaded: Bool = false
    fileprivate var reachability: NetworkReachabilityManager!
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if searchTerms == nil {
            searchTerms = ""
        }
        if searchTerms.characters.count > 15 {
            self.title = searchTerms.substring(with: Range<String.Index>(searchTerms.index(searchTerms.startIndex, offsetBy: 0)..<searchTerms.index(searchTerms.startIndex, offsetBy: 14))) + "..."
        } else {
            self.title = searchTerms
        }
        self.view.backgroundColor = UIColor.white
        
        // collection view
        let layout = GifCollectionViewLayout()
        layout.delegate = self
        
        collectionView = UICollectionView.init(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        collectionView.contentInset = UIEdgeInsetsMake(Constants.cellPadding, Constants.cellPadding, Constants.cellPadding, Constants.cellPadding)
        collectionView.register(GifCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.view.addSubview(collectionView)
        
        // reachability
        reachability = NetworkReachabilityManager()
        reachability.startListening()
        reachability.listener = { status -> Void in
            switch status {
            case .notReachable:
                self.updateNoInternetOverlay()
            case .reachable(.ethernetOrWiFi), .reachable(.wwan):
                (self.loaded == false) ? self.loadFeed() : self.loadMoreFeed()
                UIView.animate(withDuration: 0.4, animations: {
                    self.noInternetOverlay.backgroundColor = Constants.Green
                    }, completion: { done -> Void in
                        UIView.animate(withDuration: 0.3, animations: {
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
        self.willRotate(to: UIApplication.shared.statusBarOrientation, duration: 0)
    }
    
    func updateNoInternetOverlay() {
        self.noInternetOverlay.backgroundColor = Constants.Red
        if UIApplication.shared.statusBarOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown {
            self.noInternetOverlay.frame = CGRect(x: 0, y: 64, width: ((Constants.screenHeight < Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), height: 40)
        } else {
            self.noInternetOverlay.frame = CGRect(x: 0, y: 32 + ((UIDevice.current.userInterfaceIdiom == .pad) ? 32 : 0), width: ((Constants.screenHeight > Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), height: 40)
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if !reachability.isReachable {
            updateNoInternetOverlay()
        }
        var rect = collectionView.frame
        if toInterfaceOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown {
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
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func loadMoreFeed() {
        gifFeed.requestFeed(20, offset: gifFeed.currentOffset, rating: rating, terms: searchTerms, comletionHandler: { (succeed, total, error) -> Void in
            if succeed, let total = total {
                self.collectionView.performBatchUpdates({
                    
                    var indexPaths = [IndexPath]()
                    for i in (self.gifFeed.currentOffset - total)..<self.gifFeed.currentOffset {
                        let indexPath = IndexPath.init(item: i, section: 0)
                        indexPaths.append(indexPath)
                    }
                    self.collectionView.insertItems(at: indexPaths)
                    
                    }, completion: { done -> Void in
                        
                })
            } else if let error = error {
                let alert = self.alertControllerWithMessage(error)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: UIScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if collectionView.bounds.intersects(CGRect(x: 0, y: collectionView.contentSize.height - Constants.screenHeight / 2, width: collectionView.frame.width, height: Constants.screenHeight / 2)) && collectionView.contentSize.height > 0 && reachability.isReachable { // to load more feed or not
            loadMoreFeed()
        }
    }
    
    // MARK: UICollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifFeed.gifsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GifCollectionViewCell
        cell.gif = gifFeed.gifsArray[indexPath.item]
        return cell
    }
    
    // MARK: GifCollectionViewLayout Delegate
    
    func collectionView(_ collectionView: UICollectionView, heightForGifAtIndexPath indexPath: IndexPath, fixedWidth: CGFloat) -> CGFloat {
        let gif = gifFeed.gifsArray[indexPath.item]
        let gifHeight = gif.height * fixedWidth / gif.width
        return gifHeight
    }
    
}
