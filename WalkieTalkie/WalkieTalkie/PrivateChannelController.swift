//
//  PrivateChannelController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import IQKeyboardManagerSwift
import MoPub

class PrivateChannelController: ViewController {
    let TAG = "PrivateChannelController"
    
    @IBOutlet weak var channelFieldContainer: UIView!
    @IBOutlet private weak var codeField: ChannelNameField!
    @IBOutlet private weak var proButton: UIButton!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var adIconView: UIImageView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var errorTipsLabel: UILabel!
    @IBOutlet weak var dashLineView: UIView!
    
    @IBOutlet private weak var bottomEdgeHeightConstraint: NSLayoutConstraint!
    private var gradientLayer: CAGradientLayer!
    private let dashLayer = CAShapeLayer()
    var joinChannel: (String, Bool) -> Void = { _, _ in }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = true
        Logger.PageShow.log(.secret_channel_create_pop_imp)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        dismiss()
    }
    
    @IBAction func upgradeToProAction(_ sender: Any) {
        guard let premiun = R.storyboard.main.premiumViewController() else {
            return
        }
        premiun.source = .secret_channel_create
        premiun.modalPresentationStyle = .fullScreen
        present(premiun, animated: true, completion: nil)
        Logger.UserAction.log(.update_pro, "secret_channel_create")
    }
}

extension PrivateChannelController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        channelFieldContainer.layer.borderColor = UIColor(hex: 0xDCDCDC)?.cgColor
        errorTipsLabel.text = ""
        return true
    }
}

extension PrivateChannelController {
    
    func dismiss() {
        Logger.PageShow.log(.secret_channel_create_pop_close)
        hideModal()
    }
    
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
            self?.present(alert, animated: true, completion: nil)
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
                            guard let `self` = self else {
//                                    noAdAlertBlock()
                                return true
                            }
                            MPRewardedVideo.presentAd(forAdUnitID: AdsManager.shared.rewardedVideoId, from: self, with: reward)
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
                    self.dismiss()
                })
                .disposed(by: bag)
    }
    
    func configureSubview() {
        
        bottomEdgeHeightConstraint.constant = Frame.Height.safeAeraBottomHeight
        
        let startColor = UIColor(hex: 0x6D95D7)!
        let endColor = UIColor(hex: 0x3023AE)!
        let gradientColors: [CGColor] = [startColor.cgColor, endColor.cgColor]
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        //(这里的起始和终止位置就是按照坐标系,四个角分别是左上(0,0),左下(0,1),右上(1,0),右下(1,1))
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        //设置frame和插入view的layer
        gradientLayer.frame = view.bounds
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

extension PrivateChannelController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 435 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
}

