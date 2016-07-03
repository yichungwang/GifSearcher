//
//  GifCollectionViewLayout.swift
//  GifSearch
//
//  Created by Daydreamer on 6/29/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit

protocol GifCollectionViewLayoutDelegate {
    // use to get the dynamic height of each gif
    func collectionView(collectionView:UICollectionView, heightForGifAtIndexPath indexPath:NSIndexPath, fixedWidth:CGFloat) -> CGFloat
}

class GifLayoutAttributes: UICollectionViewLayoutAttributes {
    // custom attributes
    var gifHeight: CGFloat = 0.0
    var gifWidth: CGFloat = 0.0
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! GifLayoutAttributes
        copy.gifHeight = gifHeight
        copy.gifWidth = gifWidth
        return copy
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let attributes = object as? GifLayoutAttributes {
            if(attributes.gifHeight == gifHeight && attributes.gifWidth == gifWidth) {
                return super.isEqual(object)
            }
        }
        return false
    }
    
}

class GifCollectionViewLayout: UICollectionViewLayout {
    
    var delegate: GifCollectionViewLayoutDelegate!
    private var attributes = [GifLayoutAttributes]()
    private var contentHeight: CGFloat = 0.0
    private var contentWidth: CGFloat = 0.0
    
    override class func layoutAttributesClass() -> AnyClass {
        return GifLayoutAttributes.self
    }
    
    override func prepareLayout() {
        
        var column = 0
        contentHeight = 0
        contentWidth = CGRectGetWidth(collectionView!.frame) - collectionView!.contentInset.left - collectionView!.contentInset.right
        let itemWidth: CGFloat = floor(contentWidth / 2.0)
        let xOffset: [CGFloat] = [0, itemWidth]
        var yOffset: [CGFloat] = [0, 0] // keep track of y offset of each column
        attributes = []
        
        for item in 0..<collectionView!.numberOfItemsInSection(0) {
            
            let indexPath = NSIndexPath.init(forItem: item, inSection: 0)
            let gifWidth = itemWidth - 2 * Constants.cellPadding
            let gifHeight = delegate.collectionView(collectionView!, heightForGifAtIndexPath: indexPath, fixedWidth: gifWidth)
            let itemHeight = gifHeight + 2 * Constants.cellPadding
            
            if yOffset[0] > yOffset[1] { // determine which column to insert
                column = 1
            } else {
                column = 0
            }
            
            let itemFrame = CGRectMake(xOffset[column], yOffset[column], itemWidth, itemHeight)
            let attribute = GifLayoutAttributes.init(forCellWithIndexPath: indexPath)
            attribute.frame = itemFrame
            attribute.gifHeight = gifHeight
            attribute.gifWidth = gifWidth
            attributes.append(attribute)
            
            // update content height and y offset
            contentHeight = max(contentHeight, CGRectGetMaxY(itemFrame))
            yOffset[column] = yOffset[column] + itemHeight
            
        }
        
    }
    
    override func collectionViewContentSize() -> CGSize {
        return CGSizeMake(contentWidth, contentHeight)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attribute in attributes {
            if CGRectIntersectsRect(attribute.frame, rect) {
                layoutAttributes.append(attribute)
            }
        }
        return layoutAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes[indexPath.item]
    }
    
}