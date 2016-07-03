//
//  GifCollectionViewCell.swift
//  GifSearch
//
//  Created by Daydreamer on 6/28/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class GifCollectionViewCell: UICollectionViewCell {
    
    var gif: GifModel? {
        didSet {
            if let gif = gif, url = gif.url {
                SDWebImageManager.sharedManager().downloadImageWithURL(NSURL.init(string: url), options: .HighPriority, progress: {(_, _) -> Void in
                    }, completed: {(image, _, _, _, _) -> Void in
                        if let image = image { // download and cache the gif
                            self.image = image
                        }
                })
            }
            if let gif = gif, trended = gif.trended where trended == true { // check if it's necessary to add trended icon
                trendedImageView = UIImageView.init(image: UIImage.init(named: Constants.trendedIconName))
            }
        }
    }
    
    var image: UIImage? {
        didSet {
            if let image = image where imageView != nil {
                imageView.image = image
            }
        }
    }
    
    var imageView: UIImageView!
    var trendedImageView: UIImageView? {
        didSet {
            if let trendedImageView = trendedImageView {
                trendedImageView.frame = CGRectMake(Constants.cellPadding * 2, Constants.cellPadding * 2, Constants.trendedIconSize, Constants.trendedIconSize)
                self.addSubview(trendedImageView)
            }
        }
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        if let attributes = layoutAttributes as? GifLayoutAttributes {
            if imageView == nil {
                imageView = UIImageView()
                imageView.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
                self.addSubview(imageView)
            }
            // update image view size according to gif size
            imageView.frame = CGRectMake(Constants.cellPadding, Constants.cellPadding, attributes.gifWidth, attributes.gifHeight)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if imageView != nil {
            imageView.image = nil
        }
        if trendedImageView != nil {
            trendedImageView?.removeFromSuperview()
            trendedImageView = nil
        }
    }
    
}