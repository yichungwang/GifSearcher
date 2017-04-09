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
    func collectionView(_ collectionView:UICollectionView, heightForGifAtIndexPath indexPath:IndexPath, fixedWidth:CGFloat) -> CGFloat
}

class GifLayoutAttributes: UICollectionViewLayoutAttributes {
    // custom attributes
    var gifHeight: CGFloat = 0.0
    var gifWidth: CGFloat = 0.0
    
    override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! GifLayoutAttributes
        copy.gifHeight = gifHeight
        copy.gifWidth = gifWidth
        return copy
    }
    
    override func isEqual(_ object: Any?) -> Bool {
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
    fileprivate var attributes = [GifLayoutAttributes]()
    fileprivate var contentHeight: CGFloat = 0.0
    fileprivate var contentWidth: CGFloat = 0.0
    
    override class var layoutAttributesClass : AnyClass {
        return GifLayoutAttributes.self
    }
    
    override func prepare() {
        
        var column = 0
        contentHeight = 0
        contentWidth = collectionView!.frame.width - collectionView!.contentInset.left - collectionView!.contentInset.right
        let itemWidth: CGFloat = floor(contentWidth / 2.0)
        let xOffset: [CGFloat] = [0, itemWidth]
        var yOffset: [CGFloat] = [0, 0] // keep track of y offset of each column
        attributes = []
        
        for item in 0..<collectionView!.numberOfItems(inSection: 0) {
            
            let indexPath = IndexPath.init(item: item, section: 0)
            let gifWidth = itemWidth - 2 * Constants.cellPadding
            let gifHeight = delegate.collectionView(collectionView!, heightForGifAtIndexPath: indexPath, fixedWidth: gifWidth)
            let itemHeight = gifHeight + 2 * Constants.cellPadding
            
            if yOffset[0] > yOffset[1] { // determine which column to insert
                column = 1
            } else {
                column = 0
            }
            
            let itemFrame = CGRect(x: xOffset[column], y: yOffset[column], width: itemWidth, height: itemHeight)
            let attribute = GifLayoutAttributes.init(forCellWith: indexPath)
            attribute.frame = itemFrame
            attribute.gifHeight = gifHeight
            attribute.gifWidth = gifWidth
            attributes.append(attribute)
            
            // update content height and y offset
            contentHeight = max(contentHeight, itemFrame.maxY)
            yOffset[column] = yOffset[column] + itemHeight
            
        }
        
    }
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attribute in attributes {
            if attribute.frame.intersects(rect) {
                layoutAttributes.append(attribute)
            }
        }
        return layoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributes[indexPath.item]
    }
    
}
