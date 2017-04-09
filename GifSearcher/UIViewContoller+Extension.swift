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
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.text = "No Internet Connection"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)
        
        let centerX = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: overlay, attribute: .centerX, multiplier: 1.0, constant: 0)
        overlay.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: overlay, attribute: .centerY, multiplier: 1.0, constant: 0)
        overlay.addConstraint(centerY)
        let leftMargin = NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: overlay, attribute: .leading, multiplier: 1.0, constant: 0)
        overlay.addConstraint(leftMargin)
        let TopMargin = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: overlay, attribute: .top, multiplier: 1.0, constant: 0)
        overlay.addConstraint(TopMargin)
        
        return overlay
        
    }
    
    // MARK: AlertController
    func alertControllerWithMessage(_ message: String) -> UIAlertController {
        
        let alertController = UIAlertController.init(title: "GifSearcher", message: message, preferredStyle: .alert)
        let confirm = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(confirm)
        return alertController
        
    }
    
}
