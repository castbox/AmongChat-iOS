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
    
    enum ContainerStyle {
        case `default`
        case guide
    }

    @IBOutlet weak var lifeTimeButton: UIButton!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var freetrielButton: UIButton!
    
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var gradientLayer: CAGradientLayer!
    var source: Logger.IAP.ActionSource?
    var premiumContainer: PremiumContainerable!
    var style: ContainerStyle = .default
    var dismissHandler: (()->Void)? = nil
    
    private let isPuchasingState = BehaviorSubject<Bool>.init(value: false)
    
    override var screenName: Logger.Screen.Node.Start {
        return .premium
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.statusBarStyle = .lightContent
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.statusBarStyle = .lightContent
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        gradientLayer.frame = view.bounds
//        scrollView.contentInset = .zero
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        dismissSelf()
    }
    
    @IBAction func policyButtonAction(_ sender: Any) {
        open(urlSting: "https://walkietalkie.live/policy.html")
    }
    
    @IBAction func lifetimeAction(_ sender: Any) {
        buy(identifier: IAP.productLifeTime)
    }
    
    @IBAction func monthButtonAction(_ sender: Any) {
        buy(identifier: IAP.productMonth)
    }
    
    @IBAction func skipTrialAction(_ sender: Any) {
        buy(identifier: IAP.productYear)
    }
    
    @objc private func dismissSelf() {
        if let handler = dismissHandler {
            handler()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

extension PremiumViewController {
    func startAnimation() {
//        guard shouldStartAnimation else {
//            return
//        }
//        shouldStartAnimation = false
        let width = faceView.image?.size.width ?? 3880
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(100)
        UIView.setAnimationCurve(.linear)
        UIView.setAnimationRepeatCount(HUGE)
        UIView.setAnimationRepeatAutoreverses(true)
        UIView.setAnimationBeginsFromCurrentState(true)
        faceView.frame = CGRect(x: 0, y: 0, width: width, height: 60)
        UIView.commitAnimations()
    }
    
    private func setupProduct() {
        IAP.productsValue
            .observeOn(Scheduler.backgroundScheduler)
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
        .subscribe(onNext: { [weak self] (map) in
            guard let `self` = self else { return }
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
        
        
        
//        currentProduct.asDriver()
//            .drive(onNext: { [weak self] (p) in
//                guard let `self` = self, let product = p else { return }
//                let actionDescString = product.actionDesc ?? ""
//                let actionDesc = NSMutableAttributedString(string: actionDescString)
//                actionDesc.yy_font = .systemFont(ofSize: 13)
//                actionDesc.yy_color = UIColor.white.withAlphaComponent(0.7)
//                if let validRange = actionDescString.range(of: "free trial") {
//                    let range: NSRange = NSRange(validRange, in: actionDescString)
//                    actionDesc.yy_setFont(.systemFont(ofSize: 13, weight: .black), range: range)
//                    actionDesc.yy_setColor(.white, range: range)
//                }
//                actionDesc.yy_setLineSpacing(8.0, range: actionDesc.yy_rangeOfAll())
//                self.premiumView.actionDesc.attributedText = actionDesc
//
//                switch product.product.info.category {
//                case let .sub(free: f, renewal: _):
//                    if f == nil {
//                        self.premiumView.termsDescLabel.attributedText = self.attributedTerms(product.termsDesc ?? "", isFreeTrial: false)
//                    } else {
//                        self.premiumView.termsDescLabel.attributedText = self.attributedTerms(product.termsDesc ?? "", isFreeTrial: true)
//                    }
//                }
//            })
//            .disposed(by: bag)
        
    }
    
    //for
    func buySelectedProducts() {
        guard let guideView = premiumContainer as? GuideThirdView else {
            return
        }
        buy(identifier: guideView.selectedProductId)
    }
    
    func buy(identifier: String) {
        if let s = self.source {
            Logger.IAP.logPurchase(productId: identifier, source: s)
        }
        
        let removeBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
        isPuchasingState.onNext(true)
        IAP.ProductFetcher.fetchProducts(of: [identifier]) { [weak self] (error, productMap) in
            guard let product = productMap[identifier] else {
                self?.isPuchasingState.onNext(false)
                DispatchQueue.main.async {
                    removeBlock()
                }
                if let s = self?.source {
                    Logger.IAP.logPurchaseFailByIdentifier(identifier: identifier, source: s)
                }
                return
            }
            IAP.ProductDealer.pay(product, onState: { [weak self] (state, error) in
                cdPrint("ProductDealer state: \(state.rawValue)")
                switch state {
                case .purchased, .restored:
                    Settings.shared.isProValue.value = true
                    Defaults[\.purchasedItemsKey] = identifier
                    self?.isPuchasingState.onNext(false)
                    if let s = self?.source {
                        Logger.IAP.logPurchaseResult(product: product.skProduct, source: s, isSuccess: true)
                    }
                    DispatchQueue.main.async { [weak self] in
                        removeBlock()
                        self?.dismissSelf()
                    }
                case .failed:
                    self?.isPuchasingState.onNext(false)
                    NSLog("Purchase failed")
                    DispatchQueue.main.async {
                        removeBlock()
                    }
                    if let s = self?.source {
                        Logger.IAP.logPurchaseResult(product: product.skProduct, source: s, isSuccess: false)
                    }
                default:
                    break
                }
            })
        }
    }
    
    func bindSubviewEvent() {
        premiumContainer.closeHandler = { [weak self] in
            self?.dismissSelf()
        }
        
        premiumContainer.policyHandler = { [weak self] in
            self?.open(urlSting: "https://walkietalkie.live/policy.html")
        }
        
        premiumContainer.buyProductHandler = { [weak self] identifier in
            self?.buy(identifier: identifier)
        }
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
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
//        startAnimation()
        
        if style == .default {
            premiumContainer = PremiumContainer()
        } else {
            premiumContainer = GuideThirdView()
        }
        view.addSubview(premiumContainer)
        premiumContainer.snp.makeConstraints { maker in
            maker.left.right.top.bottom.equalToSuperview()
        }
    }
}
