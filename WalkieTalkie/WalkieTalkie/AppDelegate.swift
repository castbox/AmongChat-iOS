//
//  AppDelegate.swift
//  WalkieTalkie
//
//  Createds by 袁仕崇 on 2020/4/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import Firebase
import MoPub
//import MoPub_AdMob_Adapters
import RxSwift
import RxCocoa
import SwiftyUserDefaults
#if DEBUG
import DoraemonKit
//import CocoaDebug
#endif
import FirebaseInAppMessaging
import FirebaseCrashlytics
import TikTokOpenSDK
import FirebaseDynamicLinks
import Bolts
import Kingfisher
import GoogleSignIn
import SCSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var window: UIWindow? = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .black
        window.makeKeyAndVisible()
        return window
    }()
    
    var tabBarController: UITabBarController? {
        window?.rootViewController as? UITabBarController
    }
    
    var navigationController: NavigationViewController? {
        if let tab = tabBarController {
            return tab.selectedViewController as? NavigationViewController
        } else {
            return window?.rootViewController as? NavigationViewController
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window?.backgroundColor = UIColor(hex: 0x141414)
        
        setGlobalAppearance()
        RtcManager.shared.initialize()
        FirebaseApp.configure()
        updateUserProperty()
//        UserProperty.logUserID(String(Constants.sUserId))
        
        _ = AdsManager.shared
        _ = Reachability.shared
        _ = Automator.shared
        _ = FireStore.shared
        FireRemote.shared.refresh()
//        _ = Social.Module.shared
        
        _ = AdjustAnalytics.sharedInstance
        
        Settings.shared.startObserver()
        setupInitialView()
        
        DispatchQueue.global(qos: .background).async {
            IAP.verifyLocalReceipts()
//            IAP.prefetchProducts()
            
//            if Defaults[\.pushEnabledKey] {
//                PushMgr.shared.reScheduleNotification()
//            }
        }
        _ = FireStore.shared.isInReviewSubject
//            .filter { !$0 }
            .subscribe(onNext: { _ in
                IAP.prefetchProducts()
            })
        // 路由模块待优化
        _ = Routes.shared
        _ = Routes.Handler.shared
        //heart beating
        _ = ChatRoomManager.shared
        //敏感词
        _ = SensitiveWordChecker.default

        // 缓存清理，主要大户是图片，设置为 128 MB 上线
        KingfisherManager.shared.cache.diskStorage.config.sizeLimit = 128 * 1024 * 1024 // 128 MB
        //设置内存缓存失效时间为12h,修复直播间内“闪“的问题
        KingfisherManager.shared.cache.memoryStorage.config.expiration = .seconds(60 * 60 * 24) //12 h

        // end
        TikTokOpenSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        UIApplication.shared.applicationIconBadgeNumber = 0
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.hexString
        cdPrint("didRegisterForRemoteNotificationsWithDeviceToken deviceToken--------------------\(deviceTokenString)")
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        cdPrint("open url: \(url)")
        if url.scheme == Config.scheme  {
            guard let parsedURL = BFURL(url: url) else { return false }
            return Routes.handle(parsedURL.targetURL)
        }
        else if url.absoluteString.hasPrefix("com.googleusercontent.apps") {
            return GIDSignIn.sharedInstance().handle(url)
        } else if TikTokOpenSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[.sourceApplication] as? String, annotation: options[.annotation] ?? "") {
            return true
        } else if SCSDKLoginClient.application(app, open: url, options: options) {
            return true
        }
        return FireLink.handle(dynamicLink: url) { [weak self] url in
            cdPrint("url: \(String(describing: url))")
            guard let url = url else {
                return
            }
            Routes.handle(url)
//            _ = Routes.canHandle(url)
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        FirebaseAnalytics.Analytics.handleUserActivity(userActivity)

        switch userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
            guard let url = userActivity.webpageURL else { return false }
            if url.scheme == Config.scheme  {
                return Routes.handle(url)
            } 
            return FireLink.handle(dynamicLink: url) { [weak self] url in
                cdPrint("url: \(String(describing: url))")
                guard let url = url else {
                    return
                }
                Routes.handle(url)
//                _ = Routes.canHandle(url)
            }
        default:
            // not supported yet
            return false
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        RtcManager.shared.leaveChannel()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Track Installs, updates & sessions(app opens) (You must include this API to enable tracking)
        // your other code here....
        _ = FireStore.shared.appConfigObservable
            .subscribe(onNext: { (cfg) in
                guard cfg.forceUpgrade else {
                    return
                }
                UIApplication.topViewController()?.showAmongAlert(title: nil, message: R.string.localizable.forceUpgradeTip(), confirmTitle: R.string.localizable.alertOk(), confirmAction: {
                    let appID = Constants.appId
                    let urlStr = "https://itunes.apple.com/app/id\(appID)?mt=8" // (Option 2) Open App Review Page
                    
                    guard let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) else { return }
                    
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                })
            })
//        Ad.AppOpenAdManager.shared.tryToPresentAd()
    }
}

extension AppDelegate {
    
    func updateUserProperty() {
        GuruAnalytics.setUserProperty(Constants.deviceID, forName: "device_id")
        GuruAnalytics.setUserProperty(Constants.abGroup.rawValue, forName: "ab_group")
    }
    
//    func migrateUserDefaults() {
//        let room = Defaults[\.channel]
//        let mode = Mode(index: room.isPrivate.int)
//        Defaults.set(channel: room, mode: mode)
//    }
    
//    func setupInitialView(goRoom: Bool) {
////        let rootVc = R.storyboard.main.instantiateInitialViewController()!
//        let rootVc = NavigationViewController(rootViewController: AmongChat.Home.ViewController())
//        let window = UIWindow(frame: UIScreen.main.bounds)
//        window.backgroundColor = .black
//        window.makeKeyAndVisible()
//
//        if goRoom {
//            InAppMessaging.inAppMessaging().messageDisplaySuppressed = false
//            let guide = R.storyboard.guide.guideViewController()!
//            guide.dismissHandler = { [unowned self] in
//                self.window?.replaceRootViewController(rootVc)
//                // 推送服务
//                FireMessaging.shared.requestPermissionIfNotGranted()
//                InAppMessaging.inAppMessaging().messageDisplaySuppressed = true
//            }
//            window.rootViewController = guide
//        } else {
//            window.rootViewController = rootVc
//            // 推送服务
//            FireMessaging.shared.requestPermissionIfNotGranted()
//        }
//        self.window = window
//    }
    
    func setupInitialView() {
        
        let rootVc: UIViewController
        
        let homeVc: (() -> UIViewController) = {
            GuruAnalytics.log(userID: Settings.loginUserId?.string)
            return AmongChat.Home.MainTabController()
        }
        
        let needLogin: Bool = Settings.shared.loginResult.value == nil
        
        if needLogin {
            let loginVc = AmongChat.Login.ViewController()
            let _ = loginVc.loginFinishedSignal
                .take(1)
                .subscribe(onNext: { [weak self] () in
                    self?.window?.replaceRootViewController(homeVc())
                    FireMessaging.shared.requestPermissionIfNotGranted()
                })
            
            rootVc = NavigationViewController(rootViewController: loginVc)
        } else {
            rootVc = homeVc()
            FireMessaging.shared.requestPermissionIfNotGranted()
        }
        
        self.window?.replaceRootViewController(rootVc)
    }
    
    func setGlobalAppearance() {
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: R.font.nunitoBold(size: 16),
        ]
        
        //设置返回按钮图
        UINavigationBar.appearance().backIndicatorImage = R.image.backNor()
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = R.image.backNor()
        UINavigationBar.appearance().tintColor = UIColor.black
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(color: UIColor.white, size: CGSize(width: 1, height: 1)), for: .default)
        UINavigationBar.appearance().isTranslucent = false
    }
}

extension AppDelegate {
    static func handle(uri: String) {
        guard let url = URL(string: uri) else {
            return
        }
        let result = Routes.handle(url)
        print("[AppDelegate] handle url: \(url) result: \(result)")
    }
}

extension UIApplication {
    static var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    static var navigationController: NavigationViewController? {
        appDelegate?.navigationController
    }
    
    static var tabBarController: UITabBarController? {
        appDelegate?.tabBarController
    }
    
    class func topViewController(_ viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        return viewController
    }
}

extension UIWindow {
    func replaceRootViewController(_ vc: UIViewController) {
        vc.modalTransitionStyle = .flipHorizontal
        UIView.transition(with: self, duration: 0.5, options: .transitionCrossDissolve, animations: {
            let oldState = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            self.rootViewController = vc
            UIView.setAnimationsEnabled(oldState)
        }, completion: nil)
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

