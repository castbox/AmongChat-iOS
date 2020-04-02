//
//  AppDelegate.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window?.backgroundColor = UIColor(hex: 0x141414)
        RtcManager.shared.initialize()
        RtmManager.shared.initialize()
        FirebaseApp.configure()
        return true
    }


    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        cdPrint("open url: \(url)")
        let scheme = url.scheme

//        if scheme == "fb377451879542911" {
//            // 如果facebook能处理url, 交给facebook处理
//            // - Returns: YES if the url was intended for the Facebook SDK, NO if not.
//            // Facebook登录会交给FBSDK处理
//            if ApplicationDelegate.shared.application(app, open: url, options: options) {
//                return true
//            } else {
//                // 如果facebook不能处理url, 自行处理
////                let parsedURL = AppLinkURL(url: url)
//                guard let parsedURL = BFURL(url: url) else { return false }
//                guard let targetURL = parsedURL.targetQueryParameters["target_url"] as? String else { return false }
//                Routes.handle(targetURL)
//            }
//
//        } else if scheme == "com.googleusercontent.apps.784083819200-n8hb7qfat2mnlrnk7p3lds56ddai1o5o" {
//            //google
//            return GIDSignIn.sharedInstance().handle(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
//
//        } else if scheme?.lowercased() == "twitterkit-eephigkjbavfgupdz2y47jnow" {
//            // twitter
//            return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
//        } else if scheme == "cuddlelive" {
//            let parsedURL = AppLinkURL(url: url)
//            guard let parsedURL = BFURL(url: url) else { return false }
//            Routes.handle(parsedURL.targetURL)
//        } else {
//            // firebase
//            FirebaseAnalytics.Analytics.handleOpen(url)
//        }
        return FireLink.handle(dynamicLink: url) { url in
            print("url: \(url)")
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        FirebaseAnalytics.Analytics.handleUserActivity(userActivity)

        switch userActivity.activityType {
        case NSUserActivityTypeBrowsingWeb:
            guard let url = userActivity.webpageURL else { return false}
//            return Routes.handle(url)
            return FireLink.handle(dynamicLink: url) { url in
                print("url: \(url)")
            }
        default:
            // not supported yet
            return false
        }
    }
}

