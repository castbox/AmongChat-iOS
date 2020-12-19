//
//  UIAlertControllerExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 19/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension UIAlertController {

    //Set background color of UIAlertController
    func setBackgroundColor(color: UIColor) {
        if let bgView = self.view.subviews.first, let groupView = bgView.subviews.first, let contentView = groupView.subviews.first {
            contentView.backgroundColor = color
        }
    }

    //Set title font and title color
    func setTitlet(font: UIFont?, color: UIColor?) {
        guard let title = self.title else { return }
        var attribates: [NSAttributedString.Key: Any] = [:]
        if let titleFont = font {
            attribates[NSAttributedString.Key.font] = titleFont
        }

        if let titleColor = color {
            attribates[NSAttributedString.Key.foregroundColor] = titleColor
        }
        let attributeString = NSMutableAttributedString(string: title, attributes: attribates)//1
        self.setValue(attributeString, forKey: "attributedTitle")//4
    }

    //Set message font and message color
    func setMessage(font: UIFont?, color: UIColor?) {
        guard let message = self.message else { return }
        var attribates: [NSAttributedString.Key: Any] = [:]
        if let titleFont = font {
            attribates[NSAttributedString.Key.font] = titleFont
        }

        if let titleColor = color {
            attribates[NSAttributedString.Key.foregroundColor] = titleColor
        }

        let attributeString = NSMutableAttributedString(string: message, attributes: attribates)
        self.setValue(attributeString, forKey: "attributedMessage")
    }

    //Set tint color of UIAlertController
    func setTint(color: UIColor) {
        self.view.tintColor = color
    }
}

extension UIAlertAction {
    var titleTextColor: UIColor? {
        get { return self.value(forKey: "titleTextColor") as? UIColor }
        set { self.setValue(newValue, forKey: "titleTextColor") }
    }
}

extension UIAlertAction {

    //Set title font and title color
//    func setTitlet(font: UIFont?, color: UIColor?) {
//        guard let title = self.title else { return }
//        let attributeString = NSMutableAttributedString(string: title)//1
//        if let titleFont = font {
//            attributeString.addAttributes([NSAttributedString.Key.font : titleFont],//2
//                                          range: NSMakeRange(0, title.utf8.count))
//        }
//
//        if let titleColor = color {
//            attributeString.addAttributes([NSAttributedString.Key.foregroundColor : titleColor],//3
//                                          range: NSMakeRange(0, title.utf8.count))
//        }
//        self.setValue(attributeString, forKey: "attributedTitle")//4
//    }
}

extension UIAlertController {
    
    func applyBranding() {
        
        applyAlertTitleBranding()
        applyAlertMessageBranding()
    }
    
    func applyAlertTitleBranding() {
        let titleFont = [kCTFontAttributeName: UIFont(name: "Montserrat-Medium", size: 18.0)!]
        let titleAttrString = NSMutableAttributedString(string: title!, attributes: titleFont as [NSAttributedString.Key : Any])
        let titleColor = UIColor(red: 34.0/255/0, green: 34.0/255/0, blue: 34.0/255/0, alpha: 1.0)
        titleAttrString.addAttribute(NSAttributedString.Key.foregroundColor,
                                     value: titleColor,
                                     range: NSRange(location: 0, length: title!.count))
        setValue(titleAttrString, forKey: "attributedTitle")
    }
    
    func applyAlertMessageBranding() {
        let messageFont = [kCTFontAttributeName: UIFont(name: "Montserrat-Regular", size: 14.0)!]
        let messageAttrString = NSMutableAttributedString(string: message!, attributes: messageFont as [NSAttributedString.Key : Any])
        let messageTitleColor = UIColor(red: 68.0/255/0, green: 68.0/255/0, blue: 68.0/255/0, alpha: 1.0)
        messageAttrString.addAttribute(NSAttributedString.Key.foregroundColor,
                                       value: messageTitleColor,
                                       range: NSRange(location: 0, length: message!.count))
        setValue(messageAttrString, forKey: "attributedMessage")
    }
    
    func applyNoActionBranding() {
        let font = [kCTFontAttributeName: UIFont(name: "Montserrat-Medium", size: 16.0)!]
        for actionButton in actions {
            let titleAttrString = NSMutableAttributedString(string: actionButton.title!, attributes: font as [NSAttributedString.Key : Any])
            actionButton.setValue(titleAttrString, forKey: "attributedTitleForAction")
        }
    }
    
    func applyYesActionBranding() {
        let font = [kCTFontAttributeName: UIFont(name: "Montserrat-Regular", size: 16.0)!]
        for actionButton in actions {
            let titleAttrString = NSMutableAttributedString(string: actionButton.title!, attributes: font as [NSAttributedString.Key : Any])
            actionButton.setValue(titleAttrString, forKey: "attributedTitleForAction")
        }
    }
}
