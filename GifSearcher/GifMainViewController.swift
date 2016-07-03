//
//  ViewController.swift
//  GifSearcher
//
//  Created by Daydreamer on 7/2/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import UIKit
import Alamofire

class GifMainViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UISearchBarDelegate, GifCollectionViewLayoutDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var gifFeed = GifFeedModule(type: .Trending)
    private var searchBar: UISearchBar!
    private var refreshControl: UIRefreshControl!
    private var loaded: Bool = false
    private var reachability: NetworkReachabilityManager!
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // search bar
        searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.barTintColor = UIColor.init(white: 0.95, alpha: 1.0)
        searchBar.tintColor = UIColor.darkGrayColor()
        searchBar.layer.borderColor = UIColor.whiteColor().CGColor
        searchBar.layer.borderWidth = 0.5
        self.view.addSubview(searchBar)
        
        // collection view
        if let layout = collectionView.collectionViewLayout as? GifCollectionViewLayout {
            layout.delegate = self
        }
        collectionView.backgroundColor = UIColor.whiteColor()
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(GifMainViewController.refreshFeed), forControlEvents: .ValueChanged)
        collectionView.addSubview(refreshControl)
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl.endRefreshing()
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.willRotateToInterfaceOrientation(UIApplication.sharedApplication().statusBarOrientation, duration: 0)
        collectionView.contentInset = UIEdgeInsetsMake(44 + Constants.cellPadding, Constants.cellPadding, Constants.cellPadding, Constants.cellPadding)
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Subview & Orientation
    
    func updateNoInternetOverlay() {
        self.noInternetOverlay.backgroundColor = Constants.Red
        if UIApplication.sharedApplication().statusBarOrientation == .Portrait || UIApplication.sharedApplication().statusBarOrientation == .PortraitUpsideDown {
            self.noInternetOverlay.frame = CGRectMake(0, 64, ((Constants.screenHeight < Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), 40)
        } else {
            self.noInternetOverlay.frame = CGRectMake(0, 44 + ((UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 20 : 0), ((Constants.screenHeight > Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), 40)
        }
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if toInterfaceOrientation == .Portrait || UIApplication.sharedApplication().statusBarOrientation == .PortraitUpsideDown {
            searchBar.frame = CGRectMake(0, 20, ((Constants.screenHeight < Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), 44)
        } else {
            searchBar.frame = CGRectMake(0, (UIDevice.currentDevice().userInterfaceIdiom == .Pad) ? 20 : 0, ((Constants.screenHeight > Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), 44)
        }
        if !reachability.isReachable {
            updateNoInternetOverlay()
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: UISearchBar Delegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if !reachability.isReachable {
            let alert = alertControllerWithMessage("Please make sure you are connected to the internet and try again.")
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        if let searchTerms = searchBar.text where searchTerms != "" {
            let result = GifSearchResultViewController()
            result.searchTerms = searchTerms
            self.navigationController?.pushViewController(result, animated: true)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        view.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    // MARK: Feeds
    
    func refreshFeed() {
        gifFeed.clearFeed()
        collectionView.reloadData()
        refreshControl.endRefreshing()
        loadMoreFeed()
    }
    
    func loadFeed() {
        gifFeed.requestFeed(20, offset: 0, rating: nil, terms: nil, comletionHandler: { (succeed, _, error) -> Void in
            if succeed {
                self.loaded = true
                self.collectionView.reloadData()
                self.loadMoreFeed()
            } else if let _ = error {
                // let alert = self.alertControllerWithMessage(error)
                //self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
    func loadMoreFeed() {
        gifFeed.requestFeed(20, offset: gifFeed.currentOffset, rating: nil, terms: nil, comletionHandler: { (succeed, total, error) -> Void in
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
            } else if let _ = error {
                //let alert = self.alertControllerWithMessage(error)
                //self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
    // MARK: UIScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if CGRectIntersectsRect(collectionView.bounds, CGRectMake(0, collectionView.contentSize.height - Constants.screenHeight / 2, CGRectGetWidth(collectionView.frame), Constants.screenHeight / 2)) && collectionView.contentSize.height > 0 {
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
    
    // MARK: UICollectionView Delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        searchBar.text = ""
        view.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    // MARK: GifCollectionViewLayout Delegate
    
    func collectionView(collectionView: UICollectionView, heightForGifAtIndexPath indexPath: NSIndexPath, fixedWidth: CGFloat) -> CGFloat {
        let gif = gifFeed.gifsArray[indexPath.item]
        let gifHeight = gif.height * fixedWidth / gif.width
        return gifHeight
    }
    
}

