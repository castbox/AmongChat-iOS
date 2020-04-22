//
//  PremiumContainer.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

protocol PremiumContainerable: UIView {
    var closeHandler: () -> Void { get set }
    var policyHandler: () -> Void { get set }
    var buyProductHandler: (String) -> Void { get set }
}

class PremiumContainer: XibLoadableView, PremiumContainerable {
    var gradientLayer: CAGradientLayer!
    
    var closeHandler: () -> Void = {}
    
    var policyHandler: () -> Void = {}
    
    var buyProductHandler: (String) -> Void = { _ in }
//    @IBOutlet weak var lifeTimeButton: UIButton!
//    @IBOutlet weak var monthButton: UIButton!
//    @IBOutlet weak var container: UIView!
//    @IBOutlet weak var freetrielButton: UIButton!
//
//    @IBOutlet weak var faceView: UIImageView!
//    @IBOutlet weak var scrollView: UIScrollView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubview()
    }
    
    
    @IBAction func closeButtonAction(_ sender: Any) {
        closeHandler()
    }
    
    @IBAction func policyButtonAction(_ sender: Any) {
        policyHandler()
//        open(urlSting: "https://walkietalkie.live/policy.html")
    }
    
    @IBAction func lifetimeAction(_ sender: Any) {
        
        buyProductHandler(IAP.productLifeTime)
    }
    
    @IBAction func monthButtonAction(_ sender: Any) {
        buyProductHandler(IAP.productMonth)
    }
    
    @IBAction func skipTrialAction(_ sender: Any) {
        buyProductHandler(IAP.productYear)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
//        scrollView.contentInset = .zero
    }
}

extension PremiumContainer {
    func configureSubview() {
        let startColor = UIColor(hex: 0x3023AE)!
        let middenColor = UIColor(hex: 0x462EB4)!
        let endColor = UIColor(hex: 0xC86DD7)!
        let gradientColors: [CGColor] = [startColor.cgColor, middenColor.cgColor, endColor.cgColor]
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = [NSNumber(value: 0), NSNumber(value: 0.3), NSNumber(value: 1),]
        //(这里的起始和终止位置就是按照坐标系,四个角分别是左上(0,0),左下(0,1),右上(1,0),右下(1,1))
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.1, y: 1)
        //设置frame和插入view的layer
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
        
    }
}
