//
//  PolicyLabel.swift
//  Quotes
//
//  Created by 江嘉睿 on 2020/4/8.
//  Copyright © 2020 Guru Network Limited Inc. All rights reserved.
//

import Foundation
import YYText

class PolicyLabel: YYLabel {
    
    typealias LabelInteration = (_ targetPath: String) -> Void
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }
    
    var onInteration: LabelInteration?
    
    static let highlightedColor = UIColor(hex6: 0xb2b2b2)
    
    private func setup() {
        numberOfLines = 0
        textAlignment = .center
        preferredMaxLayoutWidth = UIScreen.main.bounds.size.width - 20 * 2
        lineBreakMode = .byWordWrapping
        let text = R.string.localizable.privacyLabel()
        let attTxt = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attTxt.addAttributes([NSAttributedString.Key.foregroundColor : PolicyLabel.highlightedColor,
                              NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: UIFont.Weight(rawValue: UIFont.Weight.regular.rawValue)),
                              NSAttributedString.Key.paragraphStyle : paragraphStyle],
                             range: NSRange(location: 0, length: text.count)
        )
        
        attTxt.addAttributes([NSAttributedString.Key.foregroundColor : PolicyLabel.highlightedColor],
                             range: (text as NSString).range(of: R.string.localizable.termsPrivacy())
        )
        
        attTxt.addAttributes([NSAttributedString.Key.foregroundColor : PolicyLabel.highlightedColor],
                             range: (text as NSString).range(of: R.string.localizable.termsService())
        )
        
        attributedText = attTxt
        
        textTapAction = { [weak self] (containerView:UIView, text:NSAttributedString, range:NSRange, rect:CGRect) -> Void in
            guard let `self` = self, let handler = self.onInteration else { return }
            let plcRng = (text.string as NSString).range(of: R.string.localizable.termsPrivacy())
            let srvcRng = (text.string as NSString).range(of: R.string.localizable.termsService())
            var target: String = ""
            if NSIntersectionRange(range, plcRng).length > 0 {
                target = "https://among.chat/policy.html"
            } else if NSIntersectionRange(range, srvcRng).length > 0 {
                target = "https://among.chat/term.html"
            } else {
                return
            }
            handler(target)
        }
        
    }
}
