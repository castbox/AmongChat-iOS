//
//  ConnectState.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import AgoraRtcKit
import ZegoExpressEngine

enum ConnectState: Int {
    case disconnected = 1
    case connecting
    case connected
    case reconnecting
    case failed
    case maxMic
    case preparing
    case talking
    case maxUser
    case timeout
    
//    case
    init(_ state: AgoraConnectionStateType) {
        self = ConnectState(rawValue: state.rawValue) ?? .failed
    }
    
    init(zego state: ZegoRoomState) {
        switch state {
        case .connected:
            self = .connected
        case .connecting:
            self = .connecting
        case .disconnected:
            self = .disconnected
        @unknown default:
            self = .disconnected
        }
    }
}

extension ConnectState {
    var isConnectingState: Bool {
        let connectingState: [ConnectState] = [
            .connecting,
            .connected,
            .reconnecting,
        ]
        return connectingState.contains(self)
    }
    
    var isConnectedState: Bool {
        let connectingState: [ConnectState] = [
            .reconnecting,
            .connected,
            .talking,
            .maxMic,
            .preparing,
        ]
        return connectingState.contains(self)
    }
    
    var title: String {
        switch self {
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .failed:
            return "failed"
        case .reconnecting:
            return "reconnecting"
        case .maxMic:
            return "Mic Max"
        case .preparing:
            return "PREPARING..."
        case .talking:
            return "talking..."
        case .maxUser:
            return "Max"
        case .timeout:
            return "Timeout"
        }
    }
}

