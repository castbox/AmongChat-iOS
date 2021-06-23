//
//  ConversationViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 08/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Conversation {
    /**
     当天的消息，以每5分钟为一个跨度的显示时间；发送时间间隔大于5分钟显示时间，小于5分钟不显示；
     消息超过1天、小于1周，显示星期+收发消息的时间；
     消息大于1周，显示手机收发时间的日期。
     
     */
    class ViewModel {
        let targetUid: String
        
//        var dataSource: [MessageCellViewModel] {
//            get { dataSourceReplay.value }
//            set { dataSourceReplay.accept(newValue) }
//        }
//
//        let dataSourceReplay = BehaviorRelay<[MessageCellViewModel]>(value: [])
        
        private let bag = DisposeBag()
        
        //分级时间
        private var barrierTime: Double = 0
        
        private var downloadTasks: [String: Entity.DMMessage] = [:]
        
//        var targetUid: String {
//            conversation.fromUid
//        }
        
        var loginUserDmProfile: Entity.DMProfile {
            Settings.loginUserProfile!.dmProfile
        }
        
        deinit {
            cdPrint("Conversation.ViewModel.deinit")
        }
        
        
        init(_ targetUid: String) {
            self.targetUid = targetUid
            
//            let uid = conversation.fromUid
            
//            DMManager.shared.observableMessages(for: uid)
//                .startWith(())
//                .do(onNext: { [weak self] in
//                    self?.barrierTime = 0
//                })
//                .flatMap { item -> Single<[Entity.DMMessage]> in
//                    return DMManager.shared.messages(for: uid)
//                }
//                .map { [weak self] items -> [MessageCellViewModel] in
//                    guard let `self` = self else { return [] }
//                    _ = DMManager.shared.clearUnreadCount(with: self.conversation)
//                        .subscribe()
//                    return items.map { message -> MessageCellViewModel in
//                        self.downloadFileIfNeed(for: message)
//                        if self.barrierTime == 0 {
//                            self.barrierTime = message.timestamp
//                        }
//                        //大余5分钟则显示时间，
//                        let showTimeLabel = self.barrierTime == message.timestamp || ((message.timestamp - self.barrierTime) > 300)
//                        if showTimeLabel {
//                            self.barrierTime = message.timestamp
//                        }
//                        cdPrint("barrierTime: \(self.barrierTime) reduce: \((message.timestamp - self.barrierTime))")
//                        //auto download
//                        return MessageCellViewModel(message: message, showTime: showTimeLabel)
//                    }
//                    //                    //show time
//                }
//                .catchErrorJustReturn([])
//                .observeOn(MainScheduler.asyncInstance)
//                .bind(to: dataSourceReplay)
//                .disposed(by: bag)
            
        }
        
        func loadData(limit: Int, offset: Int = 0) -> Single<[MessageCellViewModel]> {
            //
            barrierTime = 0
//            let limit = dataSource.isEmpty ? Self.requesLimit : dataSource.count
            return DMManager.shared.messages(for: targetUid, limit: limit, offset: offset)
                .map { [weak self] items -> [MessageCellViewModel] in
                    guard let `self` = self else { return [] }
                    _ = DMManager.shared.clearUnreadCount(with: self.targetUid)
                        .subscribe()
                    return items.reversed().map { message -> MessageCellViewModel in
                        self.downloadFileIfNeed(for: message)
                        if self.barrierTime == 0 {
                            self.barrierTime = message.timestamp
                        }
                        //大余5分钟则显示时间，
                        let showTimeLabel = self.barrierTime == message.timestamp || ((message.timestamp - self.barrierTime) > 300)
                        if showTimeLabel {
                            self.barrierTime = message.timestamp
                        }
                        cdPrint("barrierTime: \(self.barrierTime) reduce: \((message.timestamp - self.barrierTime))")
                        //auto download
                        return MessageCellViewModel(message: message, showTime: showTimeLabel)
                    }
                    //                    //show time
                }
                .catchErrorJustReturn([])
                .observeOn(MainScheduler.asyncInstance)
//                .do(onSuccess: { [weak self] models in
//                    guard let `self` = self else { return }
//                    self.dataSource = models
//                })
//                .disposed(by: bag)
        }
        
        func loadMore(limit: Int, offset: Int = 0) -> Single<[MessageCellViewModel]> {
//            let offset = dataSource.count
            return DMManager.shared.messages(for: targetUid, limit: limit, offset: offset)
                .map { [weak self] items -> [MessageCellViewModel] in
                    guard let `self` = self else { return [] }
                    _ = DMManager.shared.clearUnreadCount(with: self.targetUid)
                        .subscribe()
                    return items.reversed().map { message -> MessageCellViewModel in
                        self.downloadFileIfNeed(for: message)
                        //大余5分钟则显示时间，
                        let showTimeLabel = self.barrierTime == message.timestamp || ((message.timestamp - self.barrierTime) > 300)
                        if showTimeLabel {
                            self.barrierTime = message.timestamp
                        }
                        cdPrint("barrierTime: \(self.barrierTime) msg: \(message.timestamp) reduce: \((message.timestamp - self.barrierTime)) msg: \(message.body.text)")
                        //auto download
                        return MessageCellViewModel(message: message, showTime: showTimeLabel)
                    }
                }
                .catchErrorJustReturn([])
                .observeOn(MainScheduler.asyncInstance)
//                .do(onSuccess: { [weak self] models in
//                    guard let `self` = self else { return }
//                    var source = self.dataSource
//                    source.insert(contentsOf: models, at: 0)
//                    self.dataSource = source
//                })

        }
        
        func message(for text: String) -> Entity.DMMessage? {
            guard let profile = Settings.loginUserProfile?.dmProfile else {
                return nil
            }
            let messageBody = Entity.DMMessageBody(type: .text, url: nil, duration: nil, text: text)
            return Entity.DMMessage(body: messageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: profile, status: .sending)
        }
        
        func message(for media: Giphy.GPHMedia) -> Entity.DMMessage? {
            guard let profile = Settings.loginUserProfile?.dmProfile, let url = media.gifUrl else {
                return nil
            }
            let messageBody = Entity.DMMessageBody(type: .gif, img: url.absoluteString, imageWidth: media.imageWidth, imageHeight: media.imageHeight)
            return Entity.DMMessage(body: messageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: profile, status: .sending)
        }
        
        func voiceMessage(with duration: Int, filePath: String) -> Entity.DMMessage? {
            guard FileManager.default.fileExists(atPath: filePath) else {
                return nil
            }
            
            let messageBody = Entity.DMMessageBody(type: .voice, url: "", duration: duration.double, localRelativePath: FileManager.relativePath(of: filePath))
            let message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: self.targetUid, unread: false, fromUser: self.loginUserDmProfile, status: .sending)
            return message
        }
        
        
        func sendMessage(_ text: String) -> Single<Bool> {
            guard let profile = Settings.loginUserProfile?.dmProfile else {
                return .error(MsgError(.sendDmError))
            }
            let messageBody = Entity.DMMessageBody(type: .text, url: nil, duration: nil, text: text)
            let message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: profile, status: .sending)
            return sendMessage(message)
        }

        func sendGif(_ media: Giphy.GPHMedia) -> Single<Bool> {
            guard let url = media.gifUrl else {
                return .error(MsgError(.sendDmError))
            }
            let messageBody = Entity.DMMessageBody(type: .gif, img: url.absoluteString, imageWidth: media.imageWidth, imageHeight: media.imageHeight)
            let message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: loginUserDmProfile, status: .sending)
            return sendMessage(message)
        }

        func sendVoiceMessage(duration: Int, filePath: String) -> Single<Bool> {
            guard FileManager.default.fileExists(atPath: filePath) else {
                return .error(MsgError(.sendDmError))
            }

            var messageBody = Entity.DMMessageBody(type: .voice, url: "", duration: duration.double, localRelativePath: FileManager.relativePath(of: filePath))
            var message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: self.targetUid, unread: false, fromUser: self.loginUserDmProfile, status: .sending)
//            insertOrReplace(message: message)
            update(message: message, action: .add)
            return IMManager.shared.getMediaId(with: filePath)
                .flatMap { [weak self] mediaId in
                    guard let `self` = self, let mediaId = mediaId else {
                        return .error(MsgError(.sendDmError))
                    }
                    messageBody.url = mediaId
                    message.body = messageBody
                    return self.sendMessage(message)
                }
        }

        func sendFeedMessage(with feed: Entity.Feed, text: String, isSuccess: Bool) {
            let feedMessageBody = Entity.DMMessageBody(type: .feed, img: feed.img.absoluteString, imageWidth: feed.widthValue.double, imageHeight: feed.heightValue.double, link: "/feeds/"+feed.pid)
            let feedMessage = Entity.DMMessage(body: feedMessageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: loginUserDmProfile, status: isSuccess ? .success : .failed)
            
            let textMessageBody = Entity.DMMessageBody(type: .text, url: nil, duration: nil, text: text)
            let textMessage = Entity.DMMessage(body: textMessageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: loginUserDmProfile, status: isSuccess ? .success : .failed)

            update(message: feedMessage, action: .add)
            update(message: textMessage, action: .add)
        }
        
        func sendMessage(_ message: Entity.DMMessage, action: DMManager.MessageUpdateAction = .add) -> Single<Bool> {
            var message = message
            if message.status != .sending {
                message.status = .sending
            }
//            insertOrReplace(message: message)
            update(message: message, action: action)
            return Request.sendDm(message: message.body, to: message.fromUid)
                .do(onSuccess: { [weak self] result in
                    message.status = .success
//                    self?.insertOrReplace(message: message)
                    self?.update(message: message, action: .replace)
                }, onError: { [weak self] error in
                    message.status = .failed
//                    self?.insertOrReplace(message: message)
                    self?.update(message: message, action: .replace)
                })
        }
        
        func downloadFileIfNeed(for message: Entity.DMMessage) {
            guard message.isNeedDownloadSource,
                  let mediaId = message.body.url,
                  downloadTasks[mediaId] == nil else {
                return
            }
            //manager
            IMManager.shared.downloadFile(with: message.body)
                .subscribe(onSuccess: { [weak self] filePath in
                    guard let path = filePath else {
                        return
                    }
                    var message = message
                    message.status = .success
                    message.body.localRelativePath = FileManager.relativePath(of: path.path)
                    //update path
//                    self?.insertOrReplace(message: message)
                    self?.update(message: message, action: .replace)
                }) { error in
                    
                }
                .disposed(by: bag)
        }
        
        func clearUnread(_ message: Entity.DMMessage) {
            var newItem = message
            newItem.unread = false
            update(message: newItem, action: .replace)
//            insertOrReplace(message: newItem)
        }
        
        func clearAllMessage() -> Single<Void> {
            return DMManager.shared.clearAllMessage(of: targetUid)
        }
        
        func update(message: Entity.DMMessage, action: DMManager.MessageUpdateAction) {
//            barrierTime = 0
            DMManager.shared.update(message: message, action: action)
        }
    }
}


extension CGSize {
    var ceil: CGSize {
        CGSize(width: width.ceil, height: height.ceil)
    }
}
