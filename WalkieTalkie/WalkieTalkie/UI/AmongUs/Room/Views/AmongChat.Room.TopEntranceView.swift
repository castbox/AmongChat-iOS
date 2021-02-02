//
//  AmongChat.Room.TopEntranceView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 02/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVGAPlayer
import SwiftyUserDefaults

extension AmongChat.Room {
    class TopEntranceView: UIView {
        //backgroud
        private var gradient: CAGradientLayer!
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func configureSubview() {
            gradient = CAGradientLayer()
            gradient.frame = bounds
            gradient.colors = [#colorLiteral(red: 0.01960784314, green: 0.7803921569, blue: 0.9176470588, alpha: 1).cgColor, #colorLiteral(red: 0.1098039216, green: 0.4509803922, blue: 0.7294117647, alpha: 1).cgColor, #colorLiteral(red: 0, green: 1, blue: 0.2941176471, alpha: 1).cgColor]
            gradient.locations = [0.2, 0.5, 0.8]
            gradient.startPoint = CGPoint(x: 0, y: 0)
            gradient.endPoint = CGPoint(x: 1, y: 0)
            gradient?.cornerRadius = 22
            gradient?.masksToBounds = true
            layer.addSublayer(gradient!)
            
            backView.layer.cornerRadius = 10
            backView.clipsToBounds = true

        }
    }
}

class RoomTopEntranceView: XibLoadableView {
    
}
