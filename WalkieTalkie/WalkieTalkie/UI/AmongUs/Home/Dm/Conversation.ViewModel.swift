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
    static var voiceFileDirectory: String? {
        let voiceDic = CachesDirectory()+"/voice"
        let (isSuccess, error) = createFolder(folderPath: voiceDic)
        guard isSuccess else {
            cdPrint("error: \(error)")
            return nil
        }
        return voiceDic
    }
    
    static func voiceFilePath(with name: String) -> String? {
        //create doctory
        guard let fold = voiceFileDirectory else {
            return nil
        }
        return fold.appendingPathComponent(name.contains(".aac") ? name: name + ".aac")
    }
    
    static func gifFilePath(with name: String) -> String? {
        //create doctory
        guard let fold = voiceFileDirectory else {
            return nil
        }
        return fold.appendingPathComponent(name.contains(".gif") ? name: name + ".gif")
    }
    
    //relativepath
    static func relativePath(of absolutePath: String) -> String {
        return absolutePath.replacingOccurrences(of: CachesDirectory(), with: "")
    }
    
    static func absolutePath(for relativePath: String) -> String {
        if relativePath.starts(with: "/") {
            return CachesDirectory() + relativePath
        } else {
            return CachesDirectory() + "/" + relativePath
        }
    }
    
}

extension Conversation {
    class MessageCellViewModel {
        let message: Entity.DMMessage
        let height: CGFloat
        let showTime: Bool
        let contentSize: CGSize
        let sendFromMe: Bool
        let dateString: String
        //
        var isPlayingVoice: Bool = false
        
        init(message: Entity.DMMessage, showTime: Bool) {
            self.message = message
            self.showTime = showTime
            self.sendFromMe = message.fromUser.uid == Settings.loginUserId?.int64
            dateString = message.date.timeFormattedForConversation()
            //calculate height
            let maxWidth = Frame.Screen.width - 72 * 2
            
            switch message.body.msgType {
            case .text:
                let textSize = message.body.text?.boundingRect(with: CGSize(width: maxWidth, height: 1000), font: R.font.nunitoBold(size: 16)!) ?? CGSize(width: 0, height: 0)
                contentSize = textSize.ceil
                let topEdge: CGFloat = 18
                var height = contentSize.height + topEdge * 2
                if showTime {
                    height += 27
                }
                self.height = height
            case .gif:
                //最小
                let minWidth: CGFloat = 80
                let gifMaxWidth: CGFloat = 170
                let rawHeight = (message.body.imageHeight?.cgFloat ?? 1)
                let rawWidth = (message.body.imageWidth?.cgFloat ?? 1)
                var gifWidth = rawWidth
                var gifHeight = rawHeight
                if gifWidth > gifMaxWidth {
                    gifWidth = gifMaxWidth
                    gifHeight = gifMaxWidth * rawHeight / rawWidth
                } else if gifWidth < minWidth {
                    gifWidth = minWidth
                    gifHeight = minWidth * rawHeight / rawWidth
                }
                contentSize = CGSize(width: gifWidth, height: gifHeight)
                
                let topEdge: CGFloat = 6
                var height = contentSize.height + topEdge * 2
                if showTime {
                    height += 27
                }
                self.height = height
            case .voice:
                //                let topEdge: CGFloat = 6
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
        
        deinit {
            cdPrint("Conversation.ViewModel.deinit")
        }
        
        
        init(_ conversation: Entity.DMConversation) {
            self.conversation = conversation
            updateProfile()

            let uid = conversation.fromUid
            
            DMManager.shared.observableMessages(for: uid)
                .startWith(())
                .do(onNext: { [weak self] in
                    self?.groupTime = 0
                })
                .flatMap { item -> Single<[Entity.DMMessage]> in
                    return DMManager.shared.messages(for: uid)
                }
                .map { [weak self] items -> [MessageCellViewModel] in
                    guard let `self` = self else { return [] }
                    _ = DMManager.shared.clearUnreadCount(with: self.conversation)
                        .subscribe()
                    return items.map { message -> MessageCellViewModel in
                        self.downloadFileIfNeed(for: message)
                        if self.groupTime == 0 {
                            self.groupTime = message.timestamp
                        }
                        //大余5分钟则显示时间，
                        let showTimeLabel = (self.groupTime - message.timestamp) < 60 * 5
                        if showTimeLabel {
                            self.groupTime = message.timestamp
                        }
                        //auto download
                        return MessageCellViewModel(message: message, showTime: showTimeLabel)
                    }
                    //                    //show time
                }
                .catchErrorJustReturn([])
                .observeOn(MainScheduler.asyncInstance)
                .bind(to: dataSourceReplay)
                .disposed(by: bag)
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
            guard let profile = Settings.loginUserProfile?.dmProfile, let url = media.gifUrl else {
                return .error(MsgError(.sendDmError))
            }
            let messageBody = Entity.DMMessageBody(type: .gif, img: url.absoluteString, imageWidth: media.imageWidth, imageHeight: media.imageHeight)
            let message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: targetUid, unread: false, fromUser: profile, status: .sending)
            return sendMessage(message)
        }
        
        func sendVoiceMessage(duration: Int, filePath: String) -> Single<Bool> {
            guard FileManager.default.fileExists(atPath: filePath) else {
                return .error(MsgError(.sendDmError))
            }
            
            var messageBody = Entity.DMMessageBody(type: .voice, url: "", duration: duration.double, localRelativePath: FileManager.relativePath(of: filePath))
            var message = Entity.DMMessage(body: messageBody, relation: 1, fromUid: self.targetUid, unread: false, fromUser: self.loginUserDmProfile, status: .sending)
            insertOrReplace(message: message)
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
        
        func sendMessage(_ message: Entity.DMMessage) -> Single<Bool> {
            var message = message
            if message.status != .sending {
                message.status = .sending
            }
            insertOrReplace(message: message)
            return Request.sendDm(message: message.body, to: message.fromUid)
                .do(onSuccess: { [weak self] result in
                    message.status = .success
                    self?.insertOrReplace(message: message)
                }, onError: { [weak self] error in
                    message.status = .failed
                    self?.insertOrReplace(message: message)
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
                    self?.insertOrReplace(message: message)
                }) { error in
                    
                }
                .disposed(by: bag)
        }
        
        func clearUnread(_ message: Entity.DMMessage) {
            var newItem = message
            newItem.unread = false
            insertOrReplace(message: newItem)
        }
        
        func deleteAllHistory() -> Single<Void> {
            return DMManager.shared.deleteConversation(of: targetUid)
        }
        
        func insertOrReplace(message: Entity.DMMessage) {
//            groupTime = 0
            DMManager.shared.insertOrReplace(message: message)
        }
        
        func updateProfile() {
            Request.profile(targetUid.intValue)
                .subscribe()
                .disposed(by: bag)
        }
    }
}


extension CGSize {
    var ceil: CGSize {
        CGSize(width: width.ceil, height: height.ceil)
    }
}
