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
            if let gif = gif, let url = gif.url {
                SDWebImageManager.shared().loadImage(with: URL.init(string: url), options: .highPriority, progress: nil, completed: { (image, _, _, _, _, _) -> Void in
                    if let image = image { // download and cache the gif
                        self.image = image
                    }
                })
            }
            if let gif = gif, let trended = gif.trended, trended == true { // check if it's necessary to add trended icon
                trendedImageView = UIImageView.init(image: UIImage.init(named: Constants.trendedIconName))
            }
        }
    }
    
    var image: UIImage? {
        didSet {
            if let image = image, imageView != nil {
                imageView.image = image
            }
        }
    }
    
    var imageView: UIImageView!
    var trendedImageView: UIImageView? {
        didSet {
            if let trendedImageView = trendedImageView {
                trendedImageView.frame = CGRect(x: Constants.cellPadding * 2, y: Constants.cellPadding * 2, width: Constants.trendedIconSize, height: Constants.trendedIconSize)
                self.addSubview(trendedImageView)
            }
        }
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? GifLayoutAttributes {
            if imageView == nil {
                imageView = UIImageView()
                imageView.backgroundColor = UIColor.init(white: 0.9, alpha: 1.0)
                self.addSubview(imageView)
            }
            // update image view size according to gif size
            imageView.frame = CGRect(x: Constants.cellPadding, y: Constants.cellPadding, width: attributes.gifWidth, height: attributes.gifHeight)
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
