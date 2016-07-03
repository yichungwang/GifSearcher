//
//  UIViewContoller+Extension.swift
//  GifSearch
//
//  Created by Daydreamer on 7/2/16.
//  Copyright © 2016 Daydreamer. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    // MARK: No Internet Overlay
    var noInternetOverlay: UIView {
        
        if let overlay = view.viewWithTag(Constants.noInternetOverlayTag) {
            return overlay
        }
        
        let overlay = UIView()
        overlay.tag = Constants.noInternetOverlayTag
        overlay.backgroundColor = Constants.Red
        self.view.addSubview(overlay)
        
        let label = UILabel()
        label.font = UIFont.boldSystemFontOfSize(14)
        label.textColor = UIColor.whiteColor()
        label.text = "No Internet Connection"
        label.textAlignment = .Center
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)
        
        let centerX = NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: overlay, attribute: .CenterX, multiplier: 1.0, constant: 0)
        overlay.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: overlay, attribute: .CenterY, multiplier: 1.0, constant: 0)
        overlay.addConstraint(centerY)
        let leftMargin = NSLayoutConstraint(item: label, attribute: .Leading, relatedBy: .Equal, toItem: overlay, attribute: .Leading, multiplier: 1.0, constant: 0)
        overlay.addConstraint(leftMargin)
        let TopMargin = NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: overlay, attribute: .Top, multiplier: 1.0, constant: 0)
        overlay.addConstraint(TopMargin)
        
        return overlay
        
    }
    
    // MARK: AlertController
    func alertControllerWithMessage(message: String) -> UIAlertController {
        
        let alertController = UIAlertController.init(title: "GifSearcher", message: message, preferredStyle: .Alert)
        let confirm = UIAlertAction.init(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(confirm)
        return alertController
        
    }
    
}