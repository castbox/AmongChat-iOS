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
        case likeGuide
    }

    @IBOutlet weak var lifeTimeButton: UIButton!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var freetrielButton: UIButton!
    
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!

    private lazy var yearButton: WalkieButton = {
        let btn = WalkieButton(type: .custom)
        btn.layer.cornerRadius = 28
        btn.backgroundColor = .white
        btn.addTarget(self, action: #selector(onYearButton), for: .primaryActionTriggered)
        return btn
    }()
    private lazy var iapTipsLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 12)
        lb.isHidden = true
        return lb
    }()
    private var productMaps: [String: IAP.Product] = [:]
    
    var gradientLayer: CAGradientLayer!
    var source: Logger.IAP.ActionSource?
    var premiumContainer: PremiumContainerable!
    var style: ContainerStyle = .default
    var dismissHandler: ((_ purchased: Bool) -> Void)?
    var didSelectProducts: (String) -> Void = { _ in }
    
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
        setupProduct()
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
    
    private func dismissSelf(purchased: Bool = false) {
        if let handler = dismissHandler {
            handler(purchased)
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
            self.productMaps = map
            self.updateYearButtonTitle()
            })
            .disposed(by: bag)
    }
    
    //for
    func buySelectedProducts() {
        guard Constants.abGroup == .a,
            let guideView = premiumContainer as? GuideFourthView else {
                didSelectProducts(IAP.productYear)
                buy(identifier: IAP.productYear)
            return
        }
        buy(identifier: guideView.selectedProductId)
    }
    
    func buy(identifier: String) {
        
        premiumContainer.selectProduct(id: identifier)
        
        if let s = self.source {
            Logger.IAP.logPurchase(productId: identifier, source: s)
        }
        
        view.isUserInteractionEnabled = false
        let removeHUDBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
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
                        self?.dismissSelf(purchased: true)
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
            if Constants.abGroup == .b  {
                let guideView = GuideFourthView_b()
                guideView.didSelectProducts = { [weak self] pid in
                    self?.didSelectProducts(pid)
                }
                didSelectProducts(guideView.selectedProductId)
                premiumContainer = guideView
                
            } else {
                let guideView = GuideFourthView()
                guideView.didSelectProducts = { [weak self] pid in
                    self?.didSelectProducts(pid)
                }
                didSelectProducts(guideView.selectedProductId)
                premiumContainer = guideView
            }
        }
        view.addSubview(premiumContainer)
        premiumContainer.snp.makeConstraints { maker in
            maker.left.right.top.bottom.equalToSuperview()
        }
        
        if style == .likeGuide {
            view.addSubviews(views: yearButton, iapTipsLabel)
            yearButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-50)
                maker.size.equalTo(CGSize(width: 219, height: 56))
            }
            
            iapTipsLabel.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview().inset(10)
                maker.top.equalTo(yearButton.snp.bottom).offset(8)
            }
        }
    }
    
    private func updateYearButtonTitle() {
        let tryAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: R.font.nunitoBold(size: 18) ?? Font.bigBody.value,
            .kern: 0.5
        ]
        
        let mutableNormalString = NSMutableAttributedString()
        if Constants.abGroup == .b {
            if Settings.shared.isInReview.value {
                var title: String {
                    guard let price = productMaps[IAP.productYear]?.skProduct.localizedPrice else {
                        return "$29.99 / year"
                    }
                    return "\(price) / Year"
                }
                mutableNormalString.append(NSAttributedString(string: title, attributes: tryAttr))
            } else {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumFree3dTrial(), attributes: tryAttr))
            }
            
            if let product = productMaps[IAP.productYear]?.skProduct {
                if Settings.shared.isInReview.value {
                    iapTipsLabel.font = .systemFont(ofSize: 10)
                    iapTipsLabel.text =
                    """
                    A 3-Day Free Trial automatically converts into a paid subscription at the end of the trial period. Recurring billing, cancel any time.
                    """
                } else {
                    iapTipsLabel.text = """
                    3-day free trial. Then \(product.localizedPrice) / Year.
                    Recurring bilking.Cancel any time.
                    """
                }
            }
        } else {
            if Settings.shared.isInReview.value {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideSubscribeTitle(), attributes: tryAttr))
            } else {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumTryTitle(), attributes: tryAttr))
            }
        }
        yearButton.setAttributedTitle(mutableNormalString, for: .normal)
        yearButton.layoutIfNeeded()
    }
    
    @objc
    private func onYearButton() {
        buy(identifier: IAP.productYear)
    }
}
