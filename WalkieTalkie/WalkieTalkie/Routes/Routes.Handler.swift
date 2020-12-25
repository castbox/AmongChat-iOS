//
//  Routes.Handler.swift
//  Castbox
//
//  Created by ChenDong on 2018/1/16.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation

//import FBSDKCoreKit
//import GoogleSignIn
//import TwitterKit
//import FirebaseAnalytics
import FirebaseDynamicLinks

import RxSwift

extension Routes {
    
    final class Handler {
        
        static let shared = Handler()
        
        private let bag = DisposeBag()
        
        private init() {
            weak var welf = self
            //
            Routes.shared.uriValue()
                .flatMap { item -> Observable<URIRepresentable> in
                    return Observable.just(item)
                        .delay(.fromSeconds(0.5), scheduler: MainScheduler.asyncInstance)
                }
                .subscribe(onNext: { (uri) in
                    guard let `self` = welf else { return }
                    switch uri {
                    case let home as URI.Homepage:
                        self.handleHomepage(home.channelName)
                    case let room as URI.Room:
                        self.handleRoom(room.roomId)
                    case let channel as URI.Channel:
                        self.handleRoom(channel.channelId)
                    case _ as URI.Followers:
                        self.handleFollowers()
                    case let undefined as URI.Undefined:
                        self.handleUndefined(undefined.url)
                        
                    default:
                        cdAssertFailure("should never enter here")
                    }
                })
                .disposed(by: bag)
        }
        
        func handleHomepage(_ channelName: String?) {
            guard let name = channelName,
                let roomVc = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
                return
            }
            UIApplication.navigationController?.popToRootViewController(animated: true)
            roomVc.joinRoom(name)
            Logger.Channel.log(.deeplink, name, value: name.channelType.rawValue)
        }
        
//        func handleChannel(_ channel: URI.Channel) {
//            UIApplication.navigationController?.popToRootViewController(animated: true)
//
//            guard let roomVc = UIApplication.navigationController?.viewControllers.first as? AmongChat.Home.ViewController,
//                  UIApplication.topViewController() is AmongChat.Home.ViewController else {
//                return
//            }
//
//            let name = channel.roomId
//            roomVc.enterRoom(roomId: name, topicId: nil)
////            roomVc.joinRoom(with: name)
//            Logger.Channel.log(.deeplink, name, value: 0)
//        }
        
        func handleRoom(_ roomId: String) {
            UIApplication.navigationController?.popToRootViewController(animated: true)
            
            guard let roomVc = UIApplication.navigationController?.viewControllers.first as? AmongChat.Home.TopicsViewController,
                  UIApplication.topViewController() is AmongChat.Home.TopicsViewController else {
                return
            }
            
            roomVc.enterRoom(roomId: roomId, topicId: nil)
//            roomVc.joinRoom(with: name)
            Logger.Channel.log(.deeplink, roomId, value: 0)
        }
        
        func handleFollowers() {
            guard let nav = UIApplication.navigationController else { return }
            let vc = Social.RelationsViewController(.followerTab)
            nav.pushViewController(vc)
        }
        
        func showWebViewController(urlString: String) {
            guard let url = URL(string: urlString),
            let controller = UIApplication.navigationController?.topViewController else { return }
            controller.open(url: url)
        }
        
        func handleUndefined(_ url: URL) {
            if !FireLink.handle(dynamicLink: url, completion: { (url) in
                Routes.handle(url)
            }) {
                guard !url.absoluteString.contains("cuddlelive.com/share-app") else { return }
                cdPrint("open url on webpage: \(url.absoluteString)")
                showWebViewController(urlString: url.absoluteString)
            }
        }

    }
}

