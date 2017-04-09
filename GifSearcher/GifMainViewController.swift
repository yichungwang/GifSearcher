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
    
    fileprivate var gifFeed = GifFeedModel(type: .trending)
    fileprivate var searchBar: UISearchBar!
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var loaded: Bool = false
    fileprivate var reachability: NetworkReachabilityManager!
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // search bar
        searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.barTintColor = UIColor.init(white: 0.95, alpha: 1.0)
        searchBar.tintColor = UIColor.darkGray
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBar.layer.borderWidth = 0.5
        self.view.addSubview(searchBar)
        
        // collection view
        if let layout = collectionView.collectionViewLayout as? GifCollectionViewLayout {
            layout.delegate = self
        }
        collectionView.backgroundColor = UIColor.white
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(GifMainViewController.refreshFeed), for: .valueChanged)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl.endRefreshing()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.willRotate(to: UIApplication.shared.statusBarOrientation, duration: 0)
        collectionView.contentInset = UIEdgeInsetsMake(44 + Constants.cellPadding, Constants.cellPadding, Constants.cellPadding, Constants.cellPadding)
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(44, 0, 0, 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Subview & Orientation
    
    func updateNoInternetOverlay() {
        self.noInternetOverlay.backgroundColor = Constants.Red
        if UIApplication.shared.statusBarOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown {
            self.noInternetOverlay.frame = CGRect(x: 0, y: 64, width: ((Constants.screenHeight < Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), height: 40)
        } else {
            self.noInternetOverlay.frame = CGRect(x: 0, y: 44 + ((UIDevice.current.userInterfaceIdiom == .pad) ? 20 : 0), width: ((Constants.screenHeight > Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), height: 40)
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown {
            searchBar.frame = CGRect(x: 0, y: 20, width: ((Constants.screenHeight < Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), height: 44)
        } else {
            searchBar.frame = CGRect(x: 0, y: (UIDevice.current.userInterfaceIdiom == .pad) ? 20 : 0, width: ((Constants.screenHeight > Constants.screenWidth) ? Constants.screenHeight : Constants.screenWidth), height: 44)
        }
        if !reachability.isReachable {
            updateNoInternetOverlay()
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: UISearchBar Delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !reachability.isReachable {
            let alert = alertControllerWithMessage("Please make sure you are connected to the internet and try again.")
            self.present(alert, animated: true, completion: nil)
            return
        }
        if let searchTerms = searchBar.text, searchTerms != "" {
            let result = GifSearchResultViewController()
            result.searchTerms = searchTerms
            self.navigationController?.pushViewController(result, animated: true)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        view.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
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
            } else if let error = error {
                let alert = self.alertControllerWithMessage(error)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func loadMoreFeed() {
        gifFeed.requestFeed(20, offset: gifFeed.currentOffset, rating: nil, terms: nil, comletionHandler: { (succeed, total, error) -> Void in
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
        if collectionView.bounds.intersects(CGRect(x: 0, y: collectionView.contentSize.height - Constants.screenHeight / 2, width: collectionView.frame.width, height: Constants.screenHeight / 2)) && collectionView.contentSize.height > 0 && reachability.isReachable {
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
    
    // MARK: UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.text = ""
        view.endEditing(true)
        searchBar.showsCancelButton = false
    }
    
    // MARK: GifCollectionViewLayout Delegate
    
    func collectionView(_ collectionView: UICollectionView, heightForGifAtIndexPath indexPath: IndexPath, fixedWidth: CGFloat) -> CGFloat {
        let gif = gifFeed.gifsArray[indexPath.item]
        let gifHeight = gif.height * fixedWidth / gif.width
        return gifHeight
    }
    
}

