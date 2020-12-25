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

extension AmongChat.Login {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private lazy var logoIV: UIImageView = {
            let iv = UIImageView(image: R.image.ac_login_logo())
            return iv
        }()
        
        private lazy var bg: UIImageView = {
            let iv = UIImageView(image: R.image.ac_login_bg())
            iv.contentMode = .scaleAspectFill
            return iv
        }()
        
        private lazy var googleButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginSignInWithGoogle(), for: .normal)
            btn.addTarget(self, action: #selector(onGoogleButton), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_login_google(), for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = .white
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
            return btn
        }()
        
        @available(iOS 13.0, *)
        private lazy var appleButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginSignInWithApple(), for: .normal)
            btn.addTarget(self, action: #selector(onAppleButtonTouched), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_login_apple(), for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = .white
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
            return btn
        }()
        
        private lazy var policyLabel: PolicyLabel = {
            let lb = PolicyLabel()
            lb.onInteration = { [weak self] targetPath in
                self?.open(urlSting: targetPath)
            }
            return lb
        }()
        
        private lazy var loginManager = Manager()
        
        private var loadingRemoval: (() -> Void)?
        
        private lazy var loginHandler = { [weak self] (result: Entity.LoginResult?, error: Error?) in
            
            self?.loadingRemoval?()
                        
            guard error == nil else {
                self?.view.raft.autoShow(.text(error!.localizedDescription), userInteractionEnabled: false)
                return
            }
            
            guard let result = result else {
                return
            }
            
            Settings.shared.loginResult.value = result
            Settings.shared.updateProfile()
            
            self?.finish()
        }
        
        private let loginFinishedSubject = PublishSubject<Void>()
        
        var loginFinishedSignal: Observable<Void> {
            return loginFinishedSubject.asObservable()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
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
    
    private func setupLayout() {
        
        view.addSubviews(views: bg, logoIV, policyLabel, googleButton)
        
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
            maker.width.equalTo(295)
            maker.height.equalTo(48)
        }
        
        if #available(iOS 13.0, *) {
            view.addSubview(appleButton)
            appleButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(googleButton.snp.top).offset(-20)
                maker.width.equalTo(295)
                maker.height.equalTo(48)
            }
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
