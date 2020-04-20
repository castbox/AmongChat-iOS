//
//  NativeToMRectAdView.swift
//  Scanner
//
//  Created by 江嘉睿 on 2020/2/6.
//  Copyright © 2020 江嘉睿. All rights reserved.
//

import Foundation
import MoPub

class NativeToMrectContainerView: UIView, MPNativeAdRendering {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let banner = subviews.last as? MPAdView {
            
            let contentWidth = banner.adContentViewSize().width
            let contentHeight = banner.adContentViewSize().height
            
            if contentWidth > 0 && contentHeight > 0 {
                let w_hRatio: CGFloat = contentWidth / contentHeight
                let width:CGFloat = fmin(frame.width, banner.adContentViewSize().width)
                let height:CGFloat = width / w_hRatio
                let x:CGFloat = (frame.width - width) / 2
                let y:CGFloat = (frame.height - height) / 2
                banner.frame = CGRect(x: x, y: y, width: width, height: height)
            } else {
                banner.frame = bounds
            }
            
        }
    }
}
