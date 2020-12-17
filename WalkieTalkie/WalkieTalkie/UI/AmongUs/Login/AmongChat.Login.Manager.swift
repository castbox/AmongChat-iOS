//
//  AmongChat.Login.Manager.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import AuthenticationServices
import GoogleSignIn
import Firebase

extension AmongChat.Login {
    
    class Manager {
        
        private typealias Entity = Request.Entity
        
        private let bag = DisposeBag()
        
        @available(iOS 13.0, *)
        private lazy var appleProxy: AppleSigninProxy = {
            let p = AppleSigninProxy()
            return p
        }()
        
        private lazy var googleAgent = GoogleAgent()
        
        func logout() {
            // TODO: - logout google
            //            GoogleAgent.signOut()
            //            GoogleAgent.disconnect()
        }
        
        func loginGoogle(from vc: UIViewController) -> Single<Request.Entity.LoginResult?> {
            return signin(via: .google, from: vc)
                .flatMap { [weak self] (result) in
                    guard let `self` = self else {
                        return Observable.just(nil).asSingle()
                    }
                    return self.login(via: .google, token: result.token, secret: nil)
                }
        }
                
        @available(iOS 13.0, *)
        func loginApple(from vc: UIViewController) -> Single<Request.Entity.LoginResult?> {
            return signin(via: .apple, from: vc)
                .flatMap { [weak self] (result) in
                    guard let `self` = self else {
                        return Observable.just(nil).asSingle()
                    }
                    return self.login(via: .apple, token: result.token, secret: nil)
                }
        }
        
        private func signin(via provider: Entity.LoginProvider, from vc: UIViewController) -> Single<ThirdPartySignInResult> {
            switch provider {
            case .google:
                
                return Observable.create { [weak self] (subscriber) -> Disposable in
                    
                    guard let `self` = self else {
                        subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
                        return Disposables.create()
                    }
                    
                    self.googleAgent.signIn(from: vc) { (error, user) in
                        
                        guard error == nil else {
                            subscriber.onError(error!)
                            return
                        }
                        
                        guard let token = user?.authentication.idToken else {
                            subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
                            return
                        }
                        
                        subscriber.onNext(ThirdPartySignInResult(token:token, secret: nil))
                        subscriber.onCompleted()
                    }
                    
                    return Disposables.create()
                }
                .asSingle()
            
                
            case .apple:
                if #available(iOS 13.0, *) {
                    return Observable.create { [weak self] (subscriber) -> Disposable in
                        
                        guard let `self` = self else {
                            subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
                            return Disposables.create()
                        }
                        
                        self.appleProxy.signIn(completion: { (authCode, error) in
                            
                            guard error == nil else {
                                subscriber.onError(error!)
                                return
                            }
                            
                            guard let code = authCode else {
                                subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
                                return
                            }
                            
                            subscriber.onNext(ThirdPartySignInResult(token: code, secret: nil))
                            subscriber.onCompleted()
                        })
                        
                        return Disposables.create()
                    }
                    .asSingle()
                    
                } else {
                    return Observable.create { (subscriber) -> Disposable in
                        subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 0, userInfo: nil))
                        return Disposables.create()
                    }
                    .asSingle()
                }
            }
        }
                
        private func login(via provider: Entity.LoginProvider, token: String? = nil, secret: String? = nil) -> Single<Request.Entity.LoginResult?> {
            return Request.login(via: provider, token: token, secret: secret)
        }
        
    }
    
}

extension AmongChat.Login.Manager {
    private struct ThirdPartySignInResult {
        let token: String?
        let secret: String?
    }
}

extension AmongChat.Login {
    
    @available(iOS 13.0, *)
    class AppleSigninProxy: NSObject {
        
        private var signInHandler: ((_ authCode: String?, _ error: Error?) -> Void)?
        
        func signIn(completion: @escaping (_ authCode: String?, _ error: Error?) -> Void) {
            signInHandler = completion
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [request])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
        
    }
}

@available(iOS 13.0, *)
extension AmongChat.Login.AppleSigninProxy: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let codeData = appleIDCredential.authorizationCode,
            let code = String(data: codeData, encoding: .utf8) else {
            signInHandler?(nil, NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
            signInHandler = nil
            return
        }
        
        signInHandler?(code, nil)
        signInHandler = nil

    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInHandler?(nil, error)
        signInHandler = nil
    }
}

@available(iOS 13.0, *)
extension AmongChat.Login.AppleSigninProxy: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow!
    }
}

extension AmongChat.Login {
    
    class GoogleAgent: NSObject  {
        
        private var completion: ((_ error: Error?, _ user: GIDGoogleUser?)->())?
        
        override init() {
            super.init()
            GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
            GIDSignIn.sharedInstance().delegate = self
        }
        
        func signIn(from vc: UIViewController, _ completion: @escaping (_ error: Error?, _ user: GIDGoogleUser?)->()) {
            
            GIDSignIn.sharedInstance().presentingViewController = vc
            self.completion = completion
            GIDSignIn.sharedInstance().signOut()
            GIDSignIn.sharedInstance().signIn()
        }

        
        func signOut() {
            GIDSignIn.sharedInstance().signOut()
        }
        
        func disconnect() {
            GIDSignIn.sharedInstance().disconnect()
        }
        
    }
}

extension AmongChat.Login.GoogleAgent: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        self.completion?(error, user)
        self.completion = nil

    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
}
