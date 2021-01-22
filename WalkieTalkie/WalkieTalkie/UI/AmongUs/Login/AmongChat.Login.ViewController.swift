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
import YYText

extension AmongChat.Login {
    
    enum LoginStyle: Equatable {
        case tutorial
        case inAppLogin
        case authNeeded(source: String)
        case unlockPro
    }
    
    static var isLogedin: Bool {
        guard let value = Settings.shared.loginResult.value else {
            return false
        }
        return !value.isAnonymousUser
    }
    
    @discardableResult
    static func canDoLoginEvent(style: LoginStyle, autoShowLoginView: Bool = true) -> Bool {
        guard isLogedin else {
            if autoShowLoginView {
                doLogedInEvent(style: style)
            }
            return false
        }
        return true
    }
    
    static func doLogedInEvent(style: LoginStyle, event: (() -> Void)? = nil) {
        // 自己关注自己 无反应
        guard !isLogedin,
              let viewController = UIApplication.shared.keyWindow?.topViewController() else {
            event?()
            return
        }
        AmongChat.Login.present(style: style, for: viewController, onFinishHandler: event)
    }
    
    static func present(style: LoginStyle, for viewController: UIViewController, onFinishHandler: (() -> Void)?) {
        let loginVc = AmongChat.Login.MobileViewController(style: style)
        let navController = NavigationViewController(rootViewController: loginVc)
        navController.modalPresentationStyle = .fullScreen
        viewController.present(navController, animated: true)
        loginVc.loginHandler = { [weak loginVc] (result, error) in
            
            guard let _ = result else {
                return
            }
            
            loginVc?.dismiss(animated: true, completion: {
                onFinishHandler?()
            })
        }
    }
}

extension AmongChat.Login {
    
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
            player.contentMode = .bottom
            player.isUserInteractionEnabled = false
            return player
        }()
        
        private lazy var startBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatLoginStart(), for: .normal)
            btn.addTarget(self, action: #selector(onStartBtn), for: .primaryActionTriggered)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_login_start(), for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = "#FFFC00".color()
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -1, bottom: 0, right: 1)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: -1)
            return btn
        }()
        
        private lazy var signInLabel: YYLabel = {
            let l = YYLabel()
            
            let signin = R.string.localizable.amongChatLoginSignIn()
            let text = "\(R.string.localizable.amongChatLoginHaveAccount()) \(signin)"
            let signInRange = (text as NSString).range(of: signin)
            
            let attTxt = NSMutableAttributedString(string: text)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let font: UIFont = R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: UIFont.Weight(rawValue: UIFont.Weight.bold.rawValue))
            
            attTxt.addAttributes([NSAttributedString.Key.foregroundColor : UIColor(hex6: 0x898989),
                                  NSAttributedString.Key.font : font,
                                  NSAttributedString.Key.paragraphStyle : paragraphStyle],
                                 range: NSRange(location: 0, length: text.count)
            )
            
            attTxt.addAttributes([NSAttributedString.Key.foregroundColor : UIColor(hex6: 0xFFF000)],
                                 range: signInRange
            )
                    
            l.attributedText = attTxt
            
            l.textTapAction = { [weak self] (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) -> Void in
                if NSIntersectionRange(range, signInRange).length > 0 {
                    self?.signInMore()
                }
            }
            return l
        }()
        
        private lazy var loginManager = Manager()
        
        private lazy var loginHandler = { [weak self] (result: Entity.LoginResult?, error: Error?) in
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
            
            self?.finish()
        }
        
        private let loginFinishedSubject = PublishSubject<Void>()
        
        var loginFinishedSignal: Observable<Void> {
            return loginFinishedSubject.asObservable()
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
    
    @objc
    private func onStartBtn() {
        Logger.Action.log(.login_clk, categoryValue: "start")
        let loadingRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        loginManager.login(via: .device)
            .do(onDispose: {
                loadingRemoval()
            })
            .subscribe(onSuccess: { [weak self] (result) in
                Logger.Action.log(.start_result, categoryValue: nil, nil, (result != nil ? 0 : 1))
                self?.loginHandler(result, nil)
                if result != nil {
                    
                }
            }, onError: { [weak self] (error) in
                Logger.Action.log(.start_result_fail, categoryValue: nil, error.msgOfError)
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
        
        view.addSubviews(views: bg, logoIV, startBtn, signInLabel)
        
        bg.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        logoIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(100)
        }
        
        startBtn.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.height.equalTo(48)
            maker.bottom.equalTo(signInLabel.snp.top).offset(-24)
        }
        
        signInLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-140)
        }
    }
    
    private func signInMore() {
        Logger.Action.log(.login_clk, categoryValue: "signin")
        let vc = AmongChat.Login.MobileViewController(style: .tutorial)
        vc.loginHandler = { [weak self] (result, error) in
            self?.loginHandler(result, error)
        }
        navigationController?.pushViewController(vc)
    }
    
    private func finish() {
        
        #if DEBUG
        let newUser = true
        #else
        let newUser = Settings.shared.loginResult.value?.is_new_user ?? false
        #endif
        
        if newUser {
            let birthdayVC = Social.BirthdaySetViewController()
            birthdayVC.loggerSource = Logger.Action.loginSource(from: .tutorial)
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
