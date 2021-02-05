//
//  AppTrackingGuideView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 05/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AppTrackingGuideView: XibLoadableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var allowTrackingHandler: CallBack?
    var laterHandler: CallBack?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func allowTrackingAction(_ sender: Any) {
        allowTrackingHandler?()
    }
    
    @IBAction func laterAction(_ sender: Any) {
        laterHandler?()
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        let fullString = NSMutableAttributedString(string: R.string.localizable.trackingGuideTitle())
        let suffixString = NSAttributedString(
            string: R.string.localizable.trackingGuideTitleSuffix(),
            attributes: [NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 20)]
        )
        fullString.yy_appendString(" ")
        fullString.append(suffixString)
        titleLabel.attributedText = fullString
    }
}
