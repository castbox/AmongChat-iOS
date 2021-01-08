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
import SCSDKLoginKit
import FBSDKCoreKit
import FBSDKLoginKit

extension AmongChat.Login {
    
    static let cancelErrorCode = 999
    
    class Manager {
        
//        private typealias Entity = Request.Entity
        
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
        
        func loginGoogle(from vc: UIViewController) -> Single<Entity.LoginResult?> {
            return signin(via: .google, from: vc)
                .flatMap { [weak self] (result) in
                    guard let `self` = self else {
                        return Observable.just(nil).asSingle()
                    }
                    return self.login(via: .google, token: result.token, secret: nil)
                }
        }
        
        func loginSnapchat(from vc: UIViewController) -> Single<Entity.LoginResult?> {
            return signin(via: .snapchat, from: vc)
                .flatMap { [weak self] (result) in
                    guard let `self` = self else {
                        return Observable.just(nil).asSingle()
                    }
                    return self.login(via: .snapchat, token: result.token, secret: nil)
                }
        }
        
        func loginFacebook(from vc: UIViewController) -> Single<Entity.LoginResult?> {
            return signin(via: .facebook, from: vc)
                .flatMap { [weak self] (result) in
                    guard let `self` = self else {
                        return Observable.just(nil).asSingle()
                    }
                    return self.login(via: .facebook, token: result.token, secret: nil)
                }
        }
                
        @available(iOS 13.0, *)
        func loginApple(from vc: UIViewController) -> Single<Entity.LoginResult?> {
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
                return googleAgent.signIn(from: vc).map { ThirdPartySignInResult(token: $0, secret: nil) }
                
            case .apple:
                if #available(iOS 13.0, *) {
                    return appleProxy.signIn().map { ThirdPartySignInResult(token: $0, secret: nil) }
                } else {
                    return Observable.create { (subscriber) -> Disposable in
                        subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 0, userInfo: nil))
                        return Disposables.create()
                    }
                    .asSingle()
                }
            case .facebook:
                AccessToken.current = nil /// 清空 FBSDKAccessToken
                
                return Observable.create { [weak self] (subscriber) -> Disposable in
                    
                    let loginManager: LoginManager = LoginManager()
                    loginManager.logOut() // 先退出登录
                    
                    loginManager.logIn(permissions: ["public_profile"], from: vc) { (result, error) -> Void in
                        
                        var newError: Error? {
                            if result?.isCancelled == true {
                                return NSError(domain: "chat.among.knife.user", code: cancelErrorCode, userInfo: [NSLocalizedDescriptionKey: R.string.localizable.amongChatLoginSignInCancelled()])
                            }
                            return error
                        }
                        guard let token = result?.token?.tokenString, error == nil else {
                            subscriber.onError(newError ?? NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: [NSLocalizedDescriptionKey: R.string.localizable.amongChatLoginSignInCancelled()]))
                            return
                        }
                        subscriber.onNext(ThirdPartySignInResult(token: token, secret: nil))
                        subscriber.onCompleted()
                    }
                    return Disposables.create()
                }.asSingle()
            case .snapchat:
                return Observable.create { [weak self] (subscriber) -> Disposable in
                    
//                    guard let `self` = self else {
//                        subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
//                        return Disposables.create()
//                    }
//
                    SCSDKLoginClient.login(from: vc) { (sucess, error) in
                        guard error == nil else {
                            subscriber.onError(error!)
                            return
                        }
                        let successBlock = { (response: [AnyHashable: Any]?) in
                            let token = SCSDKLoginClient.getAccessToken()
                            guard !token.isEmpty else {
                                subscriber.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
                                return
                            }
                            subscriber.onNext(ThirdPartySignInResult(token: token, secret: nil))
                            subscriber.onCompleted()
                        }
                        
                        let failureBlock = { (error: Error?, success: Bool) in
                            if let error = error {
                                print(String.init(format: "Failed to fetch user data. Details: %@", error.localizedDescription))
                            }
                        }
                        
                        let queryString = "{me{externalId, displayName}}"
                        SCSDKLoginClient.fetchUserData(withQuery: queryString,
                                                       variables: nil,
                                                       success: successBlock,
                                                       failure: failureBlock)

                    }
                    return Disposables.create()
                }.asSingle()
            }
        }
                
        private func login(via provider: Entity.LoginProvider, token: String? = nil, secret: String? = nil) -> Single<Entity.LoginResult?> {
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
        
        private var signInResultSubject: PublishSubject<String>!
        
        func signIn() -> Single<String> {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [request])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
            signInResultSubject = PublishSubject<String>()
            return signInResultSubject.take(1).asSingle()
        }
        
    }
}

@available(iOS 13.0, *)
extension AmongChat.Login.AppleSigninProxy: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let codeData = appleIDCredential.authorizationCode,
            let code = String(data: codeData, encoding: .utf8) else {
            signInResultSubject.onError(NSError(domain: NSStringFromClass(Self.self), code: 1000, userInfo: nil))
            return
        }
        signInResultSubject.onNext(code)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
//        var newError: Error {
//            guard (error as NSError).code == ASAuthorizationError.Code.canceled.rawValue else {
//                return error
//            }
//            return NSError(domain: "chat.among.knife.user", code: AmongChat.Login.cancelErrorCode, userInfo: [NSLocalizedDescriptionKey: R.string.localizable.amongChatLoginSignInCancelled()])
//        }
        
        signInResultSubject.onError(NSError(domain: "chat.among.knife.user", code: AmongChat.Login.cancelErrorCode, userInfo: [NSLocalizedDescriptionKey: R.string.localizable.amongChatLoginSignInCancelled()]))
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
                
        private var signInResultSubject: PublishSubject<String>!
        
        override init() {
            super.init()
            GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
            GIDSignIn.sharedInstance().delegate = self
        }
                
        func signIn(from vc: UIViewController) -> Single<String> {
            GIDSignIn.sharedInstance().presentingViewController = vc
            GIDSignIn.sharedInstance().signOut()
            GIDSignIn.sharedInstance().signIn()
            signInResultSubject = PublishSubject<String>()
            return signInResultSubject.take(1).asSingle()
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
        
        guard let user = user,
            let token = user.authentication.idToken else {
            
            var newError: Error {
                
                guard let err = error else {
                    return NSError(domain: NSStringFromClass(Self.self), code: -1000, userInfo: [NSLocalizedDescriptionKey: R.string.localizable.amongChatUnknownError()])
                }
                
                guard (err as NSError).code == GIDSignInErrorCode.canceled.rawValue else {
                    return err
                }
                
                return NSError(domain: "chat.among.knife.user", code: AmongChat.Login.cancelErrorCode, userInfo: [NSLocalizedDescriptionKey: R.string.localizable.amongChatLoginSignInCancelled()])
            }
            
            signInResultSubject.onError(newError)
            
            return
        }
        
        signInResultSubject.onNext(token)
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
}
