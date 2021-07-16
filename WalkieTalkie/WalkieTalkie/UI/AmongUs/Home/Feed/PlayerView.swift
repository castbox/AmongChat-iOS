//
//  VideoPlayerView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 25/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import AVFoundation
import CastboxDebuger


fileprivate func cdPrint(_ message: Any) {
    Debug.info("[VideoPlayerView]-\(message)")
}

// MARK: - PlayerControllerEvent

enum PlayerControllerEventType {
    case none
    case playing
    case paused
    case stalled
    case failed
}

class PlayerView: UIView {
    
    // MARK: - Variables
    private var videoURL: URL?
    private var originalURL: URL?
    
    private var playerItem: AVPlayerItem?
    private var avPlayerLayer: AVPlayerLayer!
    private var playerLooper: AVPlayerLooper! // should be defined in class
    private var queuePlayer: AVQueuePlayer?
    private var observer: NSKeyValueObservation?
    private var timeObserver: Any?
        
    private lazy var videoPlayer: SZAVPlayer = {
        let player = SZAVPlayer()
        player.backgroundColor = .clear
        player.delegate = self
        return player
    }()
    
    private var playerControllerEvent: PlayerControllerEventType = .none
    
    private(set) var duration: Float = 0
    private(set) var currentTime: Float = 0
    
    var playingProgressHandler: ((Float) -> Void)?
    var loadHandler: CallBack?
    var config: SZAVPlayerConfig?
    var retryTime: UInt = 0
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubview()
    }
    
    deinit {

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
    }
    
    func configureSubview() {
        addSubview(videoPlayer)
        videoPlayer.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
    
    func configure(url: URL?, size: (Int, Int), loadHandler: CallBack?) {
        
        guard let url = url else {
            return
        }
        
        videoPlayer.reset(cleanAsset: true)
        
        cdPrint("configure url: \(url)")
        
        retryTime = 0
        
        var config = SZAVPlayerConfig(urlStr: url.absoluteString, uniqueID: nil, isVideo: true, isVideoOutputEnabled: false)
        config.disableCustomLoading = true
        config.timeObserverInterval = 0.05
        config.videoGravity = (size.0 < size.1) ? .resizeAspectFill : .resizeAspect
        videoPlayer.setupPlayer(config: config)
        self.config = config
        
        self.originalURL = url
        self.loadHandler = loadHandler
    }
    
    func set(progress: CGFloat) {
        guard duration > 0 else {
            return
        }
        let time = duration.cgFloat * progress
        cdPrint("progress: \(progress) time: \(time)")
        videoPlayer.seekPlayerToTime(time: Float64(time), autoPlay: false) { [weak self] result in
            self?.playingProgressHandler?(Float(progress))
        }
    }
    
    func replay(){
//        self.queuePlayer?.seek(to: .zero)
        videoPlayer.seekPlayerToTime(time: 0) { result in
            
        }
        play()
    }
    
    func play() {
        playerControllerEvent = .playing
        videoPlayer.play()
        setAudioMode()
    }
    
    func pause(){
        playerControllerEvent = .paused
        videoPlayer.pause()
    }
    
    func callLoadedHandler() {
        loadHandler?()
        loadHandler = nil
    }
}


// MARK: - SZAVPlayerDelegate

extension PlayerView: SZAVPlayerDelegate {

    func avplayer(_ avplayer: SZAVPlayer, refreshed currentTime: Float64, loadedTime: Float64, totalTime: Float64) {
//        cdPrint("refreshed currentTime: \(currentTime), loadedTime: \(loadedTime), totalTime: \(totalTime)")
        let progress = currentTime / totalTime
        callLoadedHandler()
        playingProgressHandler?(Float(progress))
    }

    func avplayer(_ avplayer: SZAVPlayer, didChanged status: SZAVPlayerStatus) {
        switch status {
        case .readyToPlay:
            cdPrint("ready to play: \(String(describing: avplayer.currentURLStr))")
            
            callLoadedHandler()
            //reset retry count
            retryTime = 0
            
            if let item = avplayer.playerItem {
                duration = String(format: "%.f", CMTimeGetSeconds(item.duration)).float() ?? 0
            } else {
                duration = 0
            }
            
            if playerControllerEvent == .playing {
                videoPlayer.play()
            }
        case .playEnd:
            cdPrint("play end: \(String(describing: avplayer.currentURLStr))")
//            handlePlayEnd()
            replay()
        case .loading:
            cdPrint("loading: \(String(describing: avplayer.currentURLStr))")
        case .loadingFailed:
            guard retryTime < 10, let config = self.config else {
                callLoadedHandler()
                return
            }
            cdPrint("loading failed: \(String(describing: avplayer.currentURLStr))")
            mainQueueDispatchAsync(after: 1 + Double(retryTime)) { [weak self] in
                guard let `self` = self,
                      config.urlStr == self.config?.urlStr else {
                    return
                }
                self.retryTime += 1
                self.videoPlayer.reset(cleanAsset: true)
                self.videoPlayer.setupPlayer(config: config)
            }
        case .bufferBegin:
            cdPrint("buffer begin: \(String(describing: avplayer.currentURLStr))")
        case .bufferEnd:
            cdPrint("buffer end: \(String(describing: avplayer.currentURLStr))")
            callLoadedHandler()
            if playerControllerEvent == .stalled {
                videoPlayer.play()
            }
        case .playbackStalled:
            cdPrint("playback stalled: \(String(describing: avplayer.currentURLStr))")
            playerControllerEvent = .stalled
        }
    }

    func avplayer(_ avplayer: SZAVPlayer, didReceived remoteCommand: SZAVPlayerRemoteCommand) -> Bool {
        return false
    }

    func avplayer(_ avplayer: SZAVPlayer, didOutput videoImage: CGImage) {

    }

}

extension PlayerView {
    func setAudioMode() {
        do {
            try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch (let err){
            print("setAudioMode error:" + err.localizedDescription)
        }
    }
}
