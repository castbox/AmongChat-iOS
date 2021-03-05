//
//  ZegoRtcManager.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 22/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Path
import CastboxDebuger
import ZegoExpressEngine

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[ZegoRtcManager]-\(message)")
}

class ZegoRtcManager: NSObject, RtcManageable {
    
    
    static let shared = ZegoRtcManager()

    weak var delegate: RtcDelegate?
    var user: Entity.UserProfile {
        Settings.shared.amongChatUserProfile.value!
    }
    
    ///current channel IDz
    var channelId: String?
    private(set) var role: RtcUserRole?
    private var mRtcEngine: ZegoExpressEngine!
    private var mUserId: UInt = 0
    private var timeoutTimer: SwiftTimer?
    private var joinChannelCompletionHandler: (() -> Void)?
    private var publishingStream: [ZegoStream] = []
//    private var recorderTimer: SwiftTimer?
//    private var haveUnmuteUser: Bool {
//        return !unMuteUsers.isEmpty
//    }
    
//    private var isLastmileProbeTesting = false {
//        didSet {
//            if isLastmileProbeTesting {
//                let config = AgoraLastmileProbeConfig()
//                config.probeUplink = true
//                config.probeDownlink = true
//                config.expectedUplinkBitrate = 5000
//                config.expectedDownlinkBitrate = 5000
//                mRtcEngine.startLastmileProbeTest(config)
//            } else {
//                mRtcEngine.stopLastmileProbeTest()
//            }
//        }
//    }

    private override init() {
        super.init()
    }

    func initialize() {
        ZegoExpressEngine.createEngine(withAppID: KeyCenter.Zego.AppId, appSign: KeyCenter.Zego.appSign, isTestEnv: true, scenario: .live, eventHandler: self)
        mRtcEngine = ZegoExpressEngine.shared()

        let config = ZegoAudioConfig()
        config.codecID = .low3
        config.bitrate = 32
        config.channel = .mono
        mRtcEngine.setAudioConfig(config)
        //降噪
        mRtcEngine.enableAEC(true)
        mRtcEngine.enableHeadphoneAEC(true)
        //启动声浪监控
        mRtcEngine.startSoundLevelMonitor()
        //设置重连时间
        //10 人 进入后报错
        
    }
    
    func joinChannel(_ joinable: RTCJoinable, _ token: String, _ userId: UInt, completionHandler: (() -> Void)?) {
        cdPrint("join \(joinable.roomId) \(userId)")
        
        //清除数据
        self.channelId = joinable.roomId
        publishingStream.removeAll()
        //
        if let bitrate = joinable.rtcBitRate {
            let config = ZegoAudioConfig()
            config.codecID = .low3
            config.bitrate = bitrate.int32
            config.channel = .mono
            mRtcEngine.setAudioConfig(config)
        }
        
        let config = ZegoRoomConfig()
        config.isUserStatusNotify = true
        config.token = token
        
        self.joinChannelCompletionHandler = completionHandler
        
        mRtcEngine.loginRoom(joinable.roomId, user: ZegoUser(userID: userId.string, userName: user.name ?? ""), config: config)
    }
    
    func startTimeoutTimer() {
        invalidTimerIfNeed()
        timeoutTimer = SwiftTimer(interval: .seconds(60), handler: { [weak self] _ in
            self?.delegate?.onJoinChannelTimeout(channelId: self?.channelId)
            self?.invalidTimerIfNeed()
        })
        timeoutTimer?.start()
    }
//
    func invalidTimerIfNeed() {
        guard timeoutTimer != nil else {
            return
        }
//        timeoutTimer?.cancel()
        timeoutTimer = nil
    }
    
    func setClientRole(_ role: RtcUserRole) {
        switch role {
        case .broadcaster:
            //user id
            mRtcEngine.startPublishingStream(user.uid.string)
        case .audience:
            mRtcEngine.stopPublishingStream()
        }
    }
    
    func adjustUserPlaybackSignalVolume(_ uid: Int, volume: Int32 = 0) -> Bool {
        mRtcEngine.mutePlayStreamAudio(volume == 0, streamID: uid.string)
        cdPrint("adjustUserPlaybackSignalVolume value: \(volume) streamID: \(uid)")
        return true
    }
    
    func mic(muted: Bool) {
        mRtcEngine.muteMicrophone(muted)
        delegate?.onUserMuteAudio(uid: mUserId, muted: muted)
    }

    func leaveChannel() {
        //清除数据
        guard let channelId = channelId else {
            return
        }
        mRtcEngine.logoutRoom(channelId)
        self.role = nil
        self.channelId = nil
    }
    
    func logFilePath() -> String {
        guard let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return ""
        }
        let fileURL = directoryURL.appendingPathComponent("walkie_talkie_zego.log")
        cdPrint("logFilePath: \(fileURL.path)")
        return fileURL.path
    }
}

extension ZegoRtcManager: ZegoEventHandler {
    
    func onDebugError(_ errorCode: Int32, funcName: String, info: String) {
        cdPrint("errorCode: \(errorCode) funcName: \(funcName) info: \(info)")
    }
    
    func onEngineStateUpdate(_ state: ZegoEngineState) {
        cdPrint("onEngineStateUpdate: \(state.rawValue)")
    }
    
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        if errorCode != 0 {
            let reportError = NSError(domain: "com.talkie.walkie.zego.rtc.connect", code: errorCode.int, userInfo: nil)
            GuruAnalytics.record(reportError, userInfo: nil)
            delegate?.onJoinChannelFailed(channelId: channelId)
        }
        switch state {
        case .connected:
            if joinChannelCompletionHandler != nil {
                joinChannelCompletionHandler?()
                joinChannelCompletionHandler = nil
            }
            delegate?.onJoinChannelSuccess(channelId: roomID)
        case .connecting:
            ()
        case .disconnected:
            ()
        @unknown default:
            ()
        }
        cdPrint("connectionChangedTo: \(state.rawValue) errorCode: \(errorCode) extendedData: \(extendedData) roomID: \(roomID)")
        delegate?.onConnectionChangedTo(state: ConnectState(zego: state), reason: .joinSuccess)
    }
    
    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        //当前用户上麦成功
        if state == .publishing, errorCode == 0 {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: true)
            cdPrint(" 📥 onPublisherStateUpdate, publishing: \(streamID) errorCode: \(errorCode) extendedData: \(extendedData)")


        } else {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: false)
            cdPrint(" 📥 onPublisherStateUpdate, Requesting: \(streamID) errorCode: \(errorCode) extendedData: \(extendedData)")
        }

    }
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        //拉流
        switch updateType {
        case .add:
            streamList.forEach { stream in
                //add
                if !publishingStream.contains(where: { $0.streamID == stream.streamID }) {
                    publishingStream.append(stream)
                }
                cdPrint(" 📥 onRoomStreamUpdate Start playing stream, streamID: \(stream.streamID)");
                mRtcEngine.startPlayingStream(stream.streamID)
            }
        case .delete:
            streamList.forEach { stream in
                publishingStream = publishingStream.filter { $0.streamID == stream.streamID && $0.user.userID == stream.user.userID }
                cdPrint(" 📥 onRoomStreamUpdate delete stream, streamID: \(stream.streamID)");
                mRtcEngine.stopPlayingStream(stream.streamID)
            }
            
        }
    }
    
    func onPlayerStateUpdate(_ state: ZegoPlayerState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        switch state {
        case .playRequesting:
            cdPrint(" 📥 onPlayerStateUpdate, playRequesting: \(streamID) errorCode: \(errorCode) extendedData: \(extendedData)")
        case .playing:
            cdPrint(" 📥 onPlayerStateUpdate, playing: \(streamID) errorCode: \(errorCode) extendedData: \(extendedData)")
        case .noPlay:
            cdPrint(" 📥 onPlayerStateUpdate, noPlay: \(streamID) errorCode: \(errorCode) extendedData: \(extendedData)")
        default:
            cdPrint(" 📥 onPlayerStateUpdate, unknow: \(streamID) errorCode: \(errorCode) extendedData: \(extendedData)")
        }

    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        
        userList.forEach { user in
            switch updateType {
            case .add:
                //新增
                cdPrint(" 📥 onRoomUserUpdate - ADD user=\(user) \(roomID)");
                delegate?.onUserOnlineStateChanged(uid: user.userID.uIntValue, isOnline: true)
            case .delete:
                cdPrint(" 📥 onRoomUserUpdate - DELETE user=\(user) \(roomID)");
                delegate?.onUserOnlineStateChanged(uid: user.userID.uIntValue, isOnline: false)
            @unknown default:
                ()
            }

        }
    }
    
    func onRoomOnlineUserCountUpdate(_ count: Int32, roomID: String) {
        cdPrint(" 📥 onRoomOnlineUserCountUpdate: count=\(count) \(roomID)");
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        cdPrint(" 📥 onRemoteSoundLevelUpdate: soundLevels=\(soundLevels)");
        soundLevels.forEach { (streamId, value) in
            delegate?.onAudioVolumeIndication(uid: streamId.uIntValue, volume: value.uintValue)
        }
    }
    
    //
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        delegate?.onAudioVolumeIndication(uid: user.uid.uInt, volume: soundLevel.uintValue)
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        //ZegoRemoteDeviceStateMute
        cdPrint(" 📥 onRemoteMicStateUpdate: state=\(state.rawValue) \(streamID)");
        switch state {
        case .mute:
            delegate?.onUserMuteAudio(uid: streamID.uIntValue, muted: true)
        case .open:
            delegate?.onUserMuteAudio(uid: streamID.uIntValue, muted: false)
        default:
            ()
            break
        }
    }
    
    
}
