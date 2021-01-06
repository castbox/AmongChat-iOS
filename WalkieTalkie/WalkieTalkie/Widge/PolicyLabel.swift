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
    
    private let plainString: String
    private let privacy: String
    private let terms: String
    
    init(with plainString: String, privacy: String, terms: String) {
        self.privacy = privacy
        self.terms = terms
        self.plainString = plainString
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init?(coder:) not implemented")
    }
    
    var onInteration: LabelInteration?
        
    private func setup() {
        numberOfLines = 0
        textAlignment = .center
        preferredMaxLayoutWidth = 300
        lineBreakMode = .byWordWrapping
        let text = plainString
        let privacyRange = (text as NSString).range(of: privacy)
        let termsRange = (text as NSString).range(of: terms)
        
        let attTxt = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let font: UIFont = R.font.nunitoExtraBold(size: 10) ?? UIFont.systemFont(ofSize: 10, weight: UIFont.Weight(rawValue: UIFont.Weight.bold.rawValue))
        
        attTxt.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.white,
                              NSAttributedString.Key.font : font,
                              NSAttributedString.Key.paragraphStyle : paragraphStyle],
                             range: NSRange(location: 0, length: text.count)
        )
        
        attTxt.addAttributes([NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue],
                             range: termsRange
        )
        
        attTxt.addAttributes([NSAttributedString.Key.underlineStyle : NSUnderlineStyle.single.rawValue],
                             range: privacyRange
        )
        
        attributedText = attTxt
        
        textTapAction = { [weak self] (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) -> Void in
            guard let `self` = self,
                  let handler = self.onInteration else {
                return
            }
            var target: String = ""
            if NSIntersectionRange(range, privacyRange).length > 0 {
                target = Config.PolicyType.url(.policy)
            } else if NSIntersectionRange(range, termsRange).length > 0 {
                target = Config.PolicyType.url(.terms)
            } else {
                return
            }
            handler(target)
        }
        
    }
}
