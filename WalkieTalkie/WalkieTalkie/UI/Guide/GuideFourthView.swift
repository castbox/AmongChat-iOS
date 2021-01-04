//
//  GuideFourthView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GuideProductButton: WalkieButton {
    var selectedTagLabel: UILabel!
    private var indicator: UIActivityIndicatorView!
    var disableSelectTag: Bool = false {
        didSet {
            selectedTagLabel.isHidden = disableSelectTag
        }
    }
    
    var hasSelected: Bool = false {
        didSet {
            guard Constants.abGroup == .a else { return }
            selectedTagLabel.isHidden = !hasSelected
            if hasSelected {
                setBackgroundImage("FFCA1E".color().image, for: .normal)
            } else {
                setBackgroundImage("FFF5CE".color().image, for: .normal)
            }
        }
    }
//
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        selectedTagLabel = UILabel(text: "✔️")
        selectedTagLabel.textColor = .black
        selectedTagLabel.font = R.font.nunitoBold(size: 10)
        selectedTagLabel.isHidden = true
        addSubview(selectedTagLabel)
        selectedTagLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(17.5)
        }
        
        indicator = UIActivityIndicatorView(style: .gray)
        indicator.tintColor = .white
        indicator.hidesWhenStopped = true
        addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        indicator.startAnimating()
    }
    
    override func setTitle(_ title: String?, for state: UIControl.State) {
        indicator.stopAnimating()
        super.setTitle(title, for: state)
    }
}

class GuideFourthView: XibLoadableView, PremiumContainerable {
    
    func selectProduct(id: String) {
    }
    
    @IBOutlet weak var yearButton: GuideProductButton!
    @IBOutlet weak var monthButton: GuideProductButton!
//    @IBOutlet weak var lifetimeButton: GuideProductButton!
    
    @IBOutlet weak var vipDesLabel: WalkieLabel!
    @IBOutlet weak var tipsLabel: UILabel!
    
    @IBOutlet weak var backgroundIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var yearButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var yearButtonLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var yearButtonRightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var desLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var descLabelLeftConstraint: NSLayoutConstraint!
//    @IBOutlet weak var productsContainerRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var emojiTopContainer: NSLayoutConstraint!
    private weak var selectedButton: GuideProductButton? {
        didSet {
            oldValue?.hasSelected = false
            selectedButton?.hasSelected = true
            if selectedButton == yearButton {
                selectedButton?.selectedTagLabel.isHidden = true
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
        
        Settings.shared.isInReview.replay()
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
        
        if Frame.Height.deviceDiagonalIsMinThan4_7 {
            emojiTopContainer.constant = 25
//            yearButtonLeftConstraint.constant = 15
//            yearButtonRightConstraint.constant = 15
//            yearButtonHeightConstraint.constant = 36
//            let text = tipsLabel.attributedText?.string
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.lineSpacing = 0
//            tipsLabel.attributedText = NSAttributedString(string: text ?? "", attributes: [NSAttributedString.Key.paragraphStyle : paragraph,
//                                                                                           NSAttributedString.Key.font: Font.smallBody.value])
//            yearButton.cornerRadius = 16
//            monthButton.cornerRadius = 16
//            lifetimeButton.cornerRadius = 16
//            productsContainerRightConstraint.constant = 10
//            descLabelLeftConstraint.constant = 15
//            topContainerTopConstraint.constant = 34
        } else if Frame.Height.deviceDiagonalIsMinThan5_5  {
//            topContainerTopConstraint.constant = 34
        } else {
//            topContainerTopConstraint.constant = Frame.Scale.height(90)
        }
//
        if Frame.Height.deviceDiagonalIsMinThan5_5 {
            desLabelBottomConstraint.constant = Frame.Scale.height(156)
        }
//
//        backgroundIconWidthConstraint.constant = Frame.Screen.width - 27 * 2
//
//        mainQueueDispatchAsync(after: 0.5) { [weak self] in
//            self?.yearButton.isSelected = true
//            self?.selectedButton = self?.yearButton
//        }
        
        IAP.productsValue
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] maps in
                self?.updateButtonTitles(maps)
            })
            .disposed(by: bag)
        
        vipDesLabel.appendKern()
        yearButton.appendKern()
        monthButton.appendKern()
//        lifetimeButton.appendKern()
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
    
    @IBAction func restoreAction(_ sender: Any) {
        IAP.restorePurchased { result in
            
        }
    }
    
    @IBAction func lifetimeAction(_ sender: GuideProductButton) {
        selectedButton = sender
        selectedProductId = IAP.productLifeTime
        buyProductHandler(IAP.productLifeTime)

    }
    
    @IBAction func monthButtonAction(_ sender: GuideProductButton) {
        selectedButton = sender
        selectedProductId = IAP.productMonth
        buyProductHandler(IAP.productMonth)
        updateTipsLabelContent(sender)
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
        if let product = maps[IAP.productYear]?.skProduct {
            cdPrint("product.localizedPrice: \(product.localizedPrice) / Year")
            yearButton.setAttributedTitle(nil, for: .normal)
            yearButton.setTitle("\(product.localizedPrice) / Year", for: .normal)
            if selectedButton == nil {
                yearButton.isSelected = true
                selectedButton = yearButton
                updateTipsLabelContent(yearButton)
            }
        }
        if let product = maps[IAP.productMonth]?.skProduct {
            monthButton.setAttributedTitle(nil, for: .normal)
            monthButton.setTitle("\(product.localizedPrice) / Month", for: .normal)
        }
//        if let product = maps[IAP.productLifeTime]?.skProduct {
//            lifetimeButton.setAttributedTitle(nil, for: .normal)
//            lifetimeButton.setTitle("\(product.localizedPrice) / Lifetime", for: .normal)
//        }
        yearButton.appendKern()
        monthButton.appendKern()
//        lifetimeButton.appendKern()
    }
}

