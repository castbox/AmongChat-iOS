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
import DoraemonKit.DoraemonManager
//import CocoaDebug
#endif
import FirebaseInAppMessaging
import FirebaseCrashlytics
//import TikTokOpenSDK
import FirebaseDynamicLinks
import Bolts
import Kingfisher
import GoogleSignIn
import SCSDKLoginKit
import FBSDKCoreKit
import CastboxDebuger
import IQKeyboardManagerSwift

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AppDelegate]-\(message)")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var window: UIWindow? = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .black
        window.makeKeyAndVisible()
        return window
    }()
    
    var tabBarController: AmongChat.Home.MainTabController? {
        window?.rootViewController as? AmongChat.Home.MainTabController
    }
    
    var navigationController: NavigationViewController? {
        if let tab = tabBarController {
            return tab.selectedViewController as? NavigationViewController
        } else {
            return window?.rootViewController as? NavigationViewController
        }
    }
    
    var isApplicationActiveReplay = BehaviorRelay(value: true)
    
    //invited event block
    var followInvitedUserhandler: CallBack?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window?.backgroundColor = UIColor(hex: 0x141414)
        
        setGlobalAppearance()
        ChatRoomManager.shared.initialize()

        FirebaseApp.configure()

        updateUserProperty()
//        UserProperty.logUserID(String(Constants.sUserId))
        
        _ = AdsManager.shared
        _ = Reachability.shared
        _ = Automator.shared
        FireRemote.shared.refresh()
        
        _ = AdjustAnalytics.sharedInstance
        
        Settings.shared.startObserver()
        Settings.shared.updateDefaultConfig()
        setupInitialView()
        
        IAP.prefetchProducts()
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

        #if DEBUG
        DoraemonManager.shareInstance().showDoraemon()
        DoraemonManager.shareInstance().install()
        #endif
        
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.enable = false
//        // end
//        TikTokOpenSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        removeAllDeliveredNotifications()
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.hexString
        cdPrint("didRegisterForRemoteNotificationsWithDeviceToken deviceToken--------------------\(deviceTokenString)")
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        cdPrint("application open url: \(url)")
        if SCSDKLoginClient.application(app, open: url, options: options) {
            return true
        } else if url.scheme == Config.scheme,
                  let parsedURL = BFURL(url: url),
                  !parsedURL.targetURL.absoluteString.contains("google/link"), //ignore firebase dynamic deep link
                  Routes.handle(parsedURL.targetURL) {
            return true
        }
        else if url.absoluteString.hasPrefix("com.googleusercontent.apps") {
            return GIDSignIn.sharedInstance().handle(url)
        }
//        else if TikTokOpenSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[.sourceApplication] as? String, annotation: options[.annotation] ?? "") {
//            return true
//        }
        else if ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation]) {
            return true
        }
        let result = FireLink.handle(dynamicLink: url) { [weak self] url in
            cdPrint("handle dynamicLink url: \(String(describing: url))")
            guard let url = url else {
                return
            }
            Routes.handle(url)
        }
        guard !result else {
            return true
        }
        return Routes.handle(url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        FirebaseAnalytics.Analytics.handleUserActivity(userActivity)

        switch userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
            guard let url = userActivity.webpageURL else { return false }
            if url.scheme == Config.scheme  {
                return Routes.handle(url)
            }
            
            let result = FireLink.handle(dynamicLink: url) { [weak self] url in
                cdPrint("url: \(String(describing: url))")
                guard let url = url else {
                    return
                }
                Routes.handle(url)
            }
            guard !result else {
                return true
            }
            return Routes.handle(url)
        default:
            // not supported yet
            return false
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        removeAllDeliveredNotifications()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        isApplicationActiveReplay.accept(false)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AgoraRtcManager.shared.leaveChannel()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        isApplicationActiveReplay.accept(true)
        _ = FireRemote.shared.remoteValue()
            .subscribe(onNext: { (cfg) in
                guard cfg.value.forceUpgrade else {
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
    
    func removeAllDeliveredNotifications() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
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
                    PermissionManager.shared.forceRequest(permission: .appTracking, completion: nil)
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
    
    static var tabBarController: AmongChat.Home.MainTabController? {
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

