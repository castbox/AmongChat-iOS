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

extension FileManager {
//    ac
}

extension Conversation {
    class MessageCellViewModel {
        let message: Entity.DMMessage
        let height: CGFloat
        let showTime: Bool
        let contentSize: CGSize
        let sendFromMe: Bool
        
        init(message: Entity.DMMessage, showTime: Bool) {
            self.message = message
            self.showTime = showTime
            self.sendFromMe = message.fromUser.uid == Settings.loginUserId?.int64
            //calculate height
            
            switch message.body.msgType {
            case .text:
                let maxWidth = Frame.Screen.width - 72 * 2
            let textSize = message.body.text?.boundingRect(with: CGSize(width: maxWidth, height: 1000), font: R.font.nunitoBold(size: 16)!) ?? CGSize(width: 0, height: 0)
            contentSize = textSize.ceil
            let topEdge: CGFloat = 18
            var height = contentSize.height + topEdge * 2
            if showTime {
                height += 27
            }
            self.height = height
            case .gif:
                self.height = 100
                contentSize = .zero
            case .voice:
//                let topEdge: CGFloat = 6
                let maxWidth = Frame.Screen.width - 72 * 2
                contentSize = CGSize(width: max(100, Double(maxWidth) / 60 * (message.body.duration ?? 0)), height: 36)
                var height: CGFloat = 48
                if showTime {
                    height += 27
                }
                self.height = height
            case .none:
                let maxWidth = Frame.Screen.width - 72 * 2
                contentSize = CGSize(width: Double(maxWidth) / 60 * (message.body.duration ?? 0), height: 36)
                self.height = 0
            }
        }
    }
}

extension Conversation {
    /**
     当天的消息，以每5分钟为一个跨度的显示时间；发送时间间隔大于5分钟显示时间，小于5分钟不显示；
     消息超过1天、小于1周，显示星期+收发消息的时间；
     消息大于1周，显示手机收发时间的日期。
     
     */
    class ViewModel {
        private var conversation: Entity.DMConversation
        
        private var dataSource: [MessageCellViewModel] = []
        
        let dataSourceReplay = BehaviorRelay<[MessageCellViewModel]>(value: [])
        
        private let bag = DisposeBag()
        
        //分级时间
        private var groupTime: Double = 0
        
        private var downloadTasks: [String: Entity.DMMessage] = [:]
        
        var targetUid: String {
            conversation.fromUid
        }
        
        var loginUserDmProfile: Entity.DMProfile {
            Settings.loginUserProfile!.dmProfile
        }

        
        init(_ conversation: Entity.DMConversation) {
            self.conversation = conversation
            let uid = conversation.fromUid
            
            DMManager.shared.observableMessages(for: uid)
                .startWith(())
                .flatMap { item -> Single<[Entity.DMMessage]> in
                    return DMManager.shared.messages(for: uid)
                }
                .map { [weak self] items -> [MessageCellViewModel] in
                    guard let `self` = self else { return [] }
                    return items.map { message -> MessageCellViewModel in
                        self.downloadFileIfNeed(for: message)
                        
                        if self.groupTime == 0 {
                            self.groupTime = message.timestamp
                        }
                        //大余5分钟则显示时间，
                        let showTimeLabel = (self.groupTime - message.timestamp) > 60 * 5
                        if showTimeLabel {
                            self.groupTime = message.timestamp
                        }
                        //auto download
                        return MessageCellViewModel(message: message, showTime: showTimeLabel)
                    }
//                    //show time
                }
                .observeOn(MainScheduler.asyncInstance)
                .bind(to: dataSourceReplay)
                .disposed(by: bag)
            
            //
            _ = DMManager.shared.clearUnreadCount(with: conversation)
                .subscribe()
        }
        
        func sendMessage(_ text: String) {
            guard let profile = Settings.loginUserProfile?.dmProfile else {
                return
            }
            let messageBody = Entity.DMMessageBody(type: .text, url: nil, duration: nil, text: text)
            let message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: profile, status: .sending)
            DMManager.shared.insertOrReplace(message: message)
            sendMessage(message)
        }
        
        func sendVoiceMessage(duration: Int, filePath: String) -> Single<Bool> {
            let url = Bundle.main.url(forResource: "sample3", withExtension: "aac")!
            let fileManager = FileManager.default
            guard let directoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                return .just(false)
            }
            let filePath = directoryURL.appendingPathComponent("sample3.aac")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.copyItem(atPath: url.path, toPath: filePath.path)
                    //                try R.image.launch_logo()?.pngData()?.write(to: filePath)
                } catch {
                    cdPrint("error: \(filePath.relativePath): \(error))")
                }
            }
            
            var messageBody = Entity.DMMessageBody(type: .voice, url: "", duration: duration.double, localRelativePath: filePath.relativePath)
            var message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: self.targetUid, unread: false, fromUser: self.loginUserDmProfile, status: .sending)
            DMManager.shared.insertOrReplace(message: message)
            return IMManager.shared.getMediaId(with: filePath.path)
                .do(onSuccess: { [weak self] mediaId in
                    guard let `self` = self, let mediaId = mediaId else {
                        return
                    }
                    messageBody.url = mediaId
                    message.body = messageBody
                    self.sendMessage(message)
                })
                .map { $0 != nil }
        }
        
        func sendMessage(_ message: Entity.DMMessage) {
            var message = message
            Request.sendDm(message: message.body, to: message.fromUid)
                .subscribe(onSuccess: { result in
                    message.status = .success
                    DMManager.shared.insertOrReplace(message: message)
                }, onError: { error in
                    message.status = .failed
                    DMManager.shared.insertOrReplace(message: message)
                })
                .disposed(by: bag)
        }
        
        func downloadFileIfNeed(for message: Entity.DMMessage) {
            guard message.isNeedDownloadSource,
                  let mediaId = message.body.url,
                  downloadTasks[mediaId] == nil else {
                return
            }
            //manager
            IMManager.shared.downloadFile(with: message.body)
                .subscribe(onSuccess: { filePath in
                    guard let path = filePath else {
                        return
                    }
                    var message = message
                    message.status = .success
                    message.body.localRelativePath = path.path
                    //update path
                    DMManager.shared.insertOrReplace(message: message)
                }) { error in
                    
                }
                .disposed(by: bag)
        }
        
        func clearUnread(_ message: Entity.DMMessage) {
            var newItem = message
            newItem.unread = false
            DMManager.shared.insertOrReplace(message: newItem)
        }
        
        func deleteAllHistory() -> Single<Void> {
            return DMManager.shared.clearAllMessage(of: targetUid)
        }
    }
}


extension CGSize {
    var ceil: CGSize {
        CGSize(width: width.ceil, height: height.ceil)
    }
}
