//
//  AmongChat.Login.MobileViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/19.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension AmongChat.Login {
    
    class MobileViewController: WalkieTalkie.ViewController {
        
        private lazy var navLayoutGuide: UILayoutGuide = {
            let l = UILayoutGuide()
            view.addLayoutGuide(l)
            l.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.height.equalTo(49)
            }
            return l
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            switch style {
            case .tutorial:
                btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
                btn.setImage(R.image.ac_back(), for: .normal)
            case .inAppLogin:
                btn.addTarget(self, action: #selector(onCLoseBtn), for: .primaryActionTriggered)
                btn.setImage(R.image.ac_profile_close()?.withRenderingMode(.alwaysTemplate), for: .normal)
                btn.tintColor = .white
            case .authNeeded:
                btn.addTarget(self, action: #selector(onCLoseBtn), for: .primaryActionTriggered)
                btn.setImage(R.image.ac_profile_close()?.withRenderingMode(.alwaysTemplate), for: .normal)
                btn.tintColor = .black
            }
            return btn
        }()
        
        private lazy var topBg: UIImageView = {
            let i = UIImageView(image: R.image.ac_login_top_bg())
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var topTipLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 22)
            l.textColor = .black
            l.textAlignment = .center
            l.adjustsFontSizeToFitWidth = true
            
            switch style {
            case .tutorial:
                ()
            case .inAppLogin:
                ()
            case .authNeeded(let source):
                
                switch source {
                case .upgradedToPro:
                    let attTxt = NSMutableAttributedString()
                    let attachment = NSTextAttachment()
                    let image = R.image.ac_login_fireworks()
                    let h1Font = R.font.nunitoExtraBold(size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .init(rawValue: UIFont.Weight.bold.rawValue))
                    let h2Font = R.font.nunitoExtraBold(size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .init(rawValue: UIFont.Weight.bold.rawValue))
                    attachment.image = image
                    attachment.bounds = CGRect(origin: CGPoint(x: 0, y: (h1Font.capHeight - (image?.size.height ?? 0)).rounded() / 2), size: image?.size ?? .zero)
                    attTxt.append(NSAttributedString(attachment: attachment))
                    attTxt.append(NSAttributedString(string: R.string.localizable.amongChatLoginCongrat() + "\n", attributes: [NSAttributedString.Key.font : h1Font]))
                    attTxt.append(NSAttributedString(string: R.string.localizable.amongChatLoginAuthTip(R.string.localizable.amongChatLoginAuthSourcePro()), attributes: [NSAttributedString.Key.font : h2Font]))
                    l.attributedText = attTxt
                    l.numberOfLines = 3
                    
                default:
                    l.text = source.tipString
                    l.numberOfLines = 2
                    
                }
                
            }
            
            return l
        }()
        
        private lazy var mobileIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_login_mobile())
            return i
        }()
        
        private lazy var mobileTitle: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 28.scalHValue)
            lb.textColor = .white
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatLoginMobileTitle()
            return lb
        }()
        
        private lazy var mobileInputContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            v.layer.cornerRadius = 24
            let seperator = UIView()
            seperator.backgroundColor = UIColor(hex6: 0xD8D8D8)
            
            let tapView: UIView = {
                let v = UIView()
                v.backgroundColor = .clear
                v.isUserInteractionEnabled = true
                return v
            }()
            
            let regionLabelTap = UITapGestureRecognizer()
            
            regionLabelTap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.showRegionPicker()
                })
                .disposed(by: bag)
            
            tapView.addGestureRecognizer(regionLabelTap)
            
            v.addSubviews(views: tapView, flagLabel, regionLabel, seperator, mobileInputField)
            
            tapView.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.trailing.equalTo(seperator.snp.leading)
            }
            
            flagLabel.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(16)
                maker.centerY.equalTo(mobileInputField)
            }
            
            regionLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(flagLabel.snp.trailing).offset(4)
                maker.centerY.equalTo(mobileInputField)
                maker.trailing.equalTo(seperator.snp.leading).offset(-8)
            }
            
            seperator.snp.makeConstraints { (maker) in
                maker.height.equalTo(27)
                maker.width.equalTo(2)
                maker.leading.equalToSuperview().inset(84)
                maker.centerY.equalToSuperview()
            }
            
            mobileInputField.snp.makeConstraints { (maker) in
                maker.leading.equalTo(seperator.snp.trailing).offset(8)
                maker.trailing.equalToSuperview().inset(16)
                maker.top.bottom.equalToSuperview()
            }
            flagLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            flagLabel.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            regionLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            regionLabel.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            return v
        }()
        
        private lazy var flagLabel: UILabel = {
            let lb = UILabel()
            lb.font = UIFont.systemFont(ofSize: 20)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var regionLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .black
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var mobileInputField: UITextField = {
            let f = MobileInputField(frame: CGRect.zero)
            f.backgroundColor = .clear
            f.borderStyle = .none
            f.keyboardType = .numberPad
            f.textColor = .black
            f.delegate = self
            f.font = R.font.nunitoExtraBold(size: 20)
            f.adjustsFontSizeToFitWidth = true
            f.keyboardAppearance = .dark
            return f
        }()
        
        private lazy var smsTip: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 14)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatLoginSmsTip()
            return lb
        }()
        
        private lazy var nextBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onNextBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.amongChatLoginNext(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.backgroundColor = UIColor(hex6: 0x2B2B2B)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 24
            btn.isEnabled = false
            return btn
        }()
        
        private lazy var moreLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.text = R.string.localizable.amongChatLoginMore()
            return lb
        }()
        
        private lazy var leftSeperator: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor.white.alpha(0.12)
            return v
        }()
        
        private lazy var rightSeperator: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor.white.alpha(0.12)
            return v
        }()
        
        private lazy var facebookButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.addTarget(self, action: #selector(onFacebookButton), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_login_facebook(), for: .normal)
            btn.layer.cornerRadius = 20
            btn.backgroundColor = "#1877F2".color()
            return btn
        }()
        
        private lazy var googleButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.addTarget(self, action: #selector(onGoogleButton), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_login_google(), for: .normal)
            btn.layer.cornerRadius = 20
            btn.backgroundColor = .white
            return btn
        }()
        
        @available(iOS 13.0, *)
        private lazy var appleButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.addTarget(self, action: #selector(onAppleButtonTouched), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_login_apple(), for: .normal)
            btn.layer.cornerRadius = 20
            btn.backgroundColor = .white
            return btn
        }()
        
        private lazy var policyLabel: PolicyLabel = {
            let terms = R.string.localizable.amongChatTermsService()
            let privacy = R.string.localizable.amongChatPrivacyPolicy()
            let text = R.string.localizable.amongChatPrivacyLabel(terms, privacy)

            let lb = PolicyLabel(with: text, privacy: privacy, terms: terms)
            lb.onInteration = { [weak self] targetPath in
                self?.open(urlSting: targetPath)
            }
            return lb
        }()

        private lazy var loginManager = Manager()
        
        var loginHandler: ((Entity.LoginResult?, Error?) -> Void)? = nil
        
        private typealias Region = Entity.Region
        
        private var currentRegion: Region? = nil {
            didSet {
                
                guard let region = currentRegion else {
                    return
                }
                flagLabel.text = region.regionCode.emojiFlag
                regionLabel.text = region.telCode
            }
        }
        
        private var regions: [Region] = []
        
        private let style: LoginStyle
        
        private var loggerSource: String? {
            return style.loggerSource
        }
        
        override var preferredStatusBarStyle: UIStatusBarStyle {
            switch style {
            case .authNeeded:
                if #available(iOS 13.0, *) {
                    return .darkContent
                } else {
                    return .default
                }
            default:
                return .lightContent
            }
        }
        
        init(style: LoginStyle) {
            self.style = style
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            setupEvent()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            
            guard let touches = event?.allTouches else {
                return
            }
            
            for touch in touches {
                if !mobileInputContainer.frame.contains(touch.location(in: view)) {
                    view.endEditing(true)
                    break
                }
            }
        }
        
    }
    
}

extension AmongChat.Login.MobileViewController {
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
    
    @objc
    private func onCLoseBtn() {
        dismiss(animated: true)
    }
    
    @objc
    private func onNextBtn() {
        
        guard let region = currentRegion else {
            return
        }
        
        guard let phone = mobileInputField.text else {
            return
        }
        
        let hudRemoval = view.raft.show(.loading)
        
        let completion = { [weak self] in
            hudRemoval()
            self?.view.isUserInteractionEnabled = true
        }
        
        view.isUserInteractionEnabled = false
        Request.requestSmsCode(telRegion: region.telCode, phoneNumber: phone)
            .subscribe(onSuccess: { [weak self] (response) in
                completion()
                self?.showVerifyCodeView(dataModel: AmongChat.Login.SmsCodeViewController.DataModel(telRegion: region.telCode, phone: phone, secondsRemain: response.data?.expire ?? 60))
                Logger.Action.log(.signin_phone_next_result, category: nil, self?.loggerSource, 0)
            }, onError: { [weak self] (error) in
                Logger.Action.log(.signin_phone_next_result_fail, category: nil, "\(region)\(phone)" + "error: \(error.msgOfError ?? "")")
                completion()
                
                guard let error = (error as? MsgError) else {
                    self?.showAmongAlert(title: R.string.localizable.amongChatCommonError())
                    return
                }

                self?.view.raft.autoShow(.text(error.msg ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
        Logger.Action.log(.signin_clk, category: .phone, loggerSource)
    }
    
    @available(iOS 13.0, *)
    @objc
    private func onAppleButtonTouched() {
        Logger.Action.log(.signin_clk, category: .apple_id, loggerSource)

        let loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginApple(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: {
                loadingRemoval()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.onLoginResult(result, nil)
                if result != nil {
                    Logger.Action.log(.signin_result, category: .apple_id, self?.loggerSource, 0)
                } else {
                    Logger.Action.log(.signin_result, category: .apple_id, self?.loggerSource, 1)
                }
            }) { [weak self] (error) in
                self?.onLoginResult(nil, error)
                Logger.Action.log(.signin_result_fail, category: .apple_id, error.msgOfError)
            }
            .disposed(by: bag)
    }
    
    @objc
    private func onSnapchatButton() {
        Logger.Action.log(.signin_clk, category: .snapchat, loggerSource)
        let loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginSnapchat(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: {
                loadingRemoval()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.onLoginResult(result, nil)
                if result != nil {
                    Logger.Action.log(.signin_result, category: .snapchat, self?.loggerSource, 0)
                } else {
                    Logger.Action.log(.signin_result, category: .snapchat, self?.loggerSource, 1)
                }
            }, onError: { [weak self] (error) in
                self?.onLoginResult(nil, error)
                Logger.Action.log(.signin_result_fail, category: .snapchat, error.msgOfError)
            })
            .disposed(by: bag)
    }
    
    @objc
    private func onFacebookButton() {
        Logger.Action.log(.signin_clk, category: .facebook, loggerSource)
        let loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginFacebook(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: {
                loadingRemoval()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.onLoginResult(result, nil)
                if result != nil {
                    Logger.Action.log(.signin_result, category: .facebook, self?.loggerSource, 0)
                } else {
                    Logger.Action.log(.signin_result, category: .facebook, self?.loggerSource, 1)
                }
            }, onError: { [weak self] (error) in
                if let msgError = error as? MsgError {
                    
                }
                self?.onLoginResult(nil, error)
                Logger.Action.log(.signin_result_fail, category: .facebook, error.msgOfError)
            })
            .disposed(by: bag)
    }
    
    @objc
    private func onGoogleButton() {
        Logger.Action.log(.signin_clk, category: .google, loggerSource)
        let loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginGoogle(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: {
                loadingRemoval()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.onLoginResult(result, nil)
                if result != nil {
                    Logger.Action.log(.signin_result, category: .google, self?.loggerSource, 0)
                } else {
                    Logger.Action.log(.signin_result, category: .google, self?.loggerSource, 1)
                }
            }, onError: { [weak self] (error) in
                self?.onLoginResult(nil, error)
                Logger.Action.log(.signin_result_fail, category: .google, error.msgOfError)
            })
            .disposed(by: bag)
    }

}

extension AmongChat.Login.MobileViewController {
    
    private func onLoginResult(_ result: Entity.LoginResult?, _ error: Error?) {
        if let error = error {
            if let nsError = error as? NSError,
               nsError.code == AmongChat.Login.cancelErrorCode {
                Logger.Action.log(.login_result, category: .fail, "cancel")
            } else {
                if let msgError = error as? MsgError, let uri = msgError.uri {
                    Routes.handle(uri)
                    return
                }
                Logger.Action.log(.login_result, category: .fail, error.localizedDescription)
            }
            view.raft.autoShow(.text(error.localizedDescription), userInteractionEnabled: false)
            return
        }
        loginHandler?(result, error)
    }
    
    private func setupLayout() {
        
        var thirdPartyBtns = [facebookButton, googleButton]
        
        if #available(iOS 13.0, *) {
            thirdPartyBtns.insert(appleButton, at: 1)
        }
        
        let btnStack = UIStackView(arrangedSubviews: thirdPartyBtns,
                                   axis: .horizontal,
                                   spacing: 40,
                                   distribution: .equalSpacing)
        
        view.addSubviews(views: backBtn, mobileTitle, mobileInputContainer, smsTip, nextBtn,
                         moreLabel, leftSeperator, rightSeperator, btnStack, policyLabel)
        setupBackBtnLayout()
        setupTopTipLayout()
        setupTitleLayout()
        
        btnStack.arrangedSubviews.forEach { $0.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(40)
        }}
        
        mobileInputContainer.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.height.equalTo(48)
            maker.top.equalTo(navLayoutGuide.snp.bottom).offset(Frame.Scale.height(221))
        }
        
        smsTip.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.top.equalTo(mobileInputContainer.snp.bottom).offset(12)
        }
        
        nextBtn.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.height.equalTo(48)
            maker.top.equalTo(smsTip.snp.bottom).offset(Frame.Scale.height(60))
        }
        
        policyLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(Frame.Scale.width(30))
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-Frame.Scale.height(12))
        }
        
        btnStack.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(policyLabel.snp.top).offset(-Frame.Scale.height(20))
        }
        
        moreLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(btnStack.snp.top).offset(-12.scalHValue)
        }
        
        leftSeperator.snp.makeConstraints { (maker) in
            maker.height.equalTo(1)
            maker.centerY.equalTo(moreLabel)
            maker.leading.equalToSuperview().inset(30)
            maker.trailing.equalTo(moreLabel.snp.leading).offset(-12)
        }
        
        rightSeperator.snp.makeConstraints { (maker) in
            maker.height.equalTo(1)
            maker.centerY.equalTo(moreLabel)
            maker.trailing.equalToSuperview().inset(30)
            maker.leading.equalTo(moreLabel.snp.trailing).offset(12)
        }
    }
    
    private func setupTopTipLayout() {
        
        switch style {
        case .authNeeded(let source):
            view.insertSubview(topBg, belowSubview: backBtn)
            view.addSubviews(views: topTipLabel)
            
            let spaceLayoutGuide = UILayoutGuide()
            view.addLayoutGuide(spaceLayoutGuide)
            spaceLayoutGuide.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topTipLabel.snp.bottom)
                maker.bottom.equalTo(mobileTitle.snp.top)
            }
            
            topTipLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(30)
                maker.top.equalTo(navLayoutGuide.snp.bottom).offset(source == .upgradedToPro ? 0 : (Frame.Screen.height < 812 ? 0 : 8))
            }
            
            topBg.snp.makeConstraints { (maker) in
                maker.top.lessThanOrEqualToSuperview().offset(0)
                maker.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(spaceLayoutGuide.snp.centerY)
            }
            
            topTipLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .vertical)
            

        default:
            ()
        }
        
    }
    
    private func setupBackBtnLayout() {
        
        switch style {
        case .tutorial:
            backBtn.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(20)
                maker.centerY.equalTo(navLayoutGuide)
                maker.width.height.equalTo(24)
            }
            
        case .inAppLogin, .authNeeded:
            backBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(20)
                maker.centerY.equalTo(navLayoutGuide)
                maker.width.height.equalTo(24)
            }
            
        }
        
    }
    
    private func setupTitleLayout() {
        switch style {
        case .tutorial, .inAppLogin:
            view.addSubviews(views: mobileIcon)
            mobileIcon.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(navLayoutGuide.snp.bottom).offset(24.scalHValue)
            }
            
            mobileTitle.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(30)
                maker.top.equalTo(mobileIcon.snp.bottom).offset(8)
            }
            
        case .authNeeded:
            mobileTitle.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(30)
                maker.bottom.equalTo(mobileInputContainer.snp.top).offset(-12)
            }
        }
    }
    
    private func setupData() {
        
        Observable<[Region]>.create { (subscriber) -> Disposable in
            DispatchQueue.global().async {
                guard let fileURL = R.file.mobileRegionsJson(),
                      let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
                      let regions = try? JSONDecoder().decodeAnyData([Region].self, from: data),
                      regions.count > 0 else {
                    subscriber.onNext([Region.default])
                    return
                }
                subscriber.onNext(regions.sorted(by: \.region))
            }
            return Disposables.create()
        }
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onNext: { [weak self] (regions) in
            self?.currentRegion = regions.first(where: { $0.regionCode == Constants.countryCode }) ?? Region.default
            self?.regions = regions
        })
        .disposed(by: bag)
        
    }
    
    private func setupEvent() {
        
        mobileInputField.rx.text
            .subscribe(onNext: { [weak self] (str) in
                
                if let str = str,
                   str.count > 6 {
                    self?.nextBtn.isEnabled = true
                    self?.nextBtn.backgroundColor = UIColor(hex6: 0xFFF000)
                } else {
                    self?.nextBtn.isEnabled = false
                    self?.nextBtn.backgroundColor = UIColor(hex6: 0x2B2B2B)
                }
                
            })
            .disposed(by: bag)
        
        RxKeyboard.instance.frame
            .drive(onNext: { [weak self](frame) in
                guard let `self` = self else { return }
                
                let overlapped = self.nextBtn.bottom - frame.origin.y
                
                if overlapped > 0 {
                    self.nextBtn.snp.updateConstraints { (maker) in
                        maker.top.equalTo(self.smsTip.snp.bottom).offset(0)
                    }

                } else {
                    self.nextBtn.snp.updateConstraints { (maker) in
                        maker.top.equalTo(self.smsTip.snp.bottom).offset(Frame.Scale.height(60))
                    }
                }
                
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            }).disposed(by: bag)
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { [weak self] (_) in
                Logger.Action.log(.signin_imp, categoryValue: nil, self?.loggerSource)
            })
            .disposed(by: bag)
        
    }
    
    private func showRegionPicker() {
        guard regions.count > 0 else { return }
        
        view.endEditing(true)
        
        let modal = AmongChat.Login.RegionModal(dataSource: regions,
                                                initialRegion: currentRegion ?? Region.default)
        modal.viewHeight = view.height - nextBtn.origin.y + Frame.Height.safeAeraBottomHeight
        modal.selectRegion = { [weak self] (region) in
            self?.currentRegion = region
        }
        modal.showModal(in: self)
    }
    
    private func showVerifyCodeView(dataModel: AmongChat.Login.SmsCodeViewController.DataModel) {
        let vc = AmongChat.Login.SmsCodeViewController(with: dataModel)
        vc.loggerSource = loggerSource
        vc.loginHandler = { [weak self] (result, error) in
            self?.loginHandler?(result, error)
        }
        navigationController?.pushViewController(vc)
    }
}

extension AmongChat.Login.MobileViewController: UITextFieldDelegate {
    
}

fileprivate extension AmongChat.Login.MobileViewController {
    
    class MobileInputField: UITextField {
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            
            if (action == #selector(UIResponderStandardEditActions.paste(_:))) {
                return false
            }
            
            return super.canPerformAction(action, withSender: sender)
        }
        
    }
    
}

fileprivate extension AmongChat.Login.LoginStyle.AuthNeededSource {
    
    var tipString: String? {
        
        switch self {
        case .applyVerified:
            return R.string.localizable.amongChatLoginAuthTipApply()
        case .createChannel:
            return R.string.localizable.amongChatLoginAuthTip(R.string.localizable.amongChatLoginAuthSourceChannel())
        case .editProfile:
            return R.string.localizable.amongChatLoginAuthTip(R.string.localizable.amongChatLoginAuthSourceProfile())
        case .upgradedToPro:
            return nil
        case .chat:
            return R.string.localizable.amongChatLoginAuthTip(R.string.localizable.amongChatLoginAuthSourceChat())
        }
        
    }
    
}
