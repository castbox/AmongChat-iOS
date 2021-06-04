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
import VIMediaCache

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
    
    private var resourceLoaderManager: VIResourceLoaderManager?
    
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
        SZAVPlayerCache.shared.setup(maxCacheSize: 50)
        
        videoPlayer.reset(cleanAsset: true)
        
        cdPrint("configure url: \(url)")
        
        retryTime = 0
        
        var config = SZAVPlayerConfig(urlStr: url.absoluteString, uniqueID: nil, isVideo: true, isVideoOutputEnabled: false)
        config.timeObserverInterval = 0.05
        config.videoGravity = (size.0 < size.1) ? .resizeAspectFill : .resizeAspect
        videoPlayer.setupPlayer(config: config)
        self.config = config
        
        self.originalURL = url
        self.loadHandler = loadHandler
    }
    
    func set(progress: CGFloat) {
//        guard let item = queuePlayer?.currentItem?.asset, progress >= 0 else {
//            return
//        }
//        let duration = item.duration
        videoPlayer.seekPlayerToTime(time: Float64(progress)) { result in
            
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
            guard retryTime < 3, let config = self.config else {
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


//class PlayerView: UIView {
//
//    // MARK: - Variables
//    private var videoURL: URL?
//    private var originalURL: URL?
//
//    private var playerItem: AVPlayerItem?
//    private var avPlayerLayer: AVPlayerLayer!
//    private var playerLooper: AVPlayerLooper! // should be defined in class
//    private var queuePlayer: AVQueuePlayer?
//    private var observer: NSKeyValueObservation?
//    private var timeObserver: Any?
//
//    private var resourceLoaderManager: VIResourceLoaderManager?
//
//    private(set) var duration: Float = 0
//    private(set) var currentTime: Float = 0
//
//    var playingProgressHandler: ((Float) -> Void)?
//    var loadHandler: CallBack?
//
//    // MARK: - Initializers
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        configureSubview()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        configureSubview()
//    }
//
//    deinit {
//        removeObserver()
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        backgroundColor = .clear
//        avPlayerLayer.frame = self.layer.bounds
//    }
//
//    func configureSubview() {
//        avPlayerLayer = AVPlayerLayer(player: queuePlayer)
////        avPlayerLayer.videoGravity = .resizeAspectFill
//        layer.addSublayer(self.avPlayerLayer)
//    }
//
//    func configure(url: URL?, size: (Int, Int), loadHandler: CallBack?) {
//        // If Height is larger than width, change the aspect ratio of the video
//        avPlayerLayer.videoGravity = (size.0 < size.1) ? .resizeAspectFill : .resizeAspect
//        guard let url = url else {
//            return
//        }
//        cancelAllLoadingRequest()
//
//        cdPrint("configure url: \(url)")
//        self.originalURL = url
//        self.loadHandler = loadHandler
//
//        resourceLoaderManager = VIResourceLoaderManager()
//        playerItem = resourceLoaderManager?.playerItem(with: url)
//        addObserverToPlayerItem()
//        //
//        if VICacheManager.cacheConfiguration(for: url).progress >= 1.0 {
//            callLoadedHandler()
//        }
//
//        if let queuePlayer = self.queuePlayer {
//            queuePlayer.replaceCurrentItem(with: playerItem)
//        } else {
//            queuePlayer = AVQueuePlayer(playerItem: playerItem)
//            queuePlayer?.automaticallyWaitsToMinimizeStalling = false
//        }
//
//        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: queuePlayer!.currentItem!)
//
//        avPlayerLayer.player = queuePlayer
//
//        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
//        timeObserver = queuePlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue(label: "chat.among.player.queue"), using: { [weak self] time in
//            mainQueueDispatchAsync {
//                guard let `self` = self, let item = self.playerItem else {
//                    return
//                }
//                self.callLoadedHandler()
//                self.duration = String(format: "%.f", CMTimeGetSeconds(item.duration)).float() ?? 0
//                let currentTime = time.value.cgFloat / CGFloat(time.timescale)
//                if !currentTime.isNaN {
//                    self.currentTime = currentTime.float
//                } else {
//                    self.currentTime = 0
//                }
//                let progress = self.currentTime / self.duration
////                cdPrint("currentTime: \(self.currentTime) \(time) duration: \(self.duration) progress: \(progress)")
//                self.playingProgressHandler?(progress)
//            }
//        })
//
//    }
//
//    func set(progress: CGFloat) {
//        guard let item = queuePlayer?.currentItem?.asset, progress >= 0 else {
//            return
//        }
//        let duration = item.duration
//        let seekTo = CMTime(value: CMTimeValue((duration.value.cgFloat * progress)), timescale: duration.timescale)
//        queuePlayer?.seek(to: seekTo, completionHandler: { [weak self] result in
//
//        })
//    }
//
//    func replay(){
//        self.queuePlayer?.seek(to: .zero)
//        play()
//    }
//
//    func play() {
//        self.queuePlayer?.play()
//    }
//
//    func pause(){
//        self.queuePlayer?.pause()
//    }
//
//}

//private extension PlayerView {
//
//    func cancelAllLoadingRequest(){
//        removeObserver()
//
//        videoURL = nil
//        originalURL = nil
//        playerItem = nil
//        avPlayerLayer.player = nil
//        playerLooper = nil
//
//    }
//
//    func removeObserver() {
//        if let observer = observer {
//            observer.invalidate()
//        }
//        removePlayerTimeObserver()
//    }
//
//    func removePlayerTimeObserver() {
//        if let observer = timeObserver {
//            queuePlayer?.removeTimeObserver(observer)
//        }
//        timeObserver = nil
//    }
//
//    func addObserverToPlayerItem() {
//        // Register as an observer of the player item's status property
//        self.observer = self.playerItem!.observe(\.status, options: [.initial, .new], changeHandler: { [weak self] item, _ in
//            mainQueueDispatchAsync {
//                guard let `self` = self else { return }
//                let status = item.status
//                // Switch over the status
//                switch status {
//                case .readyToPlay:
//                    // Player item is ready to play.
//                    cdPrint("Status: readyToPlay \(self.originalURL)")
//                    guard let item = self.playerItem else {
//                        return
//                    }
//                    self.duration = CMTimeGetSeconds(item.duration).float ?? 0
//                    self.callLoadedHandler()
//                case .failed:
//                    // Player item failed. See error.
//                    self.callLoadedHandler()
//                    cdPrint("Status: failed Error: " + item.error!.localizedDescription + " \(self.originalURL)")
//                case .unknown:
//                    // Player item is not yet ready.bn m
//                    cdPrint("Status: unknown  \(self.originalURL)")
//                @unknown default:
//                    fatalError("Status is not yet ready to present \(self.originalURL)")
//                }
//            }
//        })
//    }
//
//    func callLoadedHandler() {
//        loadHandler?()
//        loadHandler = nil
//    }
//}
