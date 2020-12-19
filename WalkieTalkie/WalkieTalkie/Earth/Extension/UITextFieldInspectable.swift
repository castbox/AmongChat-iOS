//
//  UITextFieldInspectable.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 19/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

//@IBDesignable
class PaddingTextField: UITextField {

    @IBInspectable var paddingLeft: CGFloat = 0
    @IBInspectable var paddingRight: CGFloat = 0

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x + paddingLeft, y: bounds.origin.y, width: bounds.size.width - paddingLeft - paddingRight, height: bounds.size.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }

}
