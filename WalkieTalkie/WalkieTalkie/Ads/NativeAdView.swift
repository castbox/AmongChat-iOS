//
//  NativeAdView.swift
//  Scanner
//
//  Created by 江嘉睿 on 2020/2/5.
//  Copyright © 2020 江嘉睿. All rights reserved.
//

import Foundation
import MoPub
import SwifterSwift

//class NativeAdView: UIView, MPNativeAdRendering {
//    let titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//        label.textColor = Theme.cellTitleColor
//        return label
//    }()
//    
//    let mainTextLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 13)
//        label.textColor = Theme.cellTitleColor
//        label.numberOfLines = 3
//        label.textAlignment = .center
//        return label
//    }()
//    
//    let mainImageView: UIImageView = {
//        let iv = UIImageView()
//        iv.clipsToBounds = true
//        iv.contentMode = .scaleAspectFill
//        return iv
//    }()
//    
//    let privacyInformationIconImageView:  UIImageView = {
//        let iv = UIImageView()
//        return iv
//    }()
//    
//    internal let ctaLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 16, weight: .semibold)
//        label.textColor = UIColor.white.withAlphaComponent(0.87)
//        label.textAlignment = .center
//        return label
//    }()
//    
//    internal let ctaBg: GradientView = {
//        let v = GradientView()
//        v.layer.colors = [UIColor(hex6: 0xFB9448).cgColor, UIColor(hex6: 0xF55B23).cgColor]
//        v.layer.startPoint = CGPoint(x: 0, y: 0)
//        v.layer.endPoint = CGPoint(x: 1.0, y: 1.0)
//        v.layer.cornerRadius = 4.0
//        return v
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        clipsToBounds = true
//        
//        addSubviews(views: ctaBg, titleLabel, privacyInformationIconImageView, mainImageView, mainTextLabel, ctaLabel)
//
//        privacyInformationIconImageView.snp.makeConstraints { (maker) in
//            maker.top.equalToSuperview().offset(10)
//            maker.right.equalToSuperview().offset(-10)
//            maker.size.equalTo(CGSize(width: 30, height: 30))
//        }
//
//        titleLabel.snp.makeConstraints { (maker) in
//            maker.left.equalTo(5)
//            maker.right.lessThanOrEqualTo(privacyInformationIconImageView.snp.left).offset(-5)
//            maker.top.equalTo(5)
//            maker.height.equalTo(18)
//        }
//        
//        mainImageView.snp.makeConstraints { (maker) in
//            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
//            maker.left.equalToSuperview()
//            maker.right.equalToSuperview()
//        }
//        
//        mainTextLabel.snp.makeConstraints { (maker) in
//            maker.left.equalToSuperview().offset(5)
//            maker.right.equalToSuperview().offset(-5)
//            maker.top.equalTo(mainImageView.snp.bottom).offset(5)
//        }
//        
//        ctaLabel.snp.makeConstraints { (maker) in
//            maker.left.equalToSuperview().offset(5)
//            maker.top.equalTo(mainTextLabel.snp.bottom).offset(8)
//            maker.right.equalToSuperview().offset(-5)
//            maker.height.equalTo(28)
//            maker.bottom.equalToSuperview().offset(-5)
//        }
//        
//        ctaBg.snp.makeConstraints { (make) in
//            make.edges.equalTo(ctaLabel)
//        }
//        
//        let lower = UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1)
//        let higher = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1)
//
//        mainImageView.setContentCompressionResistancePriority(lower, for: .vertical)
//        mainImageView.setContentHuggingPriority(lower, for: .vertical)
//        mainTextLabel.setContentCompressionResistancePriority(higher, for: .vertical)
//        mainTextLabel.setContentHuggingPriority(higher, for: .vertical)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//    }
//    
//    // MARK: MPNativeAdRendering
//    
//    func nativeMainTextLabel() -> UILabel! {
//        return mainTextLabel
//    }
//    
//    func nativeTitleTextLabel() -> UILabel! {
//        return titleLabel
//    }
//    
//    func nativeCallToActionTextLabel() -> UILabel! {
//        return ctaLabel
//    }
//    
//    func nativeMainImageView() -> UIImageView! {
//        return mainImageView
//    }
//    
//    func nativePrivacyInformationIconImageView() -> UIImageView! {
//        return privacyInformationIconImageView
//    }
//}
