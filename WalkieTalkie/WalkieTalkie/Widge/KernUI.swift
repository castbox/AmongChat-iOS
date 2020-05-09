//
//  KernUI.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/5/9.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class WalkieLabel: UILabel {
    override var text: String? {
        set {
            super.text = newValue
        }
        get {
            super.text
        }
    }
    
    func appendKern(with kern: CGFloat = 0.5) {
        if let attrString = attributedText {
            let attributes: [NSAttributedString.Key : Any] = [
                .kern: kern,
            ]
//            let mAttribuate = NSMutableAttributedString(attributedString: )
            self.attributedText = attrString.applying(attributes: attributes, toOccurrencesOf: attrString.string)
        } else {
            let attributes: [NSAttributedString.Key : Any] = [
                .foregroundColor: textColor ?? .black,
                .font: font ?? R.font.nunitoSemiBold(size: 17),
                .kern: kern,
            ]
            let attString = NSAttributedString(string: text ?? "", attributes: attributes)
            self.attributedText = attString
        }
    }
}

class WalkieButton: UIButton {
    func appendKern(with kern: CGFloat = 0.5) {
        if let attrString = attributedTitle(for: .normal) {
            let attributes: [NSAttributedString.Key : Any] = [
                .kern: kern,
            ]
            let kernString = attrString.applying(attributes: attributes, toOccurrencesOf: attrString.string)
            setAttributedTitle(kernString, for: .normal)
//            setAttributedTitle(kernString, for: .highlighted)
        } else {
            let attributes: [NSAttributedString.Key : Any] = [
                .font: titleLabel?.font ?? R.font.nunitoSemiBold(size: 17),
                .kern: kern,
            ]
            setAttributedTitle(NSAttributedString(string: title(for: .normal) ?? "", attributes: attributes), for: .normal)
//            setAttributedTitle(NSAttributedString(string: title(for: .highlighted) ?? "", attributes: attributes), for: .highlighted)
        }
    }
}
