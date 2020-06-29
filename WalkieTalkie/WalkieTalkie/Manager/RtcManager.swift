//
//  RtcManager.swift
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

protocol RtcDelegate: class {
    func onJoinChannelSuccess(channelId: String)
    
    func onJoinChannelFailed(channelId: String?)
    
    func onJoinChannelTimeout(channelId: String?)

    func onUserOnlineStateChanged(uid: UInt, isOnline: Bool)

    func onUserMuteAudio(uid: UInt, muted: Bool)

    func onAudioMixingStateChanged(isPlaying: Bool)

    func onAudioVolumeIndication(uid: UInt, volume: UInt)
    
    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason)
}

//1761995123
//106274582
class RtcManager: NSObject {
    static let shared = RtcManager()

    weak var delegate: RtcDelegate?

    var unMuteUsers: [UInt] = []

    ///current channel ID
    private var channelId: String?
    private(set) var role: AgoraClientRole?
    private var mRtcEngine: AgoraRtcEngineKit!
    private var mUserId: UInt = 0
    private var timeoutTimer: SwiftTimer?
    private var recorderTimer: SwiftTimer?
    private var haveUnmuteUser: Bool {
        return !unMuteUsers.isEmpty
    }
    
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
        mRtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        mRtcEngine.setLogFile(logFilePath())
        mRtcEngine.setChannelProfile(.liveBroadcasting)
        mRtcEngine.setAudioProfile(.musicHighQuality, scenario: .chatRoomEntertainment)
        mRtcEngine.enableAudioVolumeIndication(500, smooth: 3, report_vad: false)
        //先开始测试
//        isLastmileProbeTesting = true
    }

    func joinChannel(_ channelId: String, _ userId: UInt, completionHandler: (() -> Void)?) {
        //清除数据
        unMuteUsers.removeAll()
        let result = mRtcEngine.joinChannel(byToken: KeyCenter.Token, channelId: channelId, info: nil, uid: userId, joinSuccess: { [weak self] (channel, uid, elapsed) in
            cdPrint("rtc join success \(channel) \(uid)")
            guard let `self` = self else {
                return
            }
            self.channelId = channelId
            self.mUserId = uid
            completionHandler?()
            self.delegate?.onJoinChannelSuccess(channelId: channelId)
        })
        //start a time out timer
        if result != 0 {
            delegate?.onJoinChannelFailed(channelId: channelId)
        } else {
            startTimeoutTimer()
        }
    }
    
    func startTimeoutTimer() {
        invalidTimerIfNeed()
        timeoutTimer = SwiftTimer(interval: .seconds(60), handler: { [weak self] _ in
            self?.delegate?.onJoinChannelTimeout(channelId: self?.channelId)
            self?.invalidTimerIfNeed()
        })
        timeoutTimer?.start()
    }
    
    func invalidTimerIfNeed() {
        guard timeoutTimer != nil else {
            return
        }
        timeoutTimer?.cancel()
        timeoutTimer = nil
    }

    func setClientRole(_ role: AgoraClientRole) {
        let result = mRtcEngine.setClientRole(role)
        if result == 0 {
            cdPrint("setClientRole: \(role.rawValue) success")
        } else {
            cdPrint("setClientRole: \(role.rawValue) failed")
        }
        self.role = role
        updateRecordStatus()
    }
    
    func updateRecordStatus() {
        if role == .broadcaster {
            let path = Path.caches/"\(Date().timeIntervalSince1970.int)_record.wav"
            SpeechRecognizer.default.add(file: path.string)
            mRtcEngine.startAudioRecording(path.string, quality: .medium)
            //倒计时5秒
            cdPrint("start recording path: \(path)")
            invalidRecordTimerIfNeed()
            recorderTimer = SwiftTimer(interval: .seconds(2), handler: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                cdPrint("end recording path: \(path)")
                self.mRtcEngine.stopAudioRecording()
                SpeechRecognizer.default.startIfNeed()
                self.invalidRecordTimerIfNeed()
                mainQueueDispatchAsync(after: 0.2) { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    if self.role == .broadcaster {
                        self.updateRecordStatus()
                    }
                }
            })
            recorderTimer?.start()
        } else {
            cdPrint("end recording")
            invalidRecordTimerIfNeed()
            mRtcEngine.stopAudioRecording()
            SpeechRecognizer.default.startIfNeed()
        }
    }
    
    func invalidRecordTimerIfNeed() {
        guard recorderTimer != nil else {
            return
        }
        recorderTimer?.cancel()
        recorderTimer = nil
    }
    
    func muteAllRemoteAudioStreams(_ muted: Bool) {
        mRtcEngine.muteAllRemoteAudioStreams(muted)
    }

    func muteLocalAudioStream(_ muted: Bool) {
        mRtcEngine.muteLocalAudioStream(muted)
        delegate?.onUserMuteAudio(uid: mUserId, muted: muted)
    }

    func startAudioMixing(_ filePath: String?) {
        if let `filePath` = filePath {
            let volume = haveUnmuteUser ? 7 : 15
            mRtcEngine.startAudioMixing(filePath, loopback: false, replace: false, cycle: 1)
            mRtcEngine.adjustAudioMixingVolume(volume)
            mRtcEngine.adjustAudioMixingPublishVolume(volume)
        }
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
        unMuteUsers.removeAll()
        mRtcEngine.leaveChannel(nil)
        setClientRole(.audience)
        self.role = nil
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

extension RtcManager: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        let reportError = NSError(domain: "com.talkie.walkie.rtc.connect", code: Int(errorCode.rawValue), userInfo: nil)
        GuruAnalytics.record(reportError, userInfo: nil)
        delegate?.onJoinChannelFailed(channelId: channelId)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        cdPrint("connectionChangedTo: \(state.rawValue) reason: \(reason.rawValue)")
        if state == .connected {
            invalidTimerIfNeed()
        }
        delegate?.onConnectionChangedTo(state: ConnectState(state), reason: reason)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didClientRoleChanged oldRole: AgoraClientRole, newRole: AgoraClientRole) {
//        cdPrint("didClientRoleChanged \(oldRole.rawValue) \(newRole.rawValue)")

        if newRole == .broadcaster {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: true)
        } else if newRole == .audience {
            delegate?.onUserOnlineStateChanged(uid: mUserId, isOnline: false)
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        cdPrint("didJoinedOfUid \(uid)")
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: true)
        unMuteUsers.append(uid)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        cdPrint("didOfflineOfUid \(uid)")
        unMuteUsers.removeAll(where: { $0 == uid })
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: false)
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        cdPrint("didAudioMuted \(uid) \(muted)")
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
