//
//  GuideFirstView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class GuideFirstView: XibLoadableView {
    @IBOutlet weak var desLabelBottomConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if Frame.Height.deviceDiagonalIsMinThan5_5 {
            //            desLabelBottomConstraint.constant = 96
            desLabelBottomConstraint.constant = Frame.Scale.height(156)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
