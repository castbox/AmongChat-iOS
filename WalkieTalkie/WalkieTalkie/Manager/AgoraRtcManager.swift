//
//  AgoraRtcManager.swift
//  AgoraChatRoom
//
//  Created by LXH on 2019/11/25.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation
import AgoraRtcKit
import RxCocoa
import RxSwift
import Path
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AgoraRtcManager]-\(message)")
}

enum RtcUserRole: Int {
    case broadcaster = 1
    case audience = 2
}

/* AgoraConnectionChangedReason
typedef NS_ENUM(NSUInteger, AgoraConnectionChangedReason) {
    /** 0: The SDK is connecting to Agora's edge server. */
    AgoraConnectionChangedConnecting = 0,
    /** 1: The SDK has joined the channel successfully. */
    AgoraConnectionChangedJoinSuccess = 1,
    /** 2: The connection between the SDK and Agora's edge server is interrupted.  */
    AgoraConnectionChangedInterrupted = 2,
    /** 3: The connection between the SDK and Agora's edge server is banned by Agora's edge server. */
    AgoraConnectionChangedBannedByServer = 3,
    /** 4: The SDK fails to join the channel for more than 20 minutes and stops reconnecting to the channel. */
    AgoraConnectionChangedJoinFailed = 4,
    /** 5: The SDK has left the channel. */
    AgoraConnectionChangedLeaveChannel = 5,
    /** 6: The specified App ID is invalid. Try to rejoin the channel with a valid App ID. */
    AgoraConnectionChangedInvalidAppId = 6,
    /** 7: The specified channel name is invalid. Try to rejoin the channel with a valid channel name. */
    AgoraConnectionChangedInvalidChannelName = 7,
    /** 8: The generated token is invalid probably due to the following reasons:
<li>The App Certificate for the project is enabled in Console, but you do not use Token when joining the channel. If you enable the App Certificate, you must use a token to join the channel.
<li>The uid that you specify in the [joinChannelByToken]([AgoraRtcEngineKit joinChannelByToken:channelId:info:uid:joinSuccess:]) method is different from the uid that you pass for generating the token. */
    AgoraConnectionChangedInvalidToken = 8,
    /** 9: The token has expired. Generate a new token from your server. */
    AgoraConnectionChangedTokenExpired = 9,
    /** 10: The user is banned by the server. */
    AgoraConnectionChangedRejectedByServer = 10,
    /** 11: The SDK tries to reconnect after setting a proxy server. */
    AgoraConnectionChangedSettingProxyServer = 11,
    /** 12: The token renews. */
    AgoraConnectionChangedRenewToken = 12,
    /** 13: The client IP address has changed, probably due to a change of the network type, IP address, or network port. */
    AgoraConnectionChangedClientIpAddressChanged = 13,
    /** 14: Timeout for the keep-alive of the connection between the SDK and Agora's edge server. The connection state changes to AgoraConnectionStateReconnecting(4). */
    AgoraConnectionChangedKeepAliveTimeout = 14,
}
 */

enum RtcConnectionChangedReason {
    case connecting
    case joinSuccess
    case kickBySystemOfRoomInactive //
    case kickByHost
    case kickBySystemOfRoomFull
    case joinFailed
    case invalidToken
    
    init(agoraReason: AgoraConnectionChangedReason) {
        switch agoraReason {
        case .connecting:
            self = .connecting
        case .joinSuccess:
            self = .joinSuccess
        case .joinFailed:
            self = .joinFailed
        case .bannedByServer:
            self = .kickBySystemOfRoomInactive
        case .invalidToken:
            self = .invalidToken
        default:
            self = .joinSuccess
        }
    }
    
    init(zegoExtendData: [AnyHashable : Any]?) {
        guard let data = zegoExtendData, let kickoutMsg = data["custom_kickout_message"] as? String else {
            self = .joinSuccess
            return
        }
        /*
         zego踢人reason
         host： 房主踢人
         inactive：1人房系统踢出
         full： 房间超员系统踢出
         [onRoomStateUpdate] hdPVqw3m DISCONNECTED 1002055 {"custom_kickout_message":"host"}
         **/
        switch kickoutMsg {
        case "host":
            //host kick
            self = .kickByHost
        case "inactive":
            self = .kickBySystemOfRoomInactive
        case "full":
            self = .kickBySystemOfRoomFull
        default:
            self = .joinSuccess
        }
    }
}

protocol RtcManageable {
    //当前房间的 channel id
    var channelId: String? { get set }
    
    func initialize()
    
    func joinChannel(_ joinable: RTCJoinable, _ token: String, _ userId: UInt, completionHandler: (() -> Void)?)
    
    func setClientRole(_ role: RtcUserRole)
    
    func update(joinable: RTCJoinable)
    
    func mic(muted: Bool)
    
//    func muteAllRemoteAudioStreams(_ muted: Bool)
    func adjustUserPlaybackSignalVolume(_ uid: UInt, volume: Int32) -> Bool
    
    func leaveChannel()
}


protocol RtcDelegate: class {
    func onJoinChannelSuccess(channelId: String)
    
    func onJoinChannelFailed(channelId: String?)
    
    func onJoinChannelTimeout(channelId: String?)

    //用户上下线
    func onUserOnlineStateChanged(uid: UInt, isOnline: Bool)

    func onUserMuteAudio(uid: UInt, muted: Bool)

    func onAudioMixingStateChanged(isPlaying: Bool)

    func onAudioVolumeIndication(uid: UInt, volume: UInt)
    
    func onConnectionChangedTo(state: ConnectState, reason: RtcConnectionChangedReason)
    
//    func onChannelUserChanged(users: [ChannelUser])
}

//1761995123
//106274582
class AgoraRtcManager: NSObject, RtcManageable {
    
    static let shared = AgoraRtcManager()

    weak var delegate: RtcDelegate?

//    var unMuteUsers: [UInt] = []
    
//    private var talkedUsers: [ChannelUser] = [] {
//        didSet {
//            delegate?.onChannelUserChanged(users: talkedUsers)
//        }
//    }

    ///current channel IDz
    var channelId: String?
    private(set) var role: RtcUserRole?
    private var mRtcEngine: AgoraRtcEngineKit!
    private var mUserId: UInt = 0
    private var timeoutTimer: SwiftTimer?
    private var joinable: RTCJoinable?
//    private var recorderTimer: SwiftTimer?
//    private var haveUnmuteUser: Bool {
//        return !unMuteUsers.isEmpty
//    }
    
    private var isLastmileProbeTesting = false {
        didSet {
            if isLastmileProbeTesting {
                let config = AgoraLastmileProbeConfig()
                config.probeUplink = true
                config.probeDownlink = true
                config.expectedUplinkBitrate = 5000
                config.expectedDownlinkBitrate = 5000
                mRtcEngine.startLastmileProbeTest(config)
            } else {
                mRtcEngine.stopLastmileProbeTest()
            }
        }
    }

    private override init() {
        super.init()
    }

    func initialize() {
        mRtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.Agora.AppId, delegate: self)
        mRtcEngine.setLogFile(logFilePath())
        mRtcEngine.setChannelProfile(.liveBroadcasting)
        mRtcEngine.setAudioProfile(.musicStandard, scenario: .gameStreaming)
        mRtcEngine.setDefaultAudioRouteToSpeakerphone(true)
        mRtcEngine.enableAudioVolumeIndication(500, smooth: 3, report_vad: false)
        //先开始测试
//        isLastmileProbeTesting = true
    }
    
    func joinChannel(_ joinable: RTCJoinable, _ token: String, _ userId: UInt, completionHandler: (() -> Void)?) {
        //清除数据
//        unMuteUsers.removeAll()
//        talkedUsers.removeAll()
        self.channelId = joinable.roomId
        self.joinable = joinable
        
        cdPrint("join \(channelId) \(userId)")
        
        let result = mRtcEngine.joinChannel(byToken: token, channelId: joinable.roomId, info: nil, uid: userId, joinSuccess: { [weak self] (channel, uid, elapsed) in
            cdPrint("join success \(channel) \(uid)")
            guard let `self` = self else {
                return
            }
            self.setClientRole(joinable.defaultRole)
            self.mUserId = uid
            completionHandler?()
            self.delegate?.onJoinChannelSuccess(channelId: joinable.roomId)
        })
        //start a time out timer
        if result != 0 {
            delegate?.onJoinChannelFailed(channelId: channelId)
        } else {
            startTimeoutTimer()
        }
    }
    
    func update(joinable: RTCJoinable) {
        self.joinable = joinable
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
        let result = mRtcEngine?.setClientRole(AgoraClientRole(rawValue: role.rawValue)!)
        if result == 0 {
            cdPrint("setClientRole: \(role.rawValue) success")
        } else {
            cdPrint("setClientRole: \(role.rawValue) failed")
        }
        self.role = role
    }
    
    func adjustUserPlaybackSignalVolume(_ uid: UInt, volume: Int32 = 0) -> Bool {
        let result = mRtcEngine.muteRemoteAudioStream(uid, mute: volume == 0)
        cdPrint("adjustUserPlaybackSignalVolume value: \(volume) result: \(result)")
//        if volume > 0 {
//            mRtcEngine.adjustUserPlaybackSignalVolume(uid.uInt, volume: volume)
//        }
        return result == 0
    }

    func mic(muted: Bool) {
        mRtcEngine.muteLocalAudioStream(muted)
        delegate?.onUserMuteAudio(uid: mUserId, muted: muted)
    }
    
    func stopAudioMixing() {
        mRtcEngine.stopAudioMixing()
    }
    
    //second
    func getAudioMixingDuration() -> Int {
        let duration = mRtcEngine.getAudioMixingDuration()
        return Int(duration)
    }

    func setVoiceChanger(_ type: Int) {
        mRtcEngine.setParameters("{\"che.audio.morph.voice_changer\": \(type)}")
    }

    func setReverbPreset(_ type: Int) {
        mRtcEngine.setParameters("{\"che.audio.morph.reverb_preset\": \(type)}")
    }

    func leaveChannel() {
        //清除数据
//        unMuteUsers.removeAll()
//        talkedUsers.removeAll()
        mRtcEngine?.leaveChannel(nil)
        setClientRole(.audience)
        self.role = nil
        self.channelId = nil
    }
    
    func logFilePath() -> String {
        guard let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return ""
        }
        let fileURL = directoryURL.appendingPathComponent("walkie_talkie.log")
        cdPrint("logFilePath: \(fileURL.path)")
        return fileURL.path
    }
}

extension AgoraRtcManager: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        let reportError = NSError(domain: "com.talkie.walkie.rtc.connect", code: Int(errorCode.rawValue), userInfo: nil)
        GuruAnalytics.record(reportError, userInfo: nil)
        delegate?.onJoinChannelFailed(channelId: channelId)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        cdPrint("connectionChangedTo: \(state.rawValue) reason: \(reason.rawValue)")
//        if state == .connected {
//            invalidTimerIfNeed()
//        }
        delegate?.onConnectionChangedTo(state: ConnectState(state), reason: RtcConnectionChangedReason(agoraReason: reason))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didClientRoleChanged oldRole: AgoraClientRole, newRole: AgoraClientRole) {
        cdPrint("didClientRoleChanged \(oldRole.rawValue) \(newRole.rawValue)")

        if newRole == .broadcaster {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: true)
//            if !talkedUsers.contains(where: { $0.uid.intValue == mUserId }) {
//                talkedUsers.append(ChannelUser.randomUser(uid: mUserId))
//            } else {
//                talkedUsers = talkedUsers.map { item -> ChannelUser in
//                    guard item.uid.uIntValue == mUserId else {
//                        return item
//                    }
//                    var user = item
//                    user.status = .connected
//                    return user
//                }
//            }
        } else if newRole == .audience {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: false)
//            talkedUsers = talkedUsers.map { item -> ChannelUser in
//                guard item.uid.uIntValue == mUserId else {
//                    return item
//                }
//                var user = item
//                user.status = .droped
//                return user
//            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        cdPrint("didJoinedOfUid \(uid)")
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: true)
//        unMuteUsers.append(uid)
//        if !talkedUsers.contains(where: { $0.uid.uIntValue == uid }) {
//            talkedUsers.append(ChannelUser.randomUser(uid: uid))
//        } else {
//            talkedUsers = talkedUsers.map { item -> ChannelUser in
//                guard item.uid.uIntValue == uid else {
//                    return item
//                }
//                var user = item
//                user.status = .connected
//                return user
//            }
//        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        cdPrint("didOfflineOfUid \(uid) resaon: \(reason.rawValue)")
//        unMuteUsers.removeAll(where: { $0 == uid })
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: false)

//        if reason == .quit {
//            talkedUsers.removeAll(where: { $0.uid.uIntValue == uid })
//        } else if reason == .dropped || reason == .becomeAudience {
//            talkedUsers = talkedUsers.map { item -> ChannelUser in
//                guard item.uid.uIntValue == uid else {
//                    return item
//                }
//                var user = item
//                user.status = .droped
//                return user
//            }
//        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        cdPrint("didAudioMuted \(uid) \(muted)")
//        let talkedUsers = self.talkedUsers.map { user -> ChannelUser in
//            guard user.uid.uIntValue == uid else {
//                return user
//            }
//            var user = user
//            user.isMuted = muted
//            return user
//        }
//        self.talkedUsers = talkedUsers
        delegate?.onUserMuteAudio(uid: uid, muted: muted)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        for info in speakers {
            if info.volume > 0 {
                let uid = info.uid == 0 ? mUserId : info.uid
                delegate?.onAudioVolumeIndication(uid: uid, volume: info.volume)
            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioMixingStateDidChanged state: AgoraAudioMixingStateCode, errorCode: AgoraAudioMixingErrorCode) {
        delegate?.onAudioMixingStateChanged(isPlaying: state == .playing)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, lastmileProbeTest result: AgoraLastmileProbeResult) {
        guard result.state != .complete else {
            isLastmileProbeTesting = false //close
            return
        }
//        let reportError = NSError(domain: "com.talkie.walkie", code: Int(result.state.rawValue), userInfo: [
////            NSLocalizedDescriptionKey: "network test",
////            NSLocalizedFailureReasonErrorKey: maybeReason ?? "",
//            result.downlinkReport
//        ])
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        
    }
}
