//
//  HeaderLoadingView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Conversation {
    class HeaderLoadingView: UICollectionReusableView {
        var indicator: UIActivityIndicatorView!
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            configureSubview()
            bindSubviewEvent()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            backgroundColor = .clear
            
            indicator = UIActivityIndicatorView(style: .white)
            indicator.startAnimating()
            addSubview(indicator)
            indicator.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
            }
        }
        
        private func configureSubview() {
            
        }
    }
}
