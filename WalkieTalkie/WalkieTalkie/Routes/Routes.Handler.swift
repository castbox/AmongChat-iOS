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
                        self.handleProfile(profile)
                    case _ as URI.Avatars:
                        self.handleAvatars()
                    case let user as URI.InviteUser:
                        self.handleInviteUser(uid: user.uid)
                    case let group as URI.FansGroup:
                        self.handleFansGroup(group.groupId)
                    case _ as URI.AllNotice:
                        self.handleAllNotice()
                    case let message as URI.DMMessage:
                        self.handleDmMessage(message.uid)
                    case let profileFeed as URI.ProfileFeeds:
                        self.handleProfileFeeds(profileFeed)
                    case let feed as URI.Feeds:
                        self.handleFeeds(feed)
                    case _ as URI.DMInteractiveMessage:
                        self.handleInteractiveMessage()
                    case let group as URI.GroupJoinRequests:
                        self.handleGroupJoinRequests(group.gid)
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
            if let roomViewController = UIApplication.navigationController?.viewControllers.first(where: { $0 is AmongChat.Room.ContainerController }) as? AmongChat.Room.ContainerController {
                roomViewController.requestLeaveRoom()
                //pop to room
                UIApplication.navigationController?.popToRootViewController(animated: false)
            }
            
            guard let roomVc = UIApplication.navigationController?.topViewController as? ViewController else {
                return
            }
            //set to false
            UIApplication.tabBarController?.canShowAvatarGuide = false
            
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
        
        func handleProfile(_ profile: URI.Profile) {
            let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            let uid = profile.uid
            let vc = Social.ProfileViewController(with: uid ?? selfUid, autoOpenChat: profile.openChat)
            if uid == nil || uid == selfUid {
                let navigationVc = NavigationViewController(rootViewController: vc)
                navigationVc.modalPresentationStyle = .overCurrentContext
                UIApplication.tabBarController?.present(navigationVc, animated: true, completion: nil)
            } else {
                UIApplication.topViewController()?.navigationController?.pushViewController(vc)
                
            }
        }
        
        func handleAvatars() {
            let vc = Social.ProfileLookViewController()
            UIApplication.topViewController()?.navigationController?.pushViewController(vc)
        }
        
        func handleInviteUser(uid: String?) {
            guard let uid = uid?.int else {
                return
            }
            UIApplication.appDelegate?.followInvitedUserhandler = {
                //检查
                _ = Request.follow(uid: uid, type: "follow")
                    .subscribe(onSuccess: { success in
                        if success, let controller = UIApplication.topViewController()  {
                            controller.view.raft.autoShow(.text(R.string.localizable.followInvitedSuccess()), interval: 3)
                        }
                    }, onError: { (error) in 
                        cdPrint("handleInviteUser error:\(error.localizedDescription)")
                    })
                
            }
            UIApplication.appDelegate?.followInvitedUserhandler?()
            UIApplication.appDelegate?.followInvitedUserhandler = nil
        }
        
        func handleFollowers() {
            
        }
        
        func handleFansGroup(_ groupId: String) {
            //检查是否开播
            let loadingHandler = UIApplication.topViewController()?.view.raft.show(.loading)
            _ = Request.groupStatus(groupId)
                .subscribe { group in
                    loadingHandler?()
                    guard let group = group, let vc = UIApplication.topViewController() as? WalkieTalkie.ViewController else {
                        UIApplication.topViewController()?.view.raft.autoShow(.text(R.string.localizable.groupDismissedTips()))
                        return
                    }
                    if group.isLiving {
                        vc.enter(group: group)
                    } else {
                        let vc = FansGroup.GroupInfoViewController(groupId: groupId)
                        UIApplication.topViewController()?.navigationController?.pushViewController(vc)
                    }
                } onError: { _ in
                    loadingHandler?()
                }
        }
        
        func handleGroupJoinRequests(_ groupId: String) {
            let vc = FansGroup.GroupInfoViewController(groupId: groupId)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc)
        }
        
        func handleAllNotice() {
            let vc = Notice.AllNoticeViewController()
            UIApplication.topViewController()?.navigationController?.pushViewController(vc)
        }
        
        func handleProfileFeeds(_ profileFeeds: URI.ProfileFeeds) {
            guard let uid = profileFeeds.uid else {
                return
            }
            let vc = Social.ProfileFeedController(with: uid, index: profileFeeds.index ?? 0)
            UIApplication.topViewController()?.navigationController?.pushViewController(vc)
        }
        
        func handleDmMessage(_ uid: String) {
            let loadingHandler = UIApplication.topViewController()?.view.raft.show(.loading)
            _ = DMManager.shared.queryConversation(fromUid: uid)
                .flatMap { item -> Single<Entity.DMConversation?> in
                    if let conversation = item {
                        return .just(conversation)
                    } else {
                        // get user info create conversation
                        return Request.profile(uid.intValue)
                            .flatMap { profile -> Single<Entity.DMConversation?> in
                                guard let dmProfile = profile?.dmProfile else {
                                    return .just(nil)
                                }
                                let message = Entity.DMMessage.emptyMessage(for: dmProfile)
                                return DMManager.shared.add(message: message, action: .add)
                                    .flatMap { _ in
                                        return DMManager.shared.queryConversation(fromUid: uid)
                                    }
                            }
                    }
                }
                .subscribe(onSuccess: { item in
                    loadingHandler?()
                    guard let conversation = item else {
                        return
                    }
                    let vc = ConversationViewController(conversation)
                    UIApplication.topViewController()?.navigationController?.pushViewController(vc)
                }) { Error in
                    loadingHandler?()
                }
        }
        
        func handleInteractiveMessage() {
            let vc = Conversation.InteractiveMessageController()
            UIApplication.topViewController()?.navigationController?.pushViewController(vc)
        }
        
        func handleFeeds(_ feeds: URI.Feeds) {
            checkIfNeedCloseRoom {
                if let pid = feeds.pid {
                    let vc = Feed.TopicListController(with: pid)
                    UIApplication.topViewController()?.navigationController?.pushViewController(vc)
                } else {
                    //change tab
                    UIApplication.navigationController?.popToRootViewController(animated: false)
                    guard let index = UIApplication.tabBarController?.selectedIndex else {
                        return
                    }
                    UIApplication.tabBarController?.setSelectIndex(from: index, to: AmongChat.Home.MainTabController.Tab.video.index)
                }
            }
        }
        
        func checkIfNeedCloseRoom(completionHandler: CallBack?) {
            var alertHandler: CallBack?
            //如果当前有在直播间内，退出后再加入
            if let roomViewController = UIApplication.navigationController?.viewControllers.first(where: { $0 is AmongChat.Room.ContainerController }) as? AmongChat.Room.ContainerController {
                alertHandler = {
                    roomViewController.requestLeaveRoom()
                    //pop to room
                    UIApplication.navigationController?.popToRootViewController(animated: false)
                }
            } else if let groupViewController = UIApplication.navigationController?.viewControllers.first(where: { $0 is AmongChat.GroupRoom.ContainerController }) as? AmongChat.GroupRoom.ContainerController {
                alertHandler = {
                    groupViewController.requestLeaveRoom()
                    //pop to room
                    UIApplication.navigationController?.popToRootViewController(animated: false)
                }
            }

            if let handler = alertHandler {
                UIApplication.topViewController()?.showAmongAlert(title: R.string.localizable.roomPlayVideoTips(), cancelTitle: R.string.localizable.groupRoomNo(), confirmTitle: R.string.localizable.groupRoomYes(), confirmTitleColor: "#FFF000".color(), confirmAction: {
                    handler()
                    completionHandler?()
                })
            } else {
                completionHandler?()
            }
        }
        
        func showWebViewController(urlString: String) {
            guard let url = URL(string: urlString),
                  let controller = UIApplication.topViewController() else { return }
            
            if url.absoluteString.contains("among.chat") {
                WebViewController.pushFrom(controller, url: url, contentType: .normal)
            } else {
                controller.open(url: url)
            }
        }
        
        func handleUndefined(_ url: URL) {
            if !FireLink.handle(dynamicLink: url, completion: { (url, error) in
                Routes.handle(url)
            }) {
//                cdPrint("open url on webpage: \(url.absoluteString)")
                showWebViewController(urlString: url.absoluteString)
            }
        }
        
    }
}

