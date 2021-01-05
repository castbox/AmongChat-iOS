//
//  UIViewLocalizableExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 05/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

protocol Localizable {
    var localized: String { get }
}

extension String: Localizable {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}


protocol XIBLocalizable {
    var xibLocKey: String? { get set }
}

extension UILabel: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            text = key?.localized
        }
    }
}

extension UIButton: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            setTitle(key?.localized, for: .normal)
        }
   }
}

extension UITextField: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            text = xibLocKey?.localized
        }
   }
    
    @IBInspectable var placeholderXibLocKey: String? {
        get { return nil }
        set(key) {
            placeholder = placeholderXibLocKey?.localized
        }
   }
}
