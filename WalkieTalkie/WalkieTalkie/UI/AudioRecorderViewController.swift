//
//  AudioRecorderViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/10.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVKit

class AudioRecorderViewController: WalkieTalkie.ViewController {
    
    private lazy var timeLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 24)
        lb.textColor = .white
        lb.textAlignment = .center
        return lb
    }()
    
    private typealias CircularProgressView = AmongChat.Home.RoomInvitationModal.CircularProgressView
    private lazy var circleView: CircularProgressView = {
        let v = CircularProgressView()
        
        v.backgroundColor = .clear
        
        v.circleLineWidth = 0
        v.circleLineColor = .clear
        v.circleBackgroundColor = .clear
        
        v.progressLineWidth = 4.5
        v.progressLineColor = UIColor(hex6: 0xFFF000)
        v.progressBackgroundColor = .clear
        
        return v
    }()
    
    private lazy var micButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.setImage(R.image.ac_chat_speak(), for: .normal)
        return btn
    }()
    
    private lazy var tipLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 16)
        lb.textColor = UIColor(hex6: 0x898989)
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.text = R.string.localizable.amongChatAudioRecordingTimeLimit()
        return lb
    }()
    
    private lazy var cancelTipLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 16)
        lb.text = R.string.localizable.amongChatAudioRecordingSlideCancel()
        lb.textColor = .white
        lb.textAlignment = .center
        return lb
    }()
    
    private lazy var endTipLabel: UILabel = {
        let lb = UILabel()
        lb.clipsToBounds = true
        lb.font = R.font.nunitoExtraBold(size: 16)
        lb.text = R.string.localizable.amongChatAudioRecordingEnd()
        lb.textColor = .black
        lb.textAlignment = .center
        return lb
    }()
    
    var endTipLabelFrame: CGRect? = nil {
        didSet {
            guard let frame = endTipLabelFrame else {
                return
            }
            endTipLabel.snp.remakeConstraints { (maker) in
                maker.size.equalTo(frame.size)
                maker.left.equalTo(frame.origin.x)
                maker.top.equalTo(frame.origin.y)
            }
        }
    }
    
    private let sm = SM()
    private let countdown = 60
    private var recordedSeconds = 0
    private var recorder: AVAudioRecorder? = nil
    private lazy var savedFileURL: URL = {
        let user = Settings.shared.loginResult.value?.uid.string ?? "anonymous"
//        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
//                                                          .userDomainMask,
//                                                          true).last! + "/\(user)/temp/audio/"
//
//        if FileManager.default.fileExists(atPath: dirPath) == false {
//            do {
//                try FileManager.default.createDirectory(at: URL(fileURLWithPath: dirPath, isDirectory: true), withIntermediateDirectories: true)
//            } catch let error {
//
//            }
//        }
        
        let filePath = FileManager.voiceFilePath(with: "\(Date().timeIntervalSince1970).aac") ?? ""
        let fileURL = URL(fileURLWithPath: filePath)
        
        return fileURL
    }()
    
    fileprivate let recordedAudioFileSubject = PublishSubject<(URL, Int)>()
    private let recorderFinishedSuccess = ReplaySubject<Bool>.create(bufferSize: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        setUpEvents()
        startRecording()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        endTipLabel.layer.cornerRadius = endTipLabel.bounds.height / 2
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let pt = touches.first?.location(in: view) ?? .zero
        if endTipLabel.frame.contains(pt) {
            sm.eventOccurs(.touchesMoveIn)
        } else {
            sm.eventOccurs(.touchesMoveOut)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let pt = touches.first?.location(in: view) ?? .zero
        if endTipLabel.frame.contains(pt) {
            sm.eventOccurs(.touchesMoveIn)
        } else {
            sm.eventOccurs(.touchesMoveOut)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        sm.eventOccurs(.touchesEnd)
    }
}

extension AudioRecorderViewController {
    
    private func setUpLayout() {
        
        view.backgroundColor = UIColor.black.alpha(0.88)
        view.addSubviews(views: timeLabel, micButton, circleView, tipLabel, cancelTipLabel, endTipLabel)
        
        let centerContentLayout = UILayoutGuide()
        view.addLayoutGuide(centerContentLayout)
        centerContentLayout.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.centerY.equalToSuperview().offset(ceil(UIScreen.main.bounds.height * 0.02))
        }
        
        timeLabel.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalTo(centerContentLayout)
            maker.height.equalTo(33)
        }
        
        micButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(timeLabel.snp.bottom).offset(30)
            maker.centerX.equalTo(centerContentLayout)
            maker.width.height.equalTo(92)
        }
        
        circleView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(micButton).inset(-16)
        }
        
        tipLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalTo(centerContentLayout)
            maker.top.equalTo(micButton.snp.bottom).offset(30)
        }
        
        cancelTipLabel.snp.makeConstraints { (maker) in
            maker.centerX.bottom.equalTo(centerContentLayout)
            maker.top.equalTo(tipLabel.snp.bottom).offset(12)
        }
        
        endTipLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(64)
            maker.height.equalTo(36)
            maker.bottom.equalTo(-46)
        }
        
    }
    
    private func setUpEvents() {
        sm.stateObservable
            .subscribe(onNext: { [weak self] (state) in
                guard let `self` = self else { return }
                switch state {
                case .normalRecording:
                    self.updateUI(false)
                case .aboutToQuitRecording:
                    self.updateUI(true)
                case .quitRecording(let error):
                    self.stopRecording(with: error)
                case .finishRecording:
                    if self.recordedSeconds < 1 {
                        self.stopRecording(with: MsgError(code: -101, msg: R.string.localizable.amongChatAudioRecordingTooShort()))
                    } else {
                        self.stopRecording()
                    }
                }
            })
            .disposed(by: bag)
        
        Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
            .take(countdown + 1)
            .subscribe(onNext: { [weak self] timePassed in
                guard let `self` = self else { return }
                self.recordedSeconds = timePassed
                let m = timePassed / 60
                let s = timePassed % 60
                self.timeLabel.text = "\(m):\(s)"
            }, onCompleted: { [weak self] in
                self?.sm.eventOccurs(.timeout)
            })
            .disposed(by: bag)
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.circleView.updateProgress(fromValue: 0, toValue: 1, animationDuration: Double(self.countdown))
            })
            .disposed(by: bag)
        
    }
    
    private func startRecording() {
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord)
        } catch let error{
            self.sm.eventOccurs(.error(error))
        }
        
        do {
            try session.setActive(true)
        } catch let error {
            self.sm.eventOccurs(.error(error))        }
        
        let recordSetting: [String : Any] = [
            AVFormatIDKey : NSNumber(value: kAudioFormatMPEG4AAC),
            AVLinearPCMBitDepthKey : NSNumber(value: 16),
            AVNumberOfChannelsKey : NSNumber(value: 1),
            AVEncoderAudioQualityKey : NSNumber(value: AVAudioQuality.min.rawValue),
            AVSampleRateKey : 44100
        ]
        
        do {
            let recorder = try AVAudioRecorder(url: savedFileURL, settings: recordSetting)
            recorder.delegate = self
            recorder.prepareToRecord()
            recorder.record()
            self.recorder = recorder
        } catch let error {
            self.sm.eventOccurs(.error(error))
        }
        
    }
    
    private func stopRecording(with error: Error? = nil) {
        
        recorder?.stop()
        if let error = error {
            recordedAudioFileSubject.onError(error)
            do {
                try FileManager.default.removeItem(at: savedFileURL)
            } catch let _ {
                cdPrint("")
            }
        } else {
            
            recorderFinishedSuccess
                .map({ (success) -> (URL, Int) in
                    guard success else {
                        throw MsgError.default
                    }
                    
                    return (self.savedFileURL, self.recordedSeconds)
                })
                .bind(to: recordedAudioFileSubject)
                .disposed(by: bag)
            
        }
        dismiss(animated: false)
        
    }
    
    private func updateUI(_ toCancelStyle: Bool) {
        
        if toCancelStyle {
            cancelTipLabel.textColor = UIColor(hex6: 0xFB5858)
            cancelTipLabel.text = R.string.localizable.amongChatAudioRecordingReleaseCancel()
            endTipLabel.backgroundColor = UIColor(hex6: 0xFB5858)
            micButton.setImage(R.image.ac_chat_speak_cancel(), for: .normal)
        } else {
            cancelTipLabel.textColor = .white
            cancelTipLabel.text = R.string.localizable.amongChatAudioRecordingSlideCancel()
            endTipLabel.backgroundColor = UIColor(hex6: 0xFFF000)
            micButton.setImage(R.image.ac_chat_speak(), for: .normal)
        }
        
    }
}

extension AudioRecorderViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recorderFinishedSuccess.onNext(flag)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        guard let error = error else {
            return
        }
        sm.eventOccurs(.error(error))
    }
}

extension AudioRecorderViewController {
    
    class SM {
        
        enum State {
            case normalRecording
            case aboutToQuitRecording
            case quitRecording(Error)
            case finishRecording
        }
        
        enum Event {
            case timeout
            case touchesEnd
            case touchesMoveOut
            case touchesMoveIn
            case error(Error)
        }
        
        private let state = BehaviorRelay<State>(value: .normalRecording)
        var stateObservable: Observable<State> {
            return state.asObservable()
        }
        
        func eventOccurs(_ event: Event) {
            
//            cdPrint("====SM====current state: \(state.value), event: \(event)")
            
            switch state.value {
            case .normalRecording:
                switch event {
                case .timeout, .touchesEnd:
                    state.accept(.finishRecording)
                    
                case .touchesMoveOut:
                    state.accept(.aboutToQuitRecording)
                    
                case .error(let error):
                    state.accept(.quitRecording(error))
                    
                default:
                    ()
                }
                
            case .aboutToQuitRecording:
                switch event {
                case .touchesMoveIn:
                    state.accept(.normalRecording)
                    
                case .timeout:
                    state.accept(.finishRecording)
                    
                case .touchesEnd:
                    let error = MsgError.init(code: -100, msg: R.string.localizable.amongChatAudioRecordingCanceled())
                    state.accept(.quitRecording(error))
                    
                case .error(let error):
                    state.accept(.quitRecording(error))
                    
                default:
                    ()
                }
                
            default:
                ()
                
            }
            
//            cdPrint("====SM====transfer to state: \(state.value)")
        }
        
    }
    
}
    
class HoldToTalkButton: UIButton {
    
    private weak var recorder: AudioRecorderViewController? = nil
    
    private let audioFileSubject = PublishSubject<Single<(URL, Int)>>()
    var audioFileObservable: Observable<Single<(URL, Int)>> {
        return audioFileSubject.asObservable()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            
            UIApplication.topViewController()?.checkMicroPermission(title: R.string.localizable.microphoneNotAllowTitle(),
                                                                    message: nil,
                                                                    completion: {})
            return
        }
        
        let recorder = AudioRecorderViewController()
        recorder.modalPresentationStyle = .overCurrentContext
        UIApplication.topViewController()?.present(recorder, animated: false) {
            recorder.touchesBegan(touches, with: event)
        }
        let frameInController = UIApplication.topViewController()?.view.convert(frame, from: superview)
        recorder.endTipLabelFrame = frameInController
        self.recorder = recorder
        audioFileSubject.onNext(recorder.recordedAudioFileSubject.take(1).asSingle())
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        recorder?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        recorder?.touchesEnded(touches, with: event)
    }
    
}
