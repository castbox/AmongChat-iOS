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
import MoPub_AdMob_Adapters
import RxSwift
import RxCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var navigationController: NavigationViewController? {
        return window?.rootViewController as? NavigationViewController
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window?.backgroundColor = UIColor(hex: 0x141414)
        setGlobalAppearance()
        RtcManager.shared.initialize()
        FirebaseApp.configure()
        
        _ = AdsManager.shared
        _ = Reachability.shared
        
        DispatchQueue.global(qos: .background).async {
            IAP.verifyLocalReceipts()
            IAP.prefetchProducts()
//            if Defaults[\.pushEnabledKey] {
//                PushMgr.shared.reScheduleNotification()
//            }
        }
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        cdPrint("open url: \(url)")
        if Routes.canHandle(url) {
            return Routes.handle(url)
        }
        return FireLink.handle(dynamicLink: url) { url in
            cdPrint("url: \(url)")
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        FirebaseAnalytics.Analytics.handleUserActivity(userActivity)

        switch userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
            guard let url = userActivity.webpageURL else { return false }
            if Routes.canHandle(url) {
                return handle(url)
            }
            return FireLink.handle(dynamicLink: url) { url in
                cdPrint("url: \(url)")
            }
        default:
            // not supported yet
            return false
        }
    }
    
    func handle(_ uri: URL) -> Bool {
        guard let params = uri.queryParameters else {
            return false
        }
        let home = URI.Homepage(params)
        guard let name = home?.channelName,
            let roomVc = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
            return false
        }
        let removeHandler = roomVc.view.raft.show(.doing(R.string.localizable.channelChecking()))
        FireStore.shared.checkIsValidSecretChannel(name) { result in
            removeHandler()
            if result {
                Logger.Channel.log(.deeplink, name, value: name.channelType.rawValue)
                roomVc.joinChannel(name)
            } else {
                roomVc.view.raft.autoShow(.text(R.string.localizable.channelNotExist()))
            }
        }
        return true
    }
}

extension AppDelegate {
    func setGlobalAppearance() {
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: Font.title.value,
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

extension UIApplication {
    static var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    static var navigationController: NavigationViewController? {
        return (shared.delegate as? AppDelegate)?.navigationController
    }
}


