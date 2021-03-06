//
//  Among.Chat.Room.IMManager.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/7.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AgoraRtmKit
import CastboxDebuger
import AudioToolbox

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[IMManager]-\(message)")
}

class IMManager: NSObject {
    private static let systemAgoraUid = Int(99999)

    enum LoginStatus {
        case online, offline
    }
    
    static let shared = IMManager()
    let onlineRelay = BehaviorRelay<LoginStatus>(value: .offline)
    
    private var rtmKit: AgoraRtmKit?
    private var rtmChannel: AgoraRtmChannel?
    private let joinedSubject = BehaviorRelay<Bool>(value: false)
    private let newChannelMessageSubject = PublishSubject<(AgoraRtmMessage, AgoraRtmMember)>()
    private let newPeerMessageSubject = PublishSubject<(AgoraRtmMessage, String)>()
    
    private var loginDisposable: Disposable?
    private let bag = DisposeBag()
    //max login retry twice
    private var retryCount = 2
    
    var newChannelMessageObservable: Observable<ChatRoomMessage> {
        return newChannelMessageSubject.asObservable()
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { (message, member) -> ChatRoomMessage? in
                cdPrint("member: \(member.channelId) \(member.userId) \ntext: \(message.text)")
                guard message.type == .text,
                      let json = message.text.jsonObject(),
                      let messageType = json["message_type"] as? String,
                      let type = ChatRoom.MessageType(rawValue: messageType) else {
                    return nil
                }
                var item: ChatRoomMessage?
                decoderCatcher {
                    switch type {
                    case .text:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.TextMessage.self, from: json) as ChatRoomMessage
//                    case .baseInfo:
//                        item = try JSONDecoder().decodeAnyData(ChatRoom.RoomBaseMessage.self, from: json) as ChatRoomMessage
                    case .joinRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.JoinRoomMessage.self, from: json) as ChatRoomMessage
                    case .leaveRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.LeaveRoomMessage.self, from: json) as ChatRoomMessage
                    case .systemLeave:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.LeaveRoomMessage.self, from: json) as ChatRoomMessage
                    case .kickoutRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.KickOutMessage.self, from: json) as ChatRoomMessage
                    case .roomInfo:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.RoomInfoMessage.self, from: json) as ChatRoomMessage
                    case .system:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.SystemMessage.self, from: json) as ChatRoomMessage
                    case .emoji:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.EmojiMessage.self, from: json) as ChatRoomMessage
                    case .groupInfo:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.GroupInfoMessage.self, from: json) as ChatRoomMessage
                    case .groupJoinRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.GroupJoinRoomMessage.self, from: json) as ChatRoomMessage
                    case .groupLeaveRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.GroupLeaveRoomMessage.self, from: json) as ChatRoomMessage
                    case .groupLiveEnd:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.GroupRoomEndMessage.self, from: json) as ChatRoomMessage
                    case .muteMic:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.MuteMicMessage.self, from: json) as ChatRoomMessage
                    case .muteIm:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.MuteImMessage.self, from: json) as ChatRoomMessage
                    default:
                        assert(true, "message type not handler")
                        item = nil
                    }
                }
                return item
            }
            .filterNil()
    }
    
    var newPeerMessageObservable: Observable<PeerMessage> {
        return newPeerMessageSubject.asObservable()
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { (message, sender) -> PeerMessage? in
                guard message.type == .text,
                      let json = message.text.jsonObject(),
                      let messageType = json["message_type"] as? String,
                      let type = Peer.MessageType(rawValue: messageType) else {
                    return nil
                }
                var item: PeerMessage?
                decoderCatcher {
                    switch type {
                    case .text:
                        item = try JSONDecoder().decodeAnyData(Peer.TextMessage.self, from: json) as PeerMessage
                    case .groupRoomCall:
                        item = try JSONDecoder().decodeAnyData(Peer.CallMessage.self, from: json) as PeerMessage
                    case .groupApply:
                        item = try JSONDecoder().decodeAnyData(Peer.GroupApplyMessage.self, from: json) as PeerMessage
                    case .roomInvitation, .roomInvitationInviteStranger:
                        item = try JSONDecoder().decodeAnyData(Peer.FriendUpdatingInfo.self, from: json) as PeerMessage
                    case .friendsInfo:
                        if sender.int == IMManager.systemAgoraUid {
                            item = try JSONDecoder().decodeAnyData(Peer.FriendUpdatingInfo.self, from: json) as PeerMessage
                        }
                    case .unreadNotice, .unreadGroupApply, .unreadInteractiveMsg:
                        item = try JSONDecoder().decodeAnyData(Peer.UnreadNotice.self, from: json) as PeerMessage
                    case .dm:
                        var dmMessage = try JSONDecoder().decodeAnyData(Entity.DMMessage.self, from: json)
                        dmMessage.ms = Double(message.serverReceivedTs)
                        dmMessage.isFromMe = dmMessage.fromUid == Settings.loginUserId?.string
                        
                        if dmMessage.isNeedDownloadSource {
                            dmMessage.status = .downloading
                        } else {
                            dmMessage.status = .success
                        }
                        if dmMessage.body.msgType == .voice {
                            dmMessage.unread = true
                        }
                        item = dmMessage
                        
                    case .backFollow:
                        item = try JSONDecoder().decodeAnyData(Peer.BackFollowMessge.self, from: json) as PeerMessage
                    }
                }
                return item
            }
            .filterNil()
            .do(onNext: { [weak self] item in
                guard item.msgType == .dm else {
                    return
                }
                self?.triggerImpactIfCould()
            })
        
    }
    
    var joinedChannelSignal: Observable<Bool> {
        return joinedSubject.asObservable()
    }
    
    var imIsReady: Bool {
        return joinedSubject.value
    }
    
    override private init() {
        super.init()
        rtmKit = AgoraRtmKit(appId: KeyCenter.Agora.AppId, delegate: self)
        bindEvents()
    }
    
    func joinChannel(_ channel: String) {
        onlineRelay.filter { $0 == .online }.take(1)
            .flatMap { [weak self] (_) -> Single<String> in
                guard let `self` = self else {
                    return Single.error(MsgError(code: 500, msg: R.string.localizable.amongChatHomeEnterRoomFailed()))
                }
                return self.rtmJoinChannel(channel)
            }
            .subscribe(onNext: { [weak self] (channelId) in
                cdPrint("joinChannel: \(channelId)")
                self?.joinedSubject.accept(true)
            })
            .disposed(by: bag)
    }
    
    func leaveChannel(_ channelId: String) {
        cdPrint("clean: \(channelId)")
        joinedSubject.accept(false)
        rtmChannel?.leave(completion: { (code) in
            cdPrint("clean leave: \(code.rawValue)")
            guard code == .ok else {
                return
            }
        })
        rtmKit?.destroyChannel(withId: channelId)
    }
    
    func send(channelMessage message: String) -> Single<Bool> {
        cdPrint("sendChannelMessage message: \(message)")

        return Single<Bool>.create { [weak self] (subsciber) -> Disposable in
            let rtmMessage = AgoraRtmMessage(text: message)
            
            self?.rtmChannel?.send(rtmMessage, sendMessageOptions: AgoraRtmSendMessageOptions(), completion: { (code) in
                subsciber(.success(code == .errorOk))
            })
            
            return Disposables.create {
                
            }
        }
        
    }
    
    func sendPeer(message: String, to: Int) -> Single<Bool> {
        cdPrint("sendPeer message: \(message) to: \(to)")
        return Single<Bool>.create { [weak self] (subsciber) -> Disposable in
            let rtmMessage = AgoraRtmMessage(text: message)
            self?.rtmKit?.send(rtmMessage, toPeer: to.string, completion: { (code) in
                if code != .ok {
                    cdPrint("sendPeer message faile, code:\(code.rawValue)")
                } else {
                    cdPrint("sendPeer message success, code:\(code.rawValue)")
                }
                subsciber(.success(code == .ok))
            })
            
            return Disposables.create {
                
            }
        }
    }
    
    func getMediaId(with filePath: String) -> Single<String?> {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath) else {
            return .just(nil)
        }
        return Single.create { [weak self] observer in
            var requestId: Int64 = 0
            self?.rtmKit?.createFileMessage(byUploading: filePath, withRequest: &requestId, completion: { rId, message, error in
                observer(.success(message?.mediaId))
                cdPrint("filePath: \(filePath) rid: \(rId) message: \(message?.mediaId) error: \(error.rawValue)")
            })
            return Disposables.create()
        }
    }
    
    //file path
    func downloadFile(with body: Entity.DMMessageBody) -> Single<URL?> {
        guard let mediaId = body.url,
              let fileName = body.localFileName else {
            return .just(nil)
        }
        let filePath: URL
        if body.isVoiceMsg {
            guard let path = FileManager.voiceFilePath(with: fileName) else {
                return .just(nil)
            }
            filePath = URL(fileURLWithPath: path)
        } else {
            guard let path = FileManager.voiceFilePath(with: fileName) else {
                return .just(nil)
            }
            filePath = URL(fileURLWithPath: path)
        }
        guard !FileManager.default.fileExists(atPath: filePath.path) else {
            return .just(filePath)
        }
        return Single.create { [weak self] observer in
            var requestId: Int64 = 0
            self?.rtmKit?.downloadMedia(mediaId, toFile: filePath.path, withRequest: &requestId, completion: { rId, error in
                if error == .ok {
                    observer(.success(filePath))
                }
                cdPrint("downloadMedia filePath: \(filePath) rid: \(rId) error: \(error.rawValue)")
            })
            return Disposables.create {
                self?.rtmKit?.cancelMediaDownload(requestId, completion: { rId, error in
                    if error == .ok {
                        observer(.success(filePath))
                    }
                    cdPrint("cancelMediaDownload filePath: \(filePath) rid: \(rId) error: \(error.rawValue)")
                })
            }
        }
    }
    
}

private extension IMManager {
    
    func triggerImpactIfCould() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func bindEvents() {
        Settings.shared.loginResult.replay()
            .subscribe(onNext: { [weak self] (result) in
                self?.retryCount = 2
                if let _ = result {
                    self?.loginSDK()
                } else {
                    self?.logoutSDK()
                }
                
            })
            .disposed(by: bag)
    }
    
    func loginRetryIfCould() {
        if self.retryCount > 0 {
            //clear token
            Settings.shared.cachedRtmToken = nil
            self.retryCount -= 1
            self.loginSDK()
        }
    }
    
    func loginSDK() {
        loginDisposable?.dispose()
        loginDisposable = onlineRelay
            .do(onNext: { [weak self] (status) in
                guard status == .online else {
                    return
                }
                self?.logoutSDK()
            })
            .filter { $0 == .offline }
            .take(1)
            .flatMap({ (_) -> Single<Entity.RTMToken?> in
                cdPrint("requet loginSDK-token")
                return Request.rtmToken()
            })
            .subscribe(onNext: { [weak self] token in
                guard let `self` = self, let token = token, let uid = Settings.loginUserId?.string else { return }
                cdPrint("requet loginSDK token: \(token.rcToken)")
                self.rtmKit?.login(byToken: token.rcToken, user: uid, completion: { [weak self] (code) in
                    guard let `self` = self else { return }
                    cdPrint("requet loginSDK code: \(code.rawValue)")
                    if code == .ok || code == .alreadyLogin {
                        self.onlineRelay.accept(.online)
                    } else {
                        self.onlineRelay.accept(.offline)
                        self.loginRetryIfCould()
                    }
                })
            }, onError: { [weak self] error in
                cdPrint("requet loginSDK error: \(error)")
                self?.loginRetryIfCould()
            })
        loginDisposable?.disposed(by: bag)
    }
    
    func logoutSDK() {
        guard onlineRelay.value == .online else {
            return
        }
        cdPrint("requet logoutSDK")
        rtmKit?.logout(completion: { [weak self] (code) in
//                guard code == .ok else {
//                    return
//                }
            cdPrint("requet logoutSDK result: \(code)")
            self?.onlineRelay.accept(.offline)
        })
        
    }
    
    func rtmJoinChannel(_ channel: String) -> Single<String> {
        
        guard let rtmChannel = rtmKit?.createChannel(withId: channel, delegate: self) else {
            return Single.error(MsgError(code: 500, msg:  R.string.localizable.amongChatHomeEnterRoomFailed()))
        }
        
        return Single<String>.create { [weak self] (subscriber) -> Disposable in
            
            guard let `self` = self else {
                subscriber(.error(MsgError(code: 500, msg:  R.string.localizable.amongChatHomeEnterRoomFailed())))
                return Disposables.create()
            }
            
            
            cdPrint("joinChannel: \(channel)")
            rtmChannel.join { (code) in
                guard code == .channelErrorOk else {
                    subscriber(.error(MsgError(code: 500, msg:  R.string.localizable.amongChatHomeEnterRoomFailed())))
                    return
                }
                cdPrint("joinChannel: \(channel) code: \(code.rawValue)")
                self.rtmChannel = rtmChannel
                subscriber(.success(channel))
            }
            
            return Disposables.create()
        }
        
    }
    
}

// MARK: AgoraRtmDelegate
extension IMManager: AgoraRtmDelegate {
    func rtmKit(_ kit: AgoraRtmKit, connectionStateChanged state: AgoraRtmConnectionState, reason: AgoraRtmConnectionChangeReason) {
        cdPrint("connectionStateChanged: \(state.rawValue) reason: \(reason.rawValue)")
    }
    
    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        cdPrint("receive peer message: \(message.text) from: \(peerId)")
        newPeerMessageSubject.onNext((message, peerId))
    }
}

// MARK: AgoraRtmChannelDelegate
extension IMManager: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        cdPrint("memberJoined: \(member.channelId) \(member.userId)")
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        cdPrint("memberLeft: \(member.channelId) \(member.userId)")
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        cdPrint("messageReceived: \(member.channelId + "  " + member.userId + " text: " +  message.text)")
        newChannelMessageSubject.onNext((message, member))
    }
    
    func channel(_ channel: AgoraRtmChannel, memberCount count: Int32) {
        cdPrint("memberCount: \(count)")

    }
}

