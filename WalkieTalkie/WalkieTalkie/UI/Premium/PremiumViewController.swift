//
//  PremiumViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SnapKit

class PremiumViewController: ViewController {
    
    private lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 24)
        lb.textColor = UIColor.white
        return lb
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(R.image.ac_back(), for: .normal)
        btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
        return btn
    }()
    
    private lazy var layoutScrollView: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.bounces = true
        return v
    }()
    
    private lazy var topBg: UIImageView = {
        let i = UIImageView(image: R.image.ac_premium_bg())
        i.contentMode = .scaleAspectFill
        return i
    }()
    
    private lazy var avatarIV: AvatarImageView = {
        let i = AvatarImageView()
        return i
    }()
    
    private lazy var nameLabel: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoExtraBold(size: 20)
        l.textColor = .white
        l.textAlignment = .center
        l.lineBreakMode = .byTruncatingMiddle
        return l
    }()
    
    private lazy var badgeIcon: UIImageView = {
        let i = UIImageView()
        return i
    }()
    
    private lazy var statusLabel: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoBold(size: 12)
        l.textColor = UIColor(hex6: 0x898989)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.text = R.string.localizable.premiumNotActivated()
        return l
    }()
    
    private lazy var yearlyProductView: ProductView = {
        let v = ProductView(with: .yearlyProduct)
        v.isSelected = true
        let gr = UITapGestureRecognizer(target: self, action: #selector(onProductViewTapped(_:)))
        v.addGestureRecognizer(gr)
        return v
    }()
    
    private lazy var weeklyProductView: ProductView = {
        let v = ProductView(with: .default)
        v.isSelected = false
        let gr = UITapGestureRecognizer(target: self, action: #selector(onProductViewTapped(_:)))
        v.addGestureRecognizer(gr)
        return v
    }()

    private lazy var monthlyProductView: ProductView = {
        let v = ProductView(with: .default)
        v.isSelected = false
        let gr = UITapGestureRecognizer(target: self, action: #selector(onProductViewTapped(_:)))
        v.addGestureRecognizer(gr)
        return v
    }()
    
    private lazy var productsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [weeklyProductView, yearlyProductView, monthlyProductView])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()
    
    private lazy var continueBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 24
        btn.backgroundColor = UIColor(hexString: "#FFF000")
        btn.setTitle(R.string.localizable.guideContinue(), for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
        btn.addTarget(self, action: #selector(onContinueBtn), for: .primaryActionTriggered)
        return btn
    }()
    
    private lazy var termsLabel: UILabel = {
        let lb = UILabel()
        lb.numberOfLines = 0
        lb.lineBreakMode = .byWordWrapping
        lb.font = R.font.nunitoBold(size: 10)
        lb.textAlignment = .left
        lb.textColor = UIColor(hex6: 0x606060)
        return lb
    }()
    
    private lazy var policyLabel: PolicyLabel = {
        let terms = R.string.localizable.amongChatTermsService()
        let privacy = R.string.localizable.amongChatPrivacyPolicy()
        let text = R.string.localizable.amongChatPrivacyLabel(terms, privacy)

        let lb = PolicyLabel(with: text, privacy: privacy, terms: terms)
        lb.onInteration = { [weak self] targetPath in
            self?.open(urlSting: targetPath)
        }
        lb.textColor = UIColor(hex6: 0x606060)
        lb.textAlignment = .left
        lb.font = R.font.nunitoBold(size: 10)
        return lb
    }()
    
    private lazy var privilegesTitle: UILabel = {
        let l = UILabel()
        l.font = R.font.nunitoBlack(size: 20)
        l.textColor = .white
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.text = R.string.localizable.amongChatProPrivilegesTitle()
        return l
    }()
    
    private lazy var privLeftLine: UIImageView = {
        let i = UIImageView(image: R.image.ac_privileges_left_line())
        return i
    }()
    
    private lazy var privRightLine: UIImageView = {
        let i = UIImageView(image: R.image.ac_privileges_right_line())
        return i
    }()
    
    private lazy var privilegeStack: UIStackView = {
        let privilegeViewModels = [
            (
                R.image.ac_pro_privilege_no_ad(),
                R.string.localizable.amongChatProPrivilegeNoAd(),
                R.string.localizable.amongChatProPrivilegeNoAdSub()
            ),
            (
                R.image.ac_pro_privilege_unlimited_cards(),
                R.string.localizable.amongChatProPrivilegeUnlimitedCards(),
                R.string.localizable.amongChatProPrivilegeUnlimitedCardsSub()
            ),
            (
                R.image.ac_pro_privilege_badge(),
                R.string.localizable.amongChatProPrivilegeBadge(),
                R.string.localizable.amongChatProPrivilegeBadgeSub()
            ),
            (
                R.image.ac_pro_privilege_match(),
                R.string.localizable.amongChatProPrivilegeMatch(),
                R.string.localizable.amongChatProPrivilegeMatchSub()
            ),
            (
                R.image.ac_pro_privilege_special_avatars(),
                R.string.localizable.amongChatProPrivilegeAvatars(),
                R.string.localizable.amongChatProPrivilegeAvatarsSub()
            ),
            (
                R.image.ac_pro_privilege_upload_avatar(),
                R.string.localizable.amongChatProPrivilegeCustomAvatars(),
                R.string.localizable.amongChatProPrivilegeCustomAvatarsSub()
            )
        ]
        
        let privilegeViews: [PrivilegeView] = privilegeViewModels.map {
            let view = PrivilegeView()
            view.iconIV.image = $0.0
            view.titleLabel.text = $0.1
            view.subtitleLabel.text = $0.2
            return view
        }
        let stack = UIStackView(arrangedSubviews: privilegeViews)
        stack.axis = .vertical
        stack.distribution = .equalSpacing
        stack.spacing = 24
        return stack
    }()
    
    private var weekProduct: IAP.ProductInfo? = nil {
        didSet {
            guard let p = weekProduct else { return }
            weeklyProductView.titleLabel.text = p.priceInfo.adj_renewalPeriod.firstCharacterUpperCase()
            weeklyProductView.subtitleLabel.text = p.priceInfo.price
        }
    }
    
    private var monthProduct: IAP.ProductInfo? = nil {
        didSet {
            guard let p = monthProduct else { return }
            monthlyProductView.titleLabel.text = p.priceInfo.adj_renewalPeriod.firstCharacterUpperCase()
            monthlyProductView.subtitleLabel.text = p.priceInfo.price
        }
    }
    
    private var yearProduct: IAP.ProductInfo? = nil {
        didSet {
            guard let p = yearProduct else { return }
            yearlyProductView.titleLabel.text = R.string.localizable.premiumPeriodFreeTrial(p.priceInfo.freePeriod)
            yearlyProductView.subtitleLabel.text = R.string.localizable.permiumYearlyProductPrice("\(p.priceInfo.price) / \(p.priceInfo.renewalPeriod)")
        }
    }
    
    private lazy var selectedProduct: String = IAP.productYear {
        didSet {
            updateTermsLabel(for: selectedProduct)
        }
    }
    private var productsMap = [String: IAP.ProductInfo]()
    var source: Logger.IAP.ActionSource?
    var dismissHandler: ((_ purchased: Bool) -> Void)?
    var didSelectProducts: (String) -> Void = { _ in }
    
    private let isPuchasingState = BehaviorRelay<Bool>(value: false)
    
    override var screenName: Logger.Screen.Node.Start {
        return .premium
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let s = self.source, s != .first_open {
            Logger.IAP.logImp(s)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let s = self.source, s != .first_open  {
            Logger.IAP.logClose(s)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
        setupProduct()
    }
    
    private func dismissSelf(purchased: Bool = false) {
        dismiss(animated: true) {
            self.dismissHandler?(purchased)
        }
    }
}

extension PremiumViewController {
    
    @objc
    private func onContinueBtn() {
        guard isPuchasingState.value == false else {
            return
        }
        buy(identifier: selectedProduct)
    }
    
    @objc
    private func onBackBtn() {
        dismissSelf()
    }
    
    @objc
    private func onProductViewTapped(_ sender: UITapGestureRecognizer) {
        
        guard let view = sender.view as? ProductView else {
            return
        }
        
        productsStack.arrangedSubviews.forEach {
            guard let v = $0 as? ProductView else { return}
            v.isSelected = false
        }
        
        view.isSelected = true
        
        switch view {
        case yearlyProductView:
            selectedProduct = IAP.productYear
        case monthlyProductView:
            selectedProduct = IAP.productMonth
        case weeklyProductView:
            selectedProduct = IAP.productWeek
        default:
            ()
        }
        
        updateProductViewsLayout()
    }
}

extension PremiumViewController {
    
    private func setupProduct() {
        IAP.productInfoMap
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (map) in
            guard map.count > 0 else {
                IAP.prefetchProducts()
                return
            }
            guard let `self` = self else { return }
            
            self.weekProduct = map[IAP.productWeek]
            self.yearProduct = map[IAP.productYear]
            self.monthProduct = map[IAP.productMonth]
            self.productsMap = map
            self.selectedProduct = IAP.productYear
            })
            .disposed(by: bag)
    }
    
    //for
    
    private func buy(identifier: String) {
        
        guard let product = productsMap[identifier]?.product else {
            return
        }
                
        if let s = self.source {
            Logger.IAP.logPurchase(productId: identifier, source: s)
        }
        
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = {
            removeHUDBlock()
        }
        
        isPuchasingState.accept(true)
        IAP.ProductDealer.pay(product, onState: { [weak self] (state, error) in
            cdPrint("ProductDealer state: \(state.rawValue)")
            switch state {
            case .purchased, .restored:
                
                let _ = Request.uploadReceipt(restore: true)
                    .flatMap({ (_) -> Single<Bool> in
                        return Settings.shared.isProValue.replay()
                            .filter { $0 }
                            .take(1)
                            .timeout(.seconds(15), scheduler: MainScheduler.asyncInstance)
                            .asSingle()
                    })
                    .observeOn(MainScheduler.asyncInstance)
                    .do(onDispose: {
                        removeBlock()
                        self?.isPuchasingState.accept(false)
                    })
                    .subscribe(onSuccess: { (_) in
                        self?.dismissSelf(purchased: true)
                    }, onError: { (error) in
                        self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                    })
                
                Defaults[\.purchasedItemsKey] = identifier
                if let s = self?.source {
                    Logger.IAP.logPurchaseResult(product: product.skProduct, source: s, isSuccess: true)
                }
            case .failed:
                self?.isPuchasingState.accept(false)
                cdPrint("Purchase failed")
                DispatchQueue.main.async {
                    removeBlock()
                    self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
                }
                if let s = self?.source {
                    Logger.IAP.logPurchaseResult(product: product.skProduct, source: s, isSuccess: false)
                }
            default:
                ()
            }
        })
    }
    
    private func bindSubviewEvent() {
        
        Settings.shared.amongChatUserProfile.replay()
            .filterNil()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (p) in
                self?.avatarIV.updateAvatar(with: p)
                self?.nameLabel.text = p.name
                
            })
            .disposed(by: bag)
        
        Settings.shared.isProValue.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (isPro) in
                self?.badgeIcon.image = isPro ? R.image.ac_pro_unlocked_badge() : R.image.ac_pro_unbuy_badge()
                self?.titleLabel.text = isPro ? R.string.localizable.amongChatProfileProCenter() : R.string.localizable.profileUnlockPro()
                guard isPro else { return }
                
                self?.statusLabel.removeFromSuperview()
                self?.productsStack.removeFromSuperview()
                self?.continueBtn.removeFromSuperview()
                self?.policyLabel.removeFromSuperview()
                self?.termsLabel.removeFromSuperview()
            })
            .disposed(by: bag)

    }
    
    private func configureSubview() {
        
        view.addSubviews(views:topBg, layoutScrollView)
        
        topBg.snp.makeConstraints { (maker) in
            maker.top.leading.trailing.equalToSuperview()
        }
        
        layoutScrollView.snp.makeConstraints { (maker) in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        let scrollContentView = UIView()
        layoutScrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.equalTo(view)
        }
        
        scrollContentView.addSubviews(views: backBtn, titleLabel,  avatarIV, nameLabel, badgeIcon, statusLabel, productsStack,
                                      continueBtn, termsLabel, policyLabel, privilegesTitle, privLeftLine, privRightLine, privilegeStack)
        
        let navLayoutGuide = UILayoutGuide()
        scrollContentView.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(49)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
        avatarIV.snp.makeConstraints { (maker) in
            maker.top.equalTo(navLayoutGuide.snp.bottom).offset(24)
            maker.width.height.equalTo(60)
            maker.centerX.equalToSuperview()
        }
        
        let nameLayoutGuide = UILayoutGuide()
        scrollContentView.addLayoutGuide(nameLayoutGuide)
        nameLayoutGuide.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(20)
        }
        
        nameLabel.snp.makeConstraints { (maker) in
            maker.leading.top.bottom.equalTo(nameLayoutGuide)
            maker.top.equalTo(avatarIV.snp.bottom).offset(4.5)
        }
        
        badgeIcon.snp.makeConstraints { (maker) in
            maker.trailing.centerY.equalTo(nameLayoutGuide)
            maker.leading.equalTo(nameLabel.snp.trailing).offset(4)
        }
        
        let removableContentlayoutGuide = UILayoutGuide()
        
        scrollContentView.addLayoutGuide(removableContentlayoutGuide)
        removableContentlayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(nameLabel.snp.bottom)
        }
        
        statusLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(removableContentlayoutGuide).offset(1)
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(20)
        }
        
        productsStack.snp.makeConstraints { (maker) in
            maker.top.equalTo(statusLabel.snp.bottom).offset(40)
            maker.centerX.equalToSuperview()
        }
        
        continueBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(20)
            maker.top.equalTo(productsStack.snp.bottom).offset(20)
            maker.height.equalTo(48)
            maker.centerX.equalToSuperview()
        }
        
        termsLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.top.equalTo(continueBtn.snp.bottom).offset(12)
        }
        
        policyLabel.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(20)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(termsLabel.snp.bottom)
            maker.bottom.equalTo(removableContentlayoutGuide)
        }
        
        privilegesTitle.snp.makeConstraints { (maker) in
            maker.top.equalTo(removableContentlayoutGuide.snp.bottom).offset(56)
            maker.centerX.equalToSuperview()
        }
        
        privLeftLine.snp.makeConstraints { (maker) in
            maker.leading.greaterThanOrEqualToSuperview().offset(20)
            maker.centerY.equalTo(privilegesTitle)
            maker.trailing.equalTo(privilegesTitle.snp.leading).offset(-8)
        }
        
        privRightLine.snp.makeConstraints { (maker) in
            maker.trailing.greaterThanOrEqualToSuperview().inset(20)
            maker.centerY.equalTo(privilegesTitle)
            maker.leading.equalTo(privilegesTitle.snp.trailing).offset(8)
            maker.width.equalTo(privLeftLine)
        }
        
        privilegeStack.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(20)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(privilegesTitle.snp.bottom).offset(20)
            maker.bottom.equalToSuperview().offset(-28)
        }
        
        updateProductViewsLayout()
    }
    
    private func updateProductViewsLayout() {
        
        let size: ((Bool) -> CGSize) = { isSelected in
            return isSelected ? CGSize(width: 131.scalValue, height: 131.scalValue * 175.0 / 131.0) :
                CGSize(width: 90.scalValue, height: 90.scalValue * 124.0 / 90.0)
        }
        
        productsStack.arrangedSubviews.forEach {
            guard let v = $0 as? ProductView else { return}
            v.snp.remakeConstraints { (maker) in
                maker.size.equalTo(size(v.isSelected))
            }
        }
        
    }
    
    private func updateTermsLabel(for productId: String) {
        guard let product = productsMap[productId] else { return }
        if productId == IAP.productYear {
            termsLabel.text = R.string.localizable.premiumSubscriptionTerms() + " " + R.string.localizable.premiumSubscriptionDetailFree(product.product.skProduct.localizedTitle, product.priceInfo.price)
        } else {
            termsLabel.text = R.string.localizable.premiumSubscriptionTerms() + " " + R.string.localizable.premiumSubscriptionDetailNormal(product.product.skProduct.localizedTitle, product.priceInfo.price)
        }
    }

}

extension PremiumViewController {
    
    class PrivilegeView: UIView {
        
        let iconIV: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        let titleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = .white
            l.adjustsFontSizeToFitWidth = true
            return l
        }()
        
        let subtitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 12)
            l.textColor = UIColor(hex6: 0x898989)
            l.adjustsFontSizeToFitWidth = true
            return l
        }()
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: iconIV, titleLabel, subtitleLabel)
            
            iconIV.snp.makeConstraints { (maker) in
                maker.leading.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
                maker.top.bottom.equalToSuperview().inset(4.5)
            }
            
            let textLayoutGuide = UILayoutGuide()
            addLayoutGuide(textLayoutGuide)
            textLayoutGuide.snp.makeConstraints { (maker) in
                maker.leading.equalTo(iconIV.snp.trailing).offset(8)
                maker.trailing.centerY.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalTo(textLayoutGuide)
                maker.height.equalTo(22)
            }
            
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalTo(textLayoutGuide)
                maker.top.equalTo(titleLabel.snp.bottom)
                maker.height.equalTo(16)
            }
        }
    }
    
}

extension PremiumViewController {
    
    class ProductView: UIView {
        
        enum Style {
            case yearlyProduct
            case `default`
        }
        
        var isSelected: Bool = false {
            didSet {
                if isSelected {
                    layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
                } else {
                    layer.borderColor = UIColor(hex6: 0x474747).cgColor
                }
            }
        }
        
        let titleLabel: UILabel = {
            let l = UILabel()
            l.textAlignment = .center
            return l
        }()
        
        let subtitleLabel: UILabel = {
            let l = UILabel()
            l.textAlignment = .center
            return l
        }()
        
        private let style: Style

        init(with style: Style) {
            self.style = style
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            updateLayout()
        }
        
        private func setupLayout() {
            layer.cornerRadius = 12
            layer.borderWidth = 3
            
            addSubviews(views: titleLabel, subtitleLabel)
            
        }
        
        private func updateLayout() {
            switch style {
            case .yearlyProduct:
                
                titleLabel.snp.remakeConstraints { (maker) in
                    maker.top.equalToSuperview()
                    maker.bottom.equalTo(subtitleLabel.snp.top)
                    maker.leading.trailing.equalToSuperview().inset(bounds.width * 12.0 / 131.0)
                }
                
                titleLabel.font = R.font.nunitoExtraBold(size: isSelected ? 22 : 15)
                titleLabel.textColor = .white
                titleLabel.adjustsFontSizeToFitWidth = true
                titleLabel.lineBreakMode = .byWordWrapping
                titleLabel.numberOfLines = 2
                
                subtitleLabel.snp.remakeConstraints { (maker) in
                    maker.leading.trailing.equalToSuperview().inset(bounds.width * 12.0 / 131.0)
                    maker.bottom.equalToSuperview().inset(bounds.height * 20.0 / 175.0)
                }
                
                subtitleLabel.font = R.font.nunitoBold(size: isSelected ? 12 : 8)
                subtitleLabel.textColor = UIColor(hex6: 0x898989)
                subtitleLabel.adjustsFontSizeToFitWidth = true
                subtitleLabel.numberOfLines = 1
                
            case .default:
                
                let layoutGuide = UILayoutGuide()
                addLayoutGuide(layoutGuide)
                layoutGuide.snp.makeConstraints { (maker) in
                    maker.leading.trailing.equalToSuperview().inset(bounds.width * 7.0 / 90.0)
                    maker.centerY.equalToSuperview()
                }
                
                titleLabel.snp.remakeConstraints { (maker) in
                    maker.leading.top.trailing.equalTo(layoutGuide)
                }
                
                titleLabel.font = R.font.nunitoExtraBold(size: isSelected ? 16 : 14)
                titleLabel.textColor = .white
                titleLabel.adjustsFontSizeToFitWidth = true
                titleLabel.numberOfLines = 1
                
                subtitleLabel.snp.remakeConstraints { (maker) in
                    maker.leading.bottom.trailing.equalTo(layoutGuide)
                    maker.top.equalTo(titleLabel.snp.bottom).offset(3)
                }
                
                subtitleLabel.font = R.font.nunitoExtraBold(size: isSelected ? 26 : 22)
                subtitleLabel.textColor = .white
                subtitleLabel.adjustsFontSizeToFitWidth = true
                subtitleLabel.numberOfLines = 1
            }
            
        }
        
        
    }
}

extension WalkieTalkie.ViewController {
    
    func presentPremiumView(source: Logger.IAP.ActionSource, afterDismiss: ((_ purchased: Bool) -> Void)? = nil) {
        let premiumVC = PremiumViewController()
        premiumVC.source = source
        premiumVC.dismissHandler = { (purchased) in
            if purchased {
                AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: R.string.localizable.amongChatLoginAuthSourcePro()))
            }
            afterDismiss?(purchased)
        }
        premiumVC.modalPresentationStyle = .fullScreen
        present(premiumVC, animated: true, completion: nil)
    }
}
