//
//  GuideFourthView_b.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/7/13.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GuideFourthView_b: XibLoadableView, PremiumContainerable {
    
    
    @IBOutlet weak var yearButton: GuideProductButton!
    @IBOutlet weak var monthButton: GuideProductButton!
    @IBOutlet weak var weekButton: GuideProductButton!
    //    @IBOutlet weak var lifetimeButton: GuideProductButton!
    
    @IBOutlet weak var vipDesLabel: WalkieLabel!
    @IBOutlet weak var tipsLabel: UILabel!
    @IBOutlet weak var iconGuide: UIImageView!
    
    private lazy var termsBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.alpha(0.5)
        v.isHidden = true
        return v
    }()
    
    private lazy var termsLabel: UILabel = {
        let lb = UILabel()
        lb.numberOfLines = 0
        lb.lineBreakMode = .byWordWrapping
        lb.textColor = UIColor.white
        lb.font = R.font.nunitoRegular(size: 12)
        lb.textAlignment = .left
        return lb
    }()
    
    private var productsMap = [String: IAP.ProductInfo]()

    private weak var selectedButton: GuideProductButton? {
        didSet {
            if Constants.abGroup == .b {
                oldValue?.hasSelected = false
                selectedButton?.hasSelected = false
                selectedButton?.selectedTagLabel.isHidden = true
            } else {
                oldValue?.hasSelected = false
                selectedButton?.hasSelected = true
//                if selectedButton == yearButton {
//                    selectedButton?.selectedTagLabel.isHidden = true
//                }
            }
        }
    }
    
    var selectedProductId: String = IAP.productYear {
        didSet {
            didSelectProducts(selectedProductId)
        }
    }
    
    var closeHandler: () -> Void = { }
    
    var policyHandler: () -> Void = { }
    
    var buyProductHandler: (String) -> Void = { _ in }
    
    var didSelectProducts: (String) -> Void = { _ in }
    
    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        selectedProductId = IAP.productYear
        
        FireStore.shared.isInReviewSubject
            .filter { !$0 }
            .map { !$0 }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self, self.selectedProductId == IAP.productYear else {
                    return
                }
                self.selectedProductId = IAP.productYear
            })
            .disposed(by: bag)
        
        IAP.productsValue
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] maps in
                self?.updateButtonTitles(maps)
            })
            .disposed(by: bag)
        
        let _ = IAP.productInfoMap
            .take(1)
            .subscribe(onNext: {  [weak self] (map) in
                self?.productsMap = map
                self?.termsBackgroundView.isHidden = false
                guard let p = self?.productsMap[IAP.productYear] else {
                    return
                }
                self?.updateTermsLabel(for: p)
            })
        vipDesLabel.appendKern()
//        yearButton.appendKern()
        monthButton.appendKern()
//        yearButton.disableSelectTag = true
        monthButton.disableSelectTag = true
        weekButton.disableSelectTag = true
//        weekButton.isHidden = IAP.isWeekProductInReview
//        weekButton.isHidden = true
        
        insertSubview(termsLabel, aboveSubview: iconGuide)
        insertSubview(termsBackgroundView, belowSubview: termsLabel)
        termsLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(iconGuide)
            maker.width.equalTo(223)
        }
        termsBackgroundView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(termsLabel).inset(-10)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        closeHandler()
    }
    
    @IBAction func policyAction(_ sender: Any) {
        policyHandler()
    }
    
    @IBAction func yearButtonAction(_ sender: GuideProductButton) {
        selectedButton = sender
        selectedProductId = IAP.productYear
        buyProductHandler(IAP.productYear)
        updateTipsLabelContent(sender)
    }
    
    @IBAction func lifetimeAction(_ sender: GuideProductButton) {
        selectedButton = sender
        selectedProductId = IAP.productLifeTime
        buyProductHandler(IAP.productLifeTime)
        
    }
    @IBAction func restoreAction(_ sender: Any) {
        IAP.restorePurchased { _ in
            
        }
    }
    
    @IBAction func weakAction(_ sender: GuideProductButton) {
        selectedButton = sender
        selectedProductId = IAP.productWeek
        buyProductHandler(IAP.productWeek)
        
    }
    
    @IBAction func monthButtonAction(_ sender: GuideProductButton) {
        selectedButton = sender
        selectedProductId = IAP.productMonth
        buyProductHandler(IAP.productMonth)
        updateTipsLabelContent(sender)
    }
    
    @IBAction func privacyAction(_ sender: Any) {
        parentViewController?.open(urlSting: "https://walkietalkie.live/policy.html")
        policyHandler()
    }
    
    func updateTipsLabelContent(_ sender: GuideProductButton) {
        if sender == yearButton {
            tipsLabel.text = """
            3-day free trial, then \(sender.title(for: .normal) ?? "").
            Automatically renew. Cancel anytime.
            """
        } else {
            tipsLabel.text = """
            \(sender.title(for: .normal) ?? "").
            Automatically renew. Cancel anytime.
            """
        }
    }
    
    func updateButtonTitles(_ maps: [String: IAP.Product]) {
        //button
//        if let product = maps[IAP.productYear]?.skProduct {
//            cdPrint("product.localizedPrice: \(product.localizedPrice) / Year")
//            yearButton.setAttributedTitle(nil, for: .normal)
//            yearButton.setTitle("\(product.localizedPrice) / Year", for: .normal)
//            if selectedButton == nil {
//                yearButton.isSelected = true
//                selectedButton = yearButton
//                updateTipsLabelContent(yearButton)
//            }
//        }
        if let product = maps[IAP.productMonth]?.skProduct {
            monthButton.setAttributedTitle(nil, for: .normal)
            monthButton.setTitle("\(product.localizedPrice) / Month", for: .normal)
        }
        if let product = maps[IAP.productWeek]?.skProduct {
            weekButton.setAttributedTitle(nil, for: .normal)
            weekButton.setTitle("\(product.localizedPrice) / Week", for: .normal)
            weekButton.isHidden = false
        } else {
//            weekButton.isHidden = true
        }
//        yearButton.appendKern()
        monthButton.appendKern()
        weekButton.appendKern()
    }
}

extension GuideFourthView_b {
    
    private typealias ProductInfo = IAP.ProductInfo
    
    private func updateTermsLabel(for product: ProductInfo) {
                
        if product.identifier == IAP.productLifeTime {
            termsLabel.text = R.string.localizable.premiumSubscriptionDetailLifetime()
        } else if product.identifier == IAP.productYear {
            termsLabel.text = R.string.localizable.premiumSubscriptionTerms() + " " + R.string.localizable.premiumSubscriptionDetailFree(product.product.skProduct.localizedTitle, product.priceInfo.price)
        } else {
            termsLabel.text = R.string.localizable.premiumSubscriptionTerms() + " " + R.string.localizable.premiumSubscriptionDetailNormal(product.product.skProduct.localizedTitle, product.priceInfo.price)
        }
    }
    
    func selectProduct(id: String) {
        guard let p = productsMap[id] else {
            return
        }
        updateTermsLabel(for: p)
    }
    
}
