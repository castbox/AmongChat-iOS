//
//  NavigationBar.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/12.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class NavigationBar: UIView {
    
    static let barHeight: CGFloat = 49
    
    private(set) lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 24)
        lb.textColor = UIColor.white
        lb.textAlignment = .center
        lb.adjustsFontSizeToFitWidth = true
        return lb
    }()
    
    private(set) lazy var leftBtn: UIButton = {
        let btn = SmallSizeButton(type: .custom)
        return btn
    }()
    
    private(set) lazy var backgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex6: 0x121212)
        v.isHidden = true
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpLayout() {
        addSubviews(views: backgroundView, titleLabel, leftBtn)
        
        let layoutGuide = UILayoutGuide()
        addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(Self.barHeight)
        }
        
        backgroundView.snp.makeConstraints { (maker) in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(-Frame.Height.safeAeraTopHeight)
        }
        
        leftBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
            maker.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.leading.greaterThanOrEqualTo(leftBtn.snp.trailing).offset(20)
            maker.height.equalTo(33)
        }
        
        leftBtn.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
        leftBtn.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
        titleLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
        
    }
    
}
