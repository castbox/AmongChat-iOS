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
import RxSwift

class ShareManager: NSObject {
    enum ContentType {
        case roomId
        case app
    }
    
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
    
//    static func shareUrl(for channelName: String?) -> String {
//        guard let channelName = channelName,
//            let publicName = channelName.publicName else {
//            return "https://among.chat/"
//        }
//        if channelName.isPrivate {
//            return "https://among.chat/?passcode=\(publicName)"
//        }
//        return "https://among.chat/?channel=\(publicName)"
//    }
    
    static func shareUrl(with roomID: String?) -> String {
        guard let roomID = roomID else {
            return "https://among.chat/"
        }
        return "https://among.chat/room/\(roomID)"
    }
    
    static func makeDynamicLinks(with roomID: String?, for type: ShareType, completionHandler: @escaping (String?) -> Void) {
        guard let link = URL(string: shareUrl(with: roomID)) else {
            completionHandler(nil)
            return
        }
        let dynamicLinksDomainURIPrefix = "https://amongchat.page.link"
        let iosParameters = DynamicLinkIOSParameters(bundleID: Bundle.main.bundleIdentifier!)
        iosParameters.fallbackURL = URL(string: "https://apps.apple.com/app/id1539641263")
        iosParameters.appStoreID = "1539641263"
        
        let androidParameters = DynamicLinkAndroidParameters(packageName: "walkie.talkie.among.us.friends")
        androidParameters.fallbackURL = URL(string: "https://play.google.com/store/apps/details?id=walkie.talkie.among.us.friends")
        let googleAnalyticsParameters = DynamicLinkGoogleAnalyticsParameters(source: type.googleSource, medium: type.googleMedium, campaign: type.googleCampaign)
        
        let itcAnalyticsParameters = DynamicLinkItunesConnectAnalyticsParameters()
        itcAnalyticsParameters.providerToken = type.iosProviderToken
        itcAnalyticsParameters.campaignToken = type.googleCampaign
        
        let socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        socialMetaTagParameters.title = "Share Among Chat app"
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
    
    static func shareTitle(for channelName: String?, topic: AmongChat.Topic = .amongus, dynamicLink: String) -> String? {
//        guard let channelName = channelName,
//            let publicName = channelName.publicName else {
//                return nil
//        }
////        let deepLink = shareUrl(for: channelName)
//        var prefixString: String {
//            if channelName.isPrivate {
//                return "Hurry ！use passcode: \(publicName) to join our secret channel."
//            }
//            return "Hey, your friends are waiting for you, join us now"
//        }
        
        
        let shareString =
        """
        Hey I'm in the AmongUs room in AmongChat! We need 9 more people!!! Tap the link to join: \(dynamicLink)
        """
        return shareString
    }
    
    func share(with roomId: String?, type: ShareType, topic: AmongChat.Topic = .amongus, viewController: UIViewController, successHandler: (() -> Void)? = nil) {
        guard let roomId = roomId else {
            successHandler?()
            return
        }
        
        ShareManager.makeDynamicLinks(with: roomId, for: type) { url in
            guard let url = url else {
                successHandler?()
                return
            }
            guard let textToShare = Self.shareTitle(for: roomId, dynamicLink: url) else {
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
//                let shareView = SnapChatCreativeShareView(with: roomId)
//                viewController.view.addSubview(shareView)
//                guard let imageToShare = shareView.screenshot else {
//                    successHandler?()
//                    return
//                }
//                shareView.removeFromSuperview()
//                //            let snapPhoto = SCSDKSnapPhoto(image: imageToShare)
//
//                /* Sticker to be used in the Snap */
//                //            let stickerImage = imageToShare!/* Prepare a sticker image */
//                let sticker = SCSDKSnapSticker(stickerImage: imageToShare)
//                sticker.width = shareView.width
//                sticker.height = shareView.height
//                /* Alternatively, use a URL instead */
//                // let sticker = SCSDKSnapSticker(stickerUrl: stickerImageUrl, isAnimated: false)
//
//                /* Modeling a Snap using SCSDKPhotoSnapContent */
//                let snapContent = SCSDKNoSnapContent()
//                snapContent.sticker = sticker /* Optional */
//                //            snapContent.caption = textToShare /* Optional */
//                snapContent.attachmentUrl = url /* Optional */
//
//                // Send it over to Snapchat
//
//                // NOTE: startSending() makes use of the global UIPasteboard. Calling the method without synchronization
//                //       might cause the UIPasteboard data to be overwritten, while the pasteboard is being read from Snapchat.
//                //       Either synchronize the method call yourself or disable user interaction until the share is over.
//                //                    let removeHandler = viewController.view.raft.show(.loading)
//                //            self.view.isUserInteractionEnabled = false
//                self.snapAPI.startSending(snapContent) { (error: Error?) in
//                    //                        removeHandler()
//                    successHandler?()
//                    //                self?.view.isUserInteractionEnabled = true
//                    //                self?.isSharing = false
//                    print("Shared \(String(describing: "url.absoluteString")) on SnapChat.")
//                }
            ()
            case .ticktock:
                ()
//                _ = self.createImagesForTikTok(roomId, viewController: viewController)
//                    .observeOn(MainScheduler.asyncInstance)
//                    .subscribe(onNext: { localizlIdentifiers in
//                        guard localizlIdentifiers.count == 2 else {
//                            successHandler?()
//                            return
//                        }
//                        let request = TikTokOpenSDKShareRequest()
//                        request.mediaType = .image
//                        request.localIdentifiers = localizlIdentifiers
////                        request.extraInfo =
//                        request.send { response in
//                            cdPrint(response.debugDescription)
//                            if response.errCode == .success {
//
//                            } else {
//                                //
//                            }
//                            successHandler?()
//
//                        }
//                    })
                
            case .more:
                self.showActivity(name: roomId, dynamicLink: url, type: type, viewController: viewController, successHandler: successHandler)
            }
        }
    }
    
    func showActivity(viewController: UIViewController, successHandler: (() -> Void)? = nil) {
        let items = ["Guys we need more people on AmongChat! It's super fun and matches you with like minded gamers. Tap the link to download now: https://amongchat.page.link/app"] as [Any]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: [])
        activityVC.excludedActivityTypes = [.addToiCloudDrive, .airDrop, .assignToContact, .openInIBooks, .postToLinkedIn, .postToFlickr, .postToTencentWeibo, .postToWeibo, .postToXing, .saveToCameraRoll]
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            successHandler?()
        }
        viewController.present(activityVC, animated: true, completion: nil)
    }
    
    func showActivity(name: String?, dynamicLink: String, type: ShareType, viewController: UIViewController, successHandler: (() -> Void)? = nil) {
        guard let textToShare = Self.shareTitle(for: name, dynamicLink: dynamicLink) else {
            successHandler?()
            return
        }
//        let shareView = SnapChatCreativeShareView(with: name)
//        viewController.view.addSubview(shareView)
//        guard let imageToShare = shareView.screenshot else {
//            successHandler?()
//            return
//        }
//        shareView.removeFromSuperview()
        
//        let items = [textToShare, imageToShare] as [Any]
        let items = [textToShare] as [Any]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: [])
        activityVC.excludedActivityTypes = [.addToiCloudDrive, .airDrop, .assignToContact, .openInIBooks, .postToLinkedIn, .postToFlickr, .postToTencentWeibo, .postToWeibo, .postToXing, .saveToCameraRoll]
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            successHandler?()
//            if success {
//            }
        }
        viewController.present(activityVC, animated: true, completion: nil)
    }
    
//    private func createImagesForTikTok(_ channelName: String, viewController: UIViewController) -> Observable<[String]> {
//        var shareView = TikTokShareView(channelName, content: channelName.isPrivate ? .private_1 : .public_1)
//        viewController.view.addSubview(shareView)
//        guard let imageToShare = shareView.screenshot else {
//            return .just([])
//        }
//        shareView.removeFromSuperview()
//        
//        shareView = TikTokShareView(channelName, content: channelName.isPrivate ? .private_2 : .public_2)
//        viewController.view.addSubview(shareView)
//        guard let image2ToShare = shareView.screenshot else {
//            return .just([])
//        }
//        shareView.removeFromSuperview()
//        //save image to
//        return Observable.zip(PhotoManager.shared.saveImageObserve(imageToShare), PhotoManager.shared.saveImageObserve(image2ToShare))
//            .map { (item1, item2) -> [String] in
//                guard let item1 = item1, let item2 = item2 else {
//                    return []
//                }
//                return [item1, item2]
//            }
//            .subscribeOn(MainScheduler.asyncInstance)
//    }
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
        "1539641263"
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


extension PhotoManager {
    func saveImageObserve(_ image: UIImage) -> Observable<String?> {
        return Observable.create { observer -> Disposable in
            self.save(image) { (localIdentifier, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(localIdentifier)
                }
            }
            return Disposables.create {
                
            }
        }
    }
}