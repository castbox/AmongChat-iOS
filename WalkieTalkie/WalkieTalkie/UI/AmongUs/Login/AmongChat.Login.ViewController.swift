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
        
        private lazy var googleButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.loginGoogle(), for: .normal)
            btn.addTarget(self, action: #selector(onGoogleButton), for: .touchUpInside)
            return btn
        }()
        
        @available(iOS 13.0, *)
        private lazy var appleButton: ASAuthorizationAppleIDButton = {
            let buttonStyle: ASAuthorizationAppleIDButton.Style = .whiteOutline
            let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: buttonStyle)
            button.addTarget(self, action: #selector(onAppleButtonTouched), for: .touchUpInside)
            return button
        }()
        
        private lazy var policyLabel: PolicyLabel = {
            let lb = PolicyLabel()
            return lb
        }()
        
        private lazy var loginManager = Manager()
        
        private var loadingRemoval: (() -> Void)?
        
        private lazy var loginHandler = { [weak self] (result: Request.Entity.LoginResult?, error: Error?) in
            
            self?.loadingRemoval?()
                        
            guard error == nil else {
                self?.view.raft.autoShow(.text(error!.localizedDescription))
                return
            }
            
            guard let result = result else {
                return
            }
            
            Settings.shared.loginResult.value = result
            
            self?.loginFinishedSubject.onNext(())
            
            self?.finish()
        }
        
        private let loginFinishedSubject = PublishSubject<Void>()
        
        var loginFinishedSignal: Observable<Void> {
            return loginFinishedSubject.asObservable()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
    }
    
}

extension AmongChat.Login.ViewController {
    
    // MARK: - UI Action
    
    @available(iOS 13.0, *)
    @objc
    private func onAppleButtonTouched() {
        loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginApple(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: { [weak self] in
                self?.loadingRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.loginHandler(result, nil)
            }) { [weak self] (error) in
                self?.loginHandler(nil, error)
            }
            .disposed(by: bag)
    }
    
    @objc
    private func onGoogleButton() {
        
        loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.loginGoogle(from: navigationController ?? self)
            .observeOn(MainScheduler.asyncInstance)
            .do(onDispose: { [weak self] in
                self?.loadingRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                self?.loginHandler(result, nil)
            }, onError: { [weak self] (error) in
                self?.loginHandler(nil, error)
            })
            .disposed(by: bag)
    }
    
}

extension AmongChat.Login.ViewController {
    
    // MARK: - convinience
    
    private func setupLayout() {
        
        view.addSubviews(views: policyLabel, googleButton)
        
        policyLabel.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-10)
            maker.left.right.equalToSuperview().inset(20)
        }
        
        googleButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-80)
        }
        
        if #available(iOS 13.0, *) {
            view.addSubview(appleButton)
            appleButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(googleButton.snp.top).offset(-20)
            }
        }
        
    }
    
    private func finish() {
        
    }
    
}
