
//
//  UILabelExtension.swift
//  Castbox
//
//  Created by JL on 2017/5/13.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit
import UIColor_Hex_Swift

public extension UILabel {
    
    func format(size: CGFloat = 15, weight: CGFloat = UIFont.Weight.semibold.rawValue, hexColor: String = "#666666") {
        font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight(rawValue: weight))
        if hexColor.contains("#") {
            textColor = UIColor(hexColor)
        } else {
            textColor = hexColor.color()
        }
        
    }
    
    func textSize(width: CGFloat = UIScreen.main.bounds.width, lineSpaceing: CGFloat = 20) -> CGSize {
        
        let attributeString = NSMutableAttributedString(string: self.text ?? "")
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpaceing
        attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, attributeString.length))
        
        let size = sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return size
    }
    
    // 设置`numberOfLines = 0`的原因：
    // 配合方法`func boundingRect(with constrainedSize: CGSize, font: UIFont, lineSpacing: CGFloat? = nil, lines: Int) -> CGSize`使用，可以很好的解决不能正常显示限制行数的问题；
    // 如果为label设置了限制行数（大于0的前提），使用上面的计算方法（带行间距），同时字符串的实际行数大于限制行数，这时候的高度会使label不能正常显示。
    func setText(with normalString: String, lineSpacing: CGFloat?, frame: CGRect) {
        self.frame = frame
        self.numberOfLines = 0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        if lineSpacing != nil {
            if (frame.height - font.lineHeight) <= lineSpacing! {
                paragraphStyle.lineSpacing = 0
            } else {
                paragraphStyle.lineSpacing = lineSpacing!
            }
        }
        let attributedString = NSMutableAttributedString(string: normalString)
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttributes([NSAttributedString.Key.font: font], range: range)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        
        self.attributedText = attributedString
    }
}
