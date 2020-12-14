//
//  PremiumContainer.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol PremiumContainerable: UIView {
    var closeHandler: () -> Void { get set }
    var policyHandler: () -> Void { get set }
    var buyProductHandler: (String) -> Void { get set }
    func selectProduct(id: String)
}

class PremiumContainer: XibLoadableView, PremiumContainerable {
    func selectProduct(id: String) {
    }
    
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var lifeTimeButton: UIButton!
    @IBOutlet weak var yearButton: UIButton!
    let bag = DisposeBag()
    
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
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubview()
        bindSubviewEvent()
    }
    
    
    @IBAction func closeButtonAction(_ sender: Any) {
        closeHandler()
    }
    
    @IBAction func policyButtonAction(_ sender: Any) {
        policyHandler()
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
    
    @IBAction func restoreAction(_ sender: Any) {
        IAP.restorePurchased { _ in
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
//        scrollView.contentInset = .zero
    }
}

extension PremiumContainer {
    func bindSubviewEvent() {
        IAP.productsValue
            //                    .observeOn(Scheduler.backgroundScheduler)
            //            .map { (productMap) -> [String: ProductInfo] in
            //                var newMap = [String: ProductInfo]()
            //                productMap.forEach({ (key, value) in
            //                    let price = value.skProduct.localizedPrice
            //                    var actionDesc: String
            //                    var termsDesc: String
            //                    switch value.info.category {
            //                    case let .sub(free: free, renewal: duration):
            //                        if free != nil {
            //                            actionDesc = R.string.localizable.premiumFreeTrial()
            //                            termsDesc = R.string.localizable.premiumSubscriptionDetailFree(value.skProduct.localizedTitle, price)
            //
            //
            //                        } else {
            //                            actionDesc = R.string.localizable.premiumFreeTrial()
            //                            termsDesc = R.string.localizable.premiumSubscriptionDetailNormal(value.skProduct.localizedTitle, price)
            //                        }
            //                    }
            //                    let info = ProductInfo(identifier: value.skProduct.productIdentifier
            //                        , actionDesc: actionDesc, termsDesc: termsDesc, product: value)
            //                    newMap[key] = info
            //                })
            //                return newMap
            //        }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] maps in
                guard let `self` = self else { return }
                //button
                if let product = maps[IAP.productYear]?.skProduct {
//                    if FireStore.shared.isInReviewSubject.value {
                        self.yearButton.setAttributedTitle(nil, for: .normal)
                        self.yearButton.setTitleColor(.black, for: .normal)
                        self.yearButton.setTitle("\(product.localizedPrice) / Year", for: .normal)
//                    } else {
//                        let paragrph = NSMutableParagraphStyle()
//                        paragrph.alignment = .center
//                        let mutableNormalString = NSMutableAttributedString()
//                        let tryDesAttr: [NSAttributedString.Key: Any] = [
//                            .foregroundColor: "6C6C6C".color(),
//                            .font: UIFont.systemFont(ofSize: 11),
//                            .paragraphStyle: paragrph,
//                        ]
//                        let tryAttr: [NSAttributedString.Key: Any] = [
//                            .foregroundColor: UIColor.black,
//                            .font: Font.premiumSubscribeTry.value,
//                            .kern: 0.5,
//                            .paragraphStyle: paragrph,
//                        ]
//                        mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumTryTitle(), attributes: tryAttr))
//                        mutableNormalString.append(NSAttributedString(string: "\n\(R.string.localizable.premiumTryTitleDes(product.localizedPrice))", attributes: tryDesAttr))
//                        self.yearButton.setAttributedTitle(mutableNormalString, for: .normal)
//                    }
                }
                if let product = maps[IAP.productMonth]?.skProduct {
                    self.monthButton.setTitle("\(product.localizedPrice) / Month", for: .normal)
                }
                if let product = maps[IAP.productLifeTime]?.skProduct {
                    self.lifeTimeButton.setTitle("\(product.localizedPrice) / Lifetime", for: .normal)
//                    self.lifeTimeButton.setTitle("\(product.localizedPrice) / Week", for: .normal)

                }
                
                //            if let product = map[IAP.productMonth]
                //            {
                //                self.monthProduct = product
                //                switch product.product.info.category{
                //                case let .sub(_, renewal):
                //                    self.premiumView.buyButtonMonth.setTitle("\(product.product.skProduct.localizedPrice)/\(renewal.asPerDuration())", for: .normal)
                //                }
                //
                //            }
                //            if let product = map[IAP.productWeek] {
                //                self.weekProduct = product
                //                switch product.product.info.category{
                //                case let .sub(_, renewal):
                //                    self.premiumView.buyButtonWeek.setTitle("\(product.product.skProduct.localizedPrice)/\(renewal.asPerDuration())", for: .normal)
                //                }
                //            }
                //            if let product = map[IAP.productYear] {
                //                self.yearProduct = product
                //                self.currentProduct.accept(product)
                //            }
                //
                //            if self.isPremiumPage(), let text = self.freetrialText() {
                //                self.actionBtn.setTitle(text, for: .normal)
                //            }
            })
            .disposed(by: bag)
    }
    
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
