//
//  OfficialBadgeView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/16.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class OfficialBadgeView: UIView {
    
    enum HeightStyle {
        case _14
        case _18
    }
    
    private lazy var label: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(hex6: 0x000000)
        l.text = "official"
        switch heightStyle {
        case ._14:
            l.font = R.font.nunitoExtraBold(size: 11)
        case ._18:
            l.font = R.font.nunitoExtraBold(size: 12)
        }
        return l
    }()
    
    private let heightStyle: HeightStyle
    
    init(heightStyle: HeightStyle) {
        self.heightStyle = heightStyle
        super.init(frame: .zero)
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    private func setUpLayout() {
        backgroundColor = UIColor(hex6: 0xFFF000)
        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(5)
            maker.centerY.equalToSuperview()
        }
    }
    
    private func updateLayout() {
        
        let labelWidth = label.textRect(forBounds: CGRect(origin: .zero,
                                                          size: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                       height: .greatestFiniteMagnitude)),
                                        limitedToNumberOfLines: 0).size.width
        let height: CGFloat
        switch heightStyle {
        case ._14:
            height = 14
        case ._18:
            height = 18
        }
        
        bounds = CGRect(origin: .zero, size: CGSize(width: labelWidth + 5 * 2, height: height))
        layer.cornerRadius = height / 2
        layoutIfNeeded()
    }
        
    func asImage() -> UIImage? {
        updateLayout()
        return screenshot
    }
}
