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
                .observeOn(MainScheduler.asyncInstance)
//                .flatMap { item -> Observable<URIRepresentable> in
//                    return Observable.just(item)
//                        .delay(.fromSeconds(0.5), scheduler: MainScheduler.asyncInstance)
//                }
                .subscribe(onNext: { (uri) in
                    guard let `self` = welf else { return }
                    switch uri {
                    case let home as URI.Homepage:
                        self.handleHomepage(home.channelName)
                    case let channel as URI.Channel:
                        self.handleRoom(channel)
                    case _ as URI.Followers:
                        self.handleFollowers()
                    case let undefined as URI.Undefined:
                        self.handleUndefined(undefined.url)
                    case _ as URI.CreateRoom:
                        self.handleCreateRoom()
                    case _ as URI.Search:
                        self.handleSearch()
                    case let profile as URI.Profile:
                        self.handleProfile(uid: profile.uid)
                    default:
                        cdAssertFailure("should never enter here")
                    }
                })
                .disposed(by: bag)
        }
        
        func handleHomepage(_ channelName: String?) {
//            guard let name = channelName,
//                let roomVc = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
//                return
//            }
            UIApplication.navigationController?.popToRootViewController(animated: true)
//            roomVc.joinRoom(name)
//            Logger.Channel.log(.deeplink, name, value: name.channelType.rawValue)
        }
    
        
        func handleRoom(_ channel: URI.Channel) {
                        
            //如果当前有在直播间内，退出后再加入
            if let roomViewController = UIApplication.navigationController?.viewControllers.first(where: { $0 is AmongChat.Room.ViewController }) as? AmongChat.Room.ViewController {
                roomViewController.requestLeaveRoom()
                //pop to room
                UIApplication.navigationController?.popToRootViewController(animated: false)
            }
            
            guard let roomVc = UIApplication.navigationController?.topViewController as? ViewController else {
                return
            }
            
            var apiSource: ParentApiSource? = nil
            if let source = channel.sourceType {
                apiSource = ParentApiSource(key: source)
            }
            
            roomVc.enterRoom(roomId: channel.channelId, topicId: nil, logSource: ParentPageSource(.link), apiSource: apiSource)
            Logger.Channel.log(.deeplink, channel.channelId, value: 0)
        }
        
        func handleCreateRoom() {
            let vc = AmongChat.CreateRoom.ViewController()
            UIApplication.navigationController?.pushViewController(vc)
        }
        
        func handleSearch() {
            let vc = Search.ViewController()
            UIApplication.navigationController?.pushViewController(vc)
        }
        
        func handleProfile(uid: Int? = nil) {
            let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            let vc = Social.ProfileViewController(with: uid ?? selfUid)
            UIApplication.navigationController?.pushViewController(vc)
        }
        
        func handleFollowers() {
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
                guard !url.absoluteString.contains("among.chat") else { return }
                cdPrint("open url on webpage: \(url.absoluteString)")
                showWebViewController(urlString: url.absoluteString)
            }
        }

    }
}

