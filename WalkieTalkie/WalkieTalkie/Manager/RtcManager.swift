//
//  RtcManager.swift
//  AgoraChatRoom
//
//  Created by LXH on 2019/11/25.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

import AgoraRtcKit

protocol RtcDelegate: class {
    func onJoinChannelSuccess(channelId: String)

    func onUserOnlineStateChanged(uid: UInt, isOnline: Bool)

    func onUserMuteAudio(uid: UInt, muted: Bool)

    func onAudioMixingStateChanged(isPlaying: Bool)

    func onAudioVolumeIndication(uid: UInt, volume: UInt)
    
    func onConnectionChangedTo(state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason)
}

//1761995123
//106274582
class RtcManager: NSObject {
    static let shared = RtcManager()

    weak var delegate: RtcDelegate?
    
    private(set) var role: AgoraClientRole?
    
    private var mRtcEngine: AgoraRtcEngineKit?
    private var mUserId: UInt = 0
    //
    private var unMuteUsers: [UInt] = []
    private var haveUnmuteUser: Bool {
        return !unMuteUsers.isEmpty
    }

    private override init() {
        super.init()
    }

    func initialize() {
        if mRtcEngine == nil {
            mRtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        }
        if let `mRtcEngine` = mRtcEngine {
            mRtcEngine.setChannelProfile(.liveBroadcasting)
            mRtcEngine.setAudioProfile(.musicHighQuality, scenario: .chatRoomEntertainment)
            mRtcEngine.enableAudioVolumeIndication(500, smooth: 3, report_vad: false)
        }
    }

    func joinChannel(_ channelId: String, _ userId: UInt, completionHandler: (() -> Void)?) {
        mRtcEngine?.joinChannel(byToken: KeyCenter.Token, channelId: channelId, info: nil, uid: userId, joinSuccess: { [weak self] (channel, uid, elapsed) in
            print("rtc join success \(channel) \(uid)")
            guard let `self` = self else {
                return
            }
            self.mUserId = uid
            completionHandler?()
            self.delegate?.onJoinChannelSuccess(channelId: channelId)
        })
    }

    func setClientRole(_ role: AgoraClientRole) {
        let result = mRtcEngine?.setClientRole(role)
        if result == 0 {
            debugPrint("setClientRole: \(role.rawValue) success")
        } else {
            debugPrint("setClientRole: \(role.rawValue) failed")
        }
        self.role = role
    }

    func muteAllRemoteAudioStreams(_ muted: Bool) {
        mRtcEngine?.muteAllRemoteAudioStreams(muted)
    }

    func muteLocalAudioStream(_ muted: Bool) {
        mRtcEngine?.muteLocalAudioStream(muted)
        delegate?.onUserMuteAudio(uid: mUserId, muted: muted)
    }

    func startAudioMixing(_ filePath: String?) {
        if let `mRtcEngine` = mRtcEngine, let `filePath` = filePath {
            let volume = haveUnmuteUser ? 7 : 15
            mRtcEngine.startAudioMixing(filePath, loopback: false, replace: false, cycle: 1)
            mRtcEngine.adjustAudioMixingVolume(volume)
            mRtcEngine.adjustAudioMixingPublishVolume(volume)
        }
    }

    func stopAudioMixing() {
        mRtcEngine?.stopAudioMixing()
    }
    
    //second
    func getAudioMixingDuration() -> Int {
        guard let duration = mRtcEngine?.getAudioMixingDuration() else {
            return 0
        }
        return Int(duration)
    }

    func setVoiceChanger(_ type: Int) {
        mRtcEngine?.setParameters("{\"che.audio.morph.voice_changer\": \(type)}")
    }

    func setReverbPreset(_ type: Int) {
        mRtcEngine?.setParameters("{\"che.audio.morph.reverb_preset\": \(type)}")
    }

    func leaveChannel() {
        mRtcEngine?.leaveChannel(nil)
        setClientRole(.audience)
        self.role = nil
    }
}

extension RtcManager: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        print("connectionChangedTo: \(state.rawValue) reason: \(reason.rawValue)")
        delegate?.onConnectionChangedTo(state: state, reason: reason)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didClientRoleChanged oldRole: AgoraClientRole, newRole: AgoraClientRole) {
        print("didClientRoleChanged \(oldRole.rawValue) \(newRole.rawValue)")

        if newRole == .broadcaster {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: true)
        } else if newRole == .audience {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: false)
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid \(uid)")
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: true)
//        if muted {
//                   unMuteUsers.removeAll(where: { $0 == uid })
//               } else {
                   unMuteUsers.append(uid)
//               }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("didOfflineOfUid \(uid)")
        unMuteUsers.removeAll(where: { $0 == uid })
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: false)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        print("didAudioMuted \(uid) \(muted)")
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
}
