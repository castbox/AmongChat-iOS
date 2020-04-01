//
//  ViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import SwifterSwift
//iPhone 106274582
//Wilson iPhone 1761995123
enum AudioType: String {
    case begin
    case end
    case call
}

enum UserStatus {
    case audiance
    case broadcaster
    case music
}

extension AudioType {
    var name: String {
        return rawValue
    }
    var type: String {
        switch self {
        case .end, .begin:
            return ".mp3"
        case .call:
            return ".m4a"
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet private weak var speakButton: UIButton!
    
    @IBOutlet weak var numberLabel: UILabel!
    private lazy var mManager: ChatRoomManager = {
        let manager = ChatRoomManager.shared
        manager.delegate = self
        return manager
    }()
    
    private var channelName: String?
    private let bag = DisposeBag()
    var myUserId: String {
        return String(Constant.sUserId)
    }
    var timer: SwiftTimer?
    var userStatus: UserStatus = .audiance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        channelName = "#TAG"
        joinChannel()
        speakButton.rx.isHighlighted
            .skip(1)
            .subscribe(onNext: { [weak self] highlighted in
                print("speakButton is highlighted: \(highlighted)")
                self?.userStatus = highlighted ? .broadcaster : .audiance
                self?.updateRole(highlighted)
            })
            .disposed(by: bag)
        requestRoomList()
    }
    
    func requestRoomList() {
        let username = "152962b42c514918b8a15074dd6c0438"
        let password = "cc0cbe7b82b6447fa6c77e88b187ce14"
        let loginString = String(format: "%@:%@", username, password)
        // 填入 loginString，计算 loginData。
        let loginData = loginString.data(using: String.Encoding.utf8)!
        // 填入 loginData（使用 Base64 算法编码的 LoginData），计算 base64LoginString，即你要的 Authorization 字段。
        let base64LoginString = loginData.base64EncodedString()
        
        let headers = [
            "Authorization": "Basic \(base64LoginString)",
            "Accept": "application/json",
            "Content-Type": "application/json" ]
        Alamofire.request("https://api.agora.io/dev/v1/channel/06040a98af684c5f9306350bbce03acb", method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers) .responseJSON { response in
            if let value = response.result.value as? [String: Any] {
                //Handle the results as JSON
                print(value)
            }
        }
    }
    
    @IBAction func playMusicAction(_ sender: Any) {
        userStatus = .music
        updateRole(true)
    }
    
    @IBAction func upChannelAction(_ sender: Any) {
        
    }
    
    @IBAction func downChannelAction(_ sender: Any) {
        mManager.muteMic(myUserId, !mManager.getChannelData().isUserMuted(myUserId))
    }
    
    @IBAction func connectChannelAction(_ sender: Any) {
        
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        
    }
    
    func joinChannel() {
        guard let channelName = channelName else {
            return
        }
        mManager.joinChannel(channelId: channelName)
    }
    
    func playAudio(type: AudioType, completionHandler: (() -> Void)? = nil) {
        timer?.cancel()
        timer = nil
//        mManager.getRtcManager().stopAudioMixing()
        mManager.getRtcManager().startAudioMixing(Bundle.main.path(forResource: type.name, ofType: type.type))
        let duration = mManager.getRtcManager().getAudioMixingDuration()
        timer = SwiftTimer(interval: .milliseconds(duration)) { [weak self] timer in
//            self?.mManager.getRtcManager().stopAudioMixing()
            completionHandler?()
        }
        timer?.start()
    }
    
    func updateRole(_ isPublisher: Bool) {
        if isPublisher {
            mManager.updateRole(isPublisher)
        } else {
            playAudio(type: .end) { [weak self] in
                self?.mManager.updateRole(isPublisher)
            }
        }
    }
}

extension ViewController: ChatRoomDelegate {
    // MARK: - ChatRoomDelegate

    func onSeatUpdated(position: Int) {
//        mSeatVC?.reloadItems(position)
    }

    func onUserGivingGift(userId: String) {
//        gift.show(userId)
    }

    func onMessageAdded(position: Int) {
//        mMessageVC?.insertRows(position)
    }

    func onMemberListUpdated(userId: String?) {
//        num.setTitle(String(mManager.getChannelData().getMemberArray().count), for: .normal)
//        mSeatVC?.reloadItems(userId)
//        mMemberVC?.reloadData()
        numberLabel.text = mManager.getChannelData().getMemberArray().count.string
    }

    func onUserStatusChanged(userId: String, muted: Bool) {
        debugPrint("uid: \(userId) muted: \(muted)")
        if Constant.isMyself(userId) {
            if !muted {
                if userStatus == .broadcaster {
                    playAudio(type: .begin)
                } else {
                    playAudio(type: .call) { [weak self] in
                        self?.mManager.updateRole(false)
                    }
                }
            } else {

            }
        }
//        mSeatVC?.reloadItems(userId)
//        mMemberVC?.reloadRowsByUserId(userId)
        
    }

    func onAudioMixingStateChanged(isPlaying: Bool) {

    }

    func onAudioVolumeIndication(userId: String, volume: UInt) {

    }
}

extension Reactive where Base: UIButton {
    var isHighlighted: Observable<Bool> {
        let anyObservable = self.base.rx.methodInvoked(#selector(setter: self.base.isHighlighted))

        let boolObservable = anyObservable
            .flatMap { Observable.from(optional: $0.first as? Bool) }
            .startWith(self.base.isHighlighted)
            .distinctUntilChanged()
            .share()

        return boolObservable
    }
}
