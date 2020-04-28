//
//  SecretChannelContainer.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import JXPagingView
import RxCocoa
import RxSwift
import MoPub

class SecretChannelContainer: XibLoadableView {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var channelFieldContainer: UIView!
    @IBOutlet private weak var codeField: ChannelNameField!
    @IBOutlet private weak var proButton: UIButton!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var adIconView: UIImageView!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var errorTipsLabel: UILabel!
    @IBOutlet private weak var dashLineView: UIView!
    
    private var gradientLayer: CAGradientLayer!
    private let dashLayer = CAShapeLayer()
    private let bag = DisposeBag()
    
    weak var viewController: ViewController?
    
    var joinChannel: (String, Bool) -> Void = { _, _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    override var isFirstResponder: Bool {
        return codeField.isFirstResponder
    }
    
    override func layoutSubviews() {
        gradientLayer.frame = proButton.bounds
        addDashdeBorderLayer()
    }
    
    @IBAction func confirmButtonAction(_ sender: Any) {
        Logger.UserAction.log(.enter_secret)
        guard let name = codeField.text?.uppercased() else {
            return
        }
        //已存在
        guard !isValidChannel(name: name) else {
            //show hud
            channelFieldContainer.layer.borderColor = UIColor(hex: 0xD0021B)?.cgColor
            errorTipsLabel.text = R.string.localizable.privateErrorCode()
            errorTipsLabel.shake()
            return
        }
        //join
        self.joinChannel("_\(name)", false)
    }
    
    @IBAction func upgradeToProAction(_ sender: Any) {
        guard let premiun = R.storyboard.main.premiumViewController() else {
            return
        }
        premiun.source = .secret_channel_create
        premiun.modalPresentationStyle = .fullScreen
        viewController?.present(premiun, animated: true, completion: nil)
        Logger.UserAction.log(.update_pro, "secret_channel_create")
    }
}

extension SecretChannelContainer: JXPagingViewListViewDelegate {
    public func listView() -> UIView {
        return self
    }
    
    public func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> Void) {
        //        self.listViewDidScrollCallback = callback
    }
    
    public func listScrollView() -> UIScrollView {
        return scrollView
    }
    
    public func listDidDisappear() {
        print("listDidDisappear")
    }
    
    public func listDidAppear() {
        print("listDidAppear")
    }
}

extension SecretChannelContainer {
    func isValidChannel(name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        var privateName: String {
            if name.hasPrefix("_") {
                return name
            }
            return "_\(name)"
        }
        //1. 检查是否在私有频道中
        guard !FireStore.shared.secretChannels.contains(where: { $0.name == privateName }) else {
            //2. 有，则提示
            return false
        }
        return true
    }
    
    
    func createUniqueChannelName() -> String {
        let channelName = PasswordGenerator.shared.generate()
        if !isValidChannel(name: channelName) {
            return createUniqueChannelName()
        }
        return channelName
    }
    
    
    func bindSubviewEvent() {
        let networkNotReachAlertBlock = { [weak self] in
            let alert = UIAlertController(title: R.string.localizable.networkNotReachable(), message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: R.string.localizable.toastConfirm(), style: .default, handler: nil))
            self?.viewController?.present(alert, animated: true, completion: nil)
        }
        
        //        let isRewardVideoReady =
        //            AdsManager.shared.isRewardVideoReadyRelay
        //                .asObservable()
        //                .filter { $0 }
        //        let createButtonObservable =
        createButton.rx.tap.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .filter { _ -> Bool in
                guard Reachability.shared.canReachable else {
                    networkNotReachAlertBlock()
                    return false
                }
                return true
        }
        .flatMap { _ -> Observable<Void> in
            Logger.UserAction.log(.create_new)
            guard !Settings.shared.isProValue.value,
                let reward = AdsManager.shared.aviliableRewardVideo else {
                    return Observable.just(())
            }
            
            return Observable.just(())
                .filter({ [weak self] _ in
                    guard let controller = self?.viewController else {
                        //                                    noAdAlertBlock()
                        return true
                    }
                    MPRewardedVideo.presentAd(forAdUnitID: AdsManager.shared.rewardedVideoId, from: controller, with: reward)
                    return true
                })
                .flatMap { _ -> Observable<Void> in
                    return AdsManager.shared.rewardVideoShouldReward.asObserver()
            }
            .do(onNext: { _ in
                AdsManager.shared.requestRewardVideoIfNeed()
            })
                .flatMap { _ -> Observable<Void> in
                    return AdsManager.shared.rewardedVideoAdDidDisappear.asObservable()
            }
        }
        .subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            //create one
            let channelName = self.createUniqueChannelName()
            //check if in private channels
            self.joinChannel("_\(channelName)", true)
        })
            .disposed(by: bag)
    }
    
    func configureSubview() {
        
        //        bottomEdgeHeightConstraint.constant = Frame.Height.safeAeraBottomHeight
        
        let startColor = UIColor(hex: 0x6D95D7)!
        let endColor = UIColor(hex: 0x3023AE)!
        let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        //(这里的起始和终止位置就是按照坐标系,四个角分别是左上(0,0),左下(0,1),右上(1,0),右下(1,1))
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        //设置frame和插入view的layer
        gradientLayer.frame = bounds
        proButton.layer.insertSublayer(gradientLayer, at: 0)
        
        let attributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor.black.alpha(0.3),
            .font: Font.caption1.value
        ]
        codeField.attributedPlaceholder = NSAttributedString(string: R.string.localizable.inputPasscodePlaceholder(), attributes: attributes)
        if Settings.shared.isProValue.value {
            adIconView.isHidden = true
            proButton.isHidden = true
        }
    }
    
    //绘制虚线边框
    func addDashdeBorderLayer(){
        guard dashLayer.superlayer == nil else {
            return
        }
        let path = UIBezierPath(from: CGPoint(x: 0, y: 0), to: CGPoint(x: dashLineView.width, y: 0))
        dashLayer.bounds = dashLineView.bounds
        dashLayer.position = dashLineView.bounds.center
        dashLayer.fillColor = UIColor.clear.cgColor
        dashLayer.strokeColor = UIColor(hex: 0xDCDCDC)?.cgColor
        dashLayer.lineWidth = 0.5
        dashLayer.lineJoin = .round
        dashLayer.lineDashPattern = [6,6]
        //        let path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5)
        dashLayer.path = path.cgPath
        dashLineView.layer.addSublayer(dashLayer)
    }
}
