//
//  AmongChat.Login.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import AuthenticationServices
import RxCocoa
import RxSwift
import SVGAPlayer

extension AmongChat.Login {
    static var isLogedin: Bool {
        guard let value = Settings.shared.loginResult.value else {
            return false
        }
        return !value.isAnonymousUser
    }
    
    static func canDoLoginEvent(autoShowLoginView: Bool = true) -> Bool {
        guard isLogedin else {
            if autoShowLoginView {
                doLogedInEvent()
            }
            return false
        }
        return true
    }
    
    static func doLogedInEvent(_ event: (() -> Void)? = nil) {
        // 自己关注自己 无反应
        guard !isLogedin,
              let viewController = UIApplication.shared.keyWindow?.topViewController() else {
            event?()
            return
        }
        AmongChat.Login.ViewController.present(for: viewController, onFinishHandler: event)
    }
}

extension AmongChat.Login {
    
    class LoginButton: UIButton {
        override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
            return contentRect
        }
        
        override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
            let rect = super.imageRect(forContentRect: contentRect)
            return CGRect(x: 20, y: 12.5, width: rect.width, height: rect.height)
        }
    }
    
    class ViewController: WalkieTalkie.ViewController {
        
        private lazy var logoIV: UIImageView = {
            let iv = UIImageView(image: R.image.ac_login_logo())
            return iv
        }()
//        private lazy var bg = StarsOverlay()
//        private lazy var bg: UIImageView = {
//            let iv = UIImageView(image: R.image.ac_login_bg())
//            iv.contentMode = .scaleAspectFill
//            return iv
//        }()
        
        lazy var bg: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = false
//            player.delegate = self
            player.loops = 1
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        private lazy var snapchatButton: LoginButton = {
            let btn = LoginButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginSignInWithSnapchat(), for: .normal)
            btn.addTarget(self, action: #selector(onSnapchatButton), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_login_snapchat(), for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = "#FFFC00".color()
            return btn
        }()
        
        private lazy var facebookButton: LoginButton = {
            let btn = LoginButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginSignInWithFacebook(), for: .normal)
            btn.addTarget(self, action: #selector(onFacebookButton), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.white, for: .normal)
            btn.setImage(R.image.ac_login_facebook(), for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = "#1877F2".color()
            return btn
        }()
        
        private lazy var googleButton: LoginButton = {
            let btn = LoginButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginSignInWithGoogle(), for: .normal)
            btn.addTarget(self, action: #selector(onGoogleButton), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_login_google(), for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = .white
            return btn
        }()
        
        @available(iOS 13.0, *)
        private lazy var appleButton: LoginButton = {
            let btn = LoginButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginSignInWithApple(), for: .normal)
            btn.addTarget(self, action: #selector(onAppleButtonTouched), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_login_apple(), for: .normal)
            btn.layer.cornerRadius = 24
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
        
        private var loadingRemoval: (() -> Void)?
        
        private lazy var loginHandler = { [weak self] (result: Entity.LoginResult?, error: Error?) in
            
            self?.loadingRemoval?()
                        
            if let error = error {
                if let nsError = error as? NSError,
                   nsError.code == AmongChat.Login.cancelErrorCode {
                    Logger.Action.log(.login_result, category: .fail, "cancel")
                } else {
                    Logger.Action.log(.login_result, category: .fail, error.localizedDescription)
                }
                self?.view.raft.autoShow(.text(error.localizedDescription), userInteractionEnabled: false)
                return
            }
            
            guard let result = result else {
                return
            }
            Logger.Action.log(.login_result, category: .success)
            Settings.shared.loginResult.value = result
            Settings.shared.updateProfile()
            
            self?.finish()
        }
        
        private let loginFinishedSubject = PublishSubject<Void>()
        
        var loginFinishedSignal: Observable<Void> {
            return loginFinishedSubject.asObservable()
        }
        
        static func present(for viewController: UIViewController, onFinishHandler: (() -> Void)?) {
            let loginVc = AmongChat.Login.ViewController()
            let navController = NavigationViewController(rootViewController: loginVc)
            viewController.present(navController, animated: true)
            let _ = loginVc.loginFinishedSignal
                .take(1)
                .subscribe(onNext: { [weak loginVc] in
                    loginVc?.dismiss(animated: true, completion: {
                        onFinishHandler?()
                    })
                })
                .disposed(by: loginVc.bag)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            playBackgroundSvga()
            Logger.Action.log(.login_imp)
        }
        
    }
    
}

extension AmongChat.Login.ViewController {
    
    // MARK: - UI Action
    
    @available(iOS 13.0, *)
    @objc
    private func onAppleButtonTouched() {
        Logger.Action.log(.login_clk, category: .apple_id)

        loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginApple(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: { [weak self] in
                self?.loadingRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.loginHandler(result, nil)
                if result != nil {
                    Logger.Action.log(.login_success, category: .apple_id)
                }
            }) { [weak self] (error) in
                self?.loginHandler(nil, error)
            }
            .disposed(by: bag)
    }
    
    @objc
    private func onSnapchatButton() {
        Logger.Action.log(.login_clk, category: .snapchat)
        loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginSnapchat(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: { [weak self] in
                self?.loadingRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.loginHandler(result, nil)
                if result != nil {
                    Logger.Action.log(.login_success, category: .snapchat)
                }
            }, onError: { [weak self] (error) in
                self?.loginHandler(nil, error)
            })
            .disposed(by: bag)
    }
    
    @objc
    private func onFacebookButton() {
        Logger.Action.log(.login_clk, category: .facebook)
        loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginFacebook(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: { [weak self] in
                self?.loadingRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.loginHandler(result, nil)
                if result != nil {
                    Logger.Action.log(.login_success, category: .facebook)
                }
            }, onError: { [weak self] (error) in
                self?.loginHandler(nil, error)
            })
            .disposed(by: bag)
    }
    
    @objc
    private func onGoogleButton() {
        Logger.Action.log(.login_clk, category: .google)
        loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginGoogle(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: { [weak self] in
                self?.loadingRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.loginHandler(result, nil)
                if result != nil {
                    Logger.Action.log(.login_success, category: .google)
                }
            }, onError: { [weak self] (error) in
                self?.loginHandler(nil, error)
            })
            .disposed(by: bag)
    }
    
}

extension AmongChat.Login.ViewController {
    
    // MARK: - convinience
    func playBackgroundSvga() {
        let parser = SVGAGlobalParser.defaut
        parser.parse(withNamed: "login_bg", in: nil) { [weak self] (item) in
            self?.bg.videoItem = item
            self?.bg.startAnimation()
         } failureBlock: { error in
            debugPrint("error: \(error.localizedDescription ?? "")")
         }
    }
    
    private func setupLayout() {
        
        view.addSubviews(views: bg, logoIV, policyLabel, googleButton, facebookButton/*, snapchatButton*/)
        
        bg.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        logoIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(100)
        }
        
        policyLabel.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-40)
            maker.left.right.equalTo(googleButton)
        }
        
        googleButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(policyLabel.snp.top).offset(-20)
//            maker.width.equalTo(295)
            maker.left.equalTo(30)
            maker.height.equalTo(48)
        }
        
        if #available(iOS 13.0, *) {
            view.addSubview(appleButton)
            appleButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.left.equalTo(30)
                maker.bottom.equalTo(googleButton.snp.top).offset(-20)
//                maker.width.equalTo(295)
                maker.height.equalTo(48)
            }
            
            facebookButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(appleButton.snp.top).offset(-20)
//                maker.width.equalTo(295)
                maker.left.equalTo(30)
                maker.height.equalTo(48)
            }
            
//            snapchatButton.snp.makeConstraints { (maker) in
//                maker.centerX.equalToSuperview()
//                maker.bottom.equalTo(facebookButton.snp.top).offset(-20)
//                maker.width.equalTo(295)
//            maker.left.equalTo(30)
//                maker.height.equalTo(48)
//            }
        } else {
            facebookButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(googleButton.snp.top).offset(-20)
                maker.height.equalTo(48)
                maker.left.equalTo(30)
            }
            
//            snapchatButton.snp.makeConstraints { (maker) in
//                maker.centerX.equalToSuperview()
//                maker.bottom.equalTo(facebookButton.snp.top).offset(-20)
//                maker.width.equalTo(295)
//                maker.height.equalTo(48)
//            }
        }
        
    }
    
    private func finish() {
        
//        #if DEBUG
//        let newUser = true
//        #else
        let newUser = Settings.shared.loginResult.value?.is_new_user ?? false
//        #endif
        
        if newUser {
            let birthdayVC = Social.BirthdaySetViewController()
            birthdayVC.modalPresentationStyle = .fullScreen
            birthdayVC.onCompletion = { [weak self] _ in
                self?.loginFinishedSubject.onNext(())
            }
            present(birthdayVC, animated: true)
        } else {
            loginFinishedSubject.onNext(())
        }
        
    }
    
}
