//
//  ShareManager.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import FirebaseDynamicLinks
import SCSDKCreativeKit
import MessageUI
import TikTokOpenSDK

class ShareManager: NSObject {
    enum ShareType: String, CaseIterable {
        case message
        case whatsapp
        case snapchat
        case ticktock
        case more
    }
    
    static let `default` = ShareManager()
    
    fileprivate lazy var snapAPI = {
        return SCSDKSnapAPI()
    }()
    
    static func shareUrl(for channelName: String?) -> String {
        guard let channelName = channelName,
            let publicName = channelName.publicName else {
            return "https://walkietalkie.live/"
        }
        if channelName.isPrivate {
            return "https://walkietalkie.live/?passcode=\(publicName)"
        }
        return "https://walkietalkie.live/?channel=\(publicName)"
    }
    
    static func makeDynamicLinks(with channel: String?, for type: ShareType, completionHandler: @escaping (String?) -> Void) {
        guard let link = URL(string: shareUrl(for: channel)) else {
            completionHandler(nil)
            return
        }
        let dynamicLinksDomainURIPrefix = "https://walkie.page.link"
        let iosParameters = DynamicLinkIOSParameters(bundleID: "com.talkie.walkie")
        iosParameters.fallbackURL = URL(string: "https://apps.apple.com/app/id1505959099")
        iosParameters.appStoreID = "1505959099"
        
        let androidParameters = DynamicLinkAndroidParameters(packageName: "walkie.talkie.talk")
        androidParameters.fallbackURL = URL(string: "https://play.google.com/store/apps/details?id=walkie.talkie.talk")
        let googleAnalyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: type.googleSource, medium: type.googleMedium, campaign: type.googleCampaign)
        
        let itcAnalyticsParameters = DynamicLinkItunesConnectAnalyticsParameters()
        itcAnalyticsParameters.providerToken = type.iosProviderToken
        itcAnalyticsParameters.campaignToken = type.googleCampaign
        
        let socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        socialMetaTagParameters.title = "Share Walkie Talkie app"
        socialMetaTagParameters.descriptionText = "This link works whether the app is installed or not!"
        let navigationInfoParameters = DynamicLinkNavigationInfoParameters()
        navigationInfoParameters.isForcedRedirectEnabled = true
        
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder?.iOSParameters = iosParameters
        linkBuilder?.androidParameters = androidParameters
        linkBuilder?.analyticsParameters = googleAnalyticsParameters
        linkBuilder?.iTunesConnectParameters = itcAnalyticsParameters
        linkBuilder?.socialMetaTagParameters = socialMetaTagParameters
        linkBuilder?.navigationInfoParameters = navigationInfoParameters
        linkBuilder?.shorten(completion: { url, warnings, error in
            cdPrint("The long URL is: \(url)")
            if let url = url {
                completionHandler(url.absoluteString)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    static func shareTitle(for channelName: String?, dynamicLink: String) -> String? {
        guard let channelName = channelName,
            let publicName = channelName.publicName else {
                return nil
        }
        let deepLink = shareUrl(for: channelName)
        var prefixString: String {
            if channelName.isPrivate {
                return "Hurry ！use passcode: \(publicName) to join our secret channel."
            }
            return "Hey, your friends are waiting for you, join us now"
        }
        
        
        let shareString =
        """
        \(prefixString)
        \(deepLink)

        Enjoy a better experience with the app
        \(dynamicLink)

        Over and out.
        #WalkieTalkieTalktoFriends #WalkieTalkieEmoji
        """
        return shareString
    }
    
    func share(with channelName: String?, type: ShareType, viewController: UIViewController, successHandler: (() -> Void)? = nil) {
        ShareManager.makeDynamicLinks(with: channelName, for: type) { url in
            guard let url = url else {
                successHandler?()
                return
            }
            guard let textToShare = Self.shareTitle(for: channelName, dynamicLink: url) else {
                successHandler?()
                return
            }
            switch type {
            case .whatsapp:
                let urlWhats = "whatsapp://send?text=\(textToShare)"
                guard let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let whatsappURL = URL(string: urlString) else {
                        successHandler?()
                    return
                }
                if UIApplication.shared.canOpenURL(whatsappURL) {
                    UIApplication.shared.open(whatsappURL, options: [:]) { _ in
                        successHandler?()
                    }
                } else {
                    // Cannot open whatsapp
                    successHandler?()
                }
            case .message:
                if MFMessageComposeViewController.canSendText() {
                    let controller = MFMessageComposeViewController()
                    controller.body = textToShare
                    //                controller.recipients = [phoneNumber.text]
                    controller.messageComposeDelegate = self
                    viewController.present(controller, animated: true) {
                        successHandler?()
                    }
                }
            case .snapchat:
                let shareView = SnapChatCreativeShareView(with: channelName ?? "")
                viewController.view.addSubview(shareView)
                guard let imageToShare = shareView.screenshot else {
                    successHandler?()
                    return
                }
                shareView.removeFromSuperview()
                //            let snapPhoto = SCSDKSnapPhoto(image: imageToShare)
                
                /* Sticker to be used in the Snap */
                //            let stickerImage = imageToShare!/* Prepare a sticker image */
                let sticker = SCSDKSnapSticker(stickerImage: imageToShare)
                sticker.width = shareView.width
                sticker.height = shareView.height
                /* Alternatively, use a URL instead */
                // let sticker = SCSDKSnapSticker(stickerUrl: stickerImageUrl, isAnimated: false)
                
                /* Modeling a Snap using SCSDKPhotoSnapContent */
                let snapContent = SCSDKNoSnapContent()
                snapContent.sticker = sticker /* Optional */
                //            snapContent.caption = textToShare /* Optional */
                snapContent.attachmentUrl = url /* Optional */
                
                // Send it over to Snapchat
                
                // NOTE: startSending() makes use of the global UIPasteboard. Calling the method without synchronization
                //       might cause the UIPasteboard data to be overwritten, while the pasteboard is being read from Snapchat.
                //       Either synchronize the method call yourself or disable user interaction until the share is over.
                //                    let removeHandler = viewController.view.raft.show(.loading)
                //            self.view.isUserInteractionEnabled = false
                self.snapAPI.startSending(snapContent) { (error: Error?) in
                    //                        removeHandler()
                    successHandler?()
                    //                self?.view.isUserInteractionEnabled = true
                    //                self?.isSharing = false
                    print("Shared \(String(describing: "url.absoluteString")) on SnapChat.")
                }
            case .more:
                self.showActivity(name: channelName, dynamicLink: url, type: type, viewController: viewController, successHandler: successHandler)
            default:
                ()
            }
        }
    }
    
    private func showActivity(name: String?, dynamicLink: String, type: ShareType, viewController: UIViewController, successHandler: (() -> Void)? = nil) {
        guard let textToShare = Self.shareTitle(for: name, dynamicLink: dynamicLink) else {
            successHandler?()
            return
        }
        let shareView = SnapChatCreativeShareView(with: name)
        viewController.view.addSubview(shareView)
        guard let imageToShare = shareView.screenshot else {
            successHandler?()
            return
        }
        shareView.removeFromSuperview()
        
//        let urlToShare = Self.shareUrl(for: name)
        let items = [textToShare, imageToShare] as [Any]
//        let snapChat = ActivityViewCustomActivity(title: "Snapchat", image: R.image.logo_snapchat()) { [weak viewController] in
//            guard let controller = viewController else { return }
//            //            let snapPhoto = SCSDKSnapPhoto(image: imageToShare)
//
//            /* Sticker to be used in the Snap */
//            //            let stickerImage = imageToShare!/* Prepare a sticker image */
//            let sticker = SCSDKSnapSticker(stickerImage: imageToShare)
//            sticker.width = shareView.width
//            sticker.height = shareView.height
//            /* Alternatively, use a URL instead */
//            // let sticker = SCSDKSnapSticker(stickerUrl: stickerImageUrl, isAnimated: false)
//
//            /* Modeling a Snap using SCSDKPhotoSnapContent */
//            let snapContent = SCSDKNoSnapContent()
//            snapContent.sticker = sticker /* Optional */
//            //            snapContent.caption = textToShare /* Optional */
//            snapContent.attachmentUrl = urlToShare /* Optional */
//
//            // Send it over to Snapchat
//
//            // NOTE: startSending() makes use of the global UIPasteboard. Calling the method without synchronization
//            //       might cause the UIPasteboard data to be overwritten, while the pasteboard is being read from Snapchat.
//            //       Either synchronize the method call yourself or disable user interaction until the share is over.
////            let removeHandler = controller.view.raft.show(.loading)
//            //            self.view.isUserInteractionEnabled = false
//            self.snapAPI.startSending(snapContent) { (error: Error?) in
////                removeHandler()
//                successHandler?()
//                //                self?.view.isUserInteractionEnabled = true
//                //                self?.isSharing = false
//                print("Shared \(String(describing: "url.absoluteString")) on SnapChat.")
//            }
//        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: [])
        activityVC.excludedActivityTypes = [.addToiCloudDrive, .airDrop, .assignToContact, .openInIBooks, .postToLinkedIn, .postToFlickr, .postToTencentWeibo, .postToWeibo, .postToXing, .saveToCameraRoll]
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            successHandler?()
//            if success {
//            }
        }
        viewController.present(activityVC, animated: true, completion: { () -> Void in
            
        })
    }
}

extension ShareManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}


extension ShareManager.ShareType {
    var googleSource: String {
        switch self {
        case .more:
            return "market"
        default:
            return self.rawValue
        }
    }
    
    var googleMedium: String {
        "i_share"
    }

    var googleCampaign: String {
        "\(googleSource)_share"
    }

    var iosProviderToken: String {
        "120002615"
    }
    
    var isAppInstalled: Bool {
        switch self {
        case .snapchat, .whatsapp:
            return UIApplication.shared.canOpenURL(URL(string: "\(rawValue)://")!)
        case .ticktock:
            return TikTokOpenSDKApplicationDelegate.sharedInstance().isAppInstalled()
        default:
            return true
        }
    }
}

