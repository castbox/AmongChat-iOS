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
import SnapKit
import AgoraRtcKit
import SwiftyUserDefaults

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
    @IBOutlet weak var connectStateLabel: UILabel!
    
    @IBOutlet weak var numberLabel: UILabel!
    private lazy var mManager: ChatRoomManager = {
        let manager = ChatRoomManager.shared
        manager.delegate = self
        return manager
    }()
    @IBOutlet weak var channelTextField: UITextField!
    @IBOutlet weak var screenContainer: UIView!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var pushToTalkButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    
    private lazy var searchController: SearchViewController = {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        controller.viewModel = viewModel
        return controller
    }()
    
    private let viewModel = SearchViewModel()
    private var channelName: String? {
        didSet {
            channelTextField.text = channelName
            //save to cache
            Defaults[.channelName] = channelName
        }
    }
    
    private let bag = DisposeBag()
    
    var myUserId: String {
        return String(Constant.sUserId)
    }
    var timer: SwiftTimer?
    var userStatus: UserStatus = .audiance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubview()
        bindSubviewEvent()
        //
        channelName = Defaults[.channelName]
        channelTextField.text = channelName

        requestRoomList()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func playMusicAction(_ sender: Any) {
        userStatus = .music
        updateRole(true)
    }
    
    @IBAction func upChannelAction(_ sender: Any) {
        guard let channelName = channelName,
            let room = viewModel.previousRoom(channelName) else {
            return
        }
        joinChannel(room.channel_name)
    }
    
    @IBAction func downChannelAction(_ sender: Any) {
        guard let channelName = channelName,
            let room = viewModel.nextRoom(channelName) else {
            return
        }
        joinChannel(room.channel_name)
    }
    
    @IBAction func connectChannelAction(_ sender: UIButton) {
        let connectingState: [AgoraConnectionStateType] = [
            .connecting,
            .connected,
            .reconnecting
        ]
        if connectingState.contains(mManager.state) {
            //disconnect
            mManager.leaveChannel()
            sender.setImage(R.image.btn_power(), for: .normal)
        } else {
            joinChannel(channelName)
        }
        HapticFeedback.Impact.medium()
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        guard let channelName = channelName else {
            return
        }
        let shareString = """
        #\(channelName) is my Walkie Talkie Channel. Free download to talk with me.
        Android: https://play.google.com/store/apps/details?id=com.talkie.walkie
        iOS: https://apps.apple.com/app/id1505959099
        """
        
        let textToShare = shareString
        //         let imageToShare = UIImage.init(named: "img_01")
        //         let urlToShare = NSURL.init(string: "http://www.baidu.com")
        let items = [textToShare] as [Any]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.completionWithItemsHandler =  { activity, success, items, error in
//            print(activity)
//            print(success)
//            print(items)
//            print(error)
        }
        present(activityVC, animated: true, completion: { () -> Void in
            
        })
    }
    
    func joinChannel(_ name: String?) {
        guard let name = name else {
            return
        }
        if mManager.state == .connected && name == channelName {
           return
        }
        channelName = name
        mManager.joinChannel(channelId: name)
    }
    
    func playAudio(type: AudioType, completionHandler: (() -> Void)? = nil) {
        timer?.cancel()
        timer = nil
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

// MARK: - ChatRoomDelegate
extension ViewController: ChatRoomDelegate {

    func onConnectionChangedTo(state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        connectStateLabel.text = state.title.uppercased()
        if state == .connected {
            powerButton.setImage(R.image.btn_power_on(), for: .normal)
        } else {
            powerButton.setImage(R.image.btn_power(), for: .normal)
        }
        updateMemberCountLabel()
        updateButtonsEnable()
    }
    
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
        updateMemberCountLabel()
    }

    func onUserStatusChanged(userId: String, muted: Bool) {
        debugPrint("uid: \(userId) muted: \(muted)")
        if Constant.isMyself(userId) {
            
            if !muted {
                if userStatus == .broadcaster {
                    playAudio(type: .begin)
                    pushToTalkButton.isHidden = true
                } else if userStatus == .music {
                    playAudio(type: .call) { [weak self] in
                        self?.mManager.updateRole(false)
                    }
                }
            } else {
                //已链接，但为上麦，提示上麦说话
                pushToTalkButton.isHidden = false
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

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.rangeOfCharacter(from: .letters) != nil || string.rangeOfCharacter(from: .alphanumerics) != nil || string == ""{
            searchController.set(textField.text?.uppercased() ?? "")
            return true
        }else {
            return false
        }
    }
    
}

private extension ViewController {
    
    func updateButtonsEnable() {
        switch mManager.state {
        case .connected:
            speakButton.isEnabled = true
            musicButton.isEnabled = true
        case .connecting:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
        case .reconnecting:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
        case .disconnected:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
        case .failed:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
        default:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
        }
    }
    
    func updateMemberCountLabel() {
//        if mManager.state == .connected {
//            numberLabel.text = mManager.getChannelData().getMemberArray().count.string
//        } else {
            numberLabel.text = nil
//        }
    }
    
    func showSearchView() {
        guard searchController.view.superview == nil else {
            return
        }

        searchController.willMove(toParent: self)
        view.addSubview(searchController.view)
        searchController.didMove(toParent: self)
        searchController.view.snp.makeConstraints { make in
            make.width.equalTo(screenContainer.snp.width)
            make.leading.equalTo(screenContainer.snp.leading)
            make.top.equalTo(screenContainer.snp.bottom).offset(-12)
            make.height.equalTo(300)
        }
    }
    
    func hideSearchView() {
        searchController.willMove(toParent: nil)
        searchController.removeFromParent()
        searchController.view.removeFromSuperview()
        view.endEditing(true)
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
    
    func bindSubviewEvent() {
        viewModel.startListenerList()
        
//        mManager.stateObservable
//            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { state in
//                
//            })
        speakButton.rx.isHighlighted
            .skip(1)
            .subscribe(onNext: { [weak self] highlighted in
                print("speakButton is highlighted: \(highlighted)")
                self?.userStatus = highlighted ? .broadcaster : .audiance
                self?.updateRole(highlighted)
            })
            .disposed(by: bag)
        
        channelTextField.rx.controlEvent(.editingDidBegin)
            .subscribe(onNext: { [weak self] _ in
                self?.showSearchView()
            })
            .disposed(by: bag)
        
        channelTextField.rx.controlEvent(.editingDidEnd)
            .subscribe(onNext: { [weak self] _ in
                self?.joinChannel(self?.channelTextField.text?.uppercased())
                self?.hideSearchView()
            })
            .disposed(by: bag)
        
//        channelTextField.rx.controlEvent(.editingChanged)
//            .subscribe(onNext: { [weak self] _ in
//            })
//            .disposed(by: bag)
        
        searchController.selectRoomHandler = { [weak self] room in
            self?.joinChannel(room.channel_name)
            self?.hideSearchView()
        }
    }
    
    func configureSubview() {
        
    }
}

extension AgoraConnectionStateType {
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
        }
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


extension Collection where Element: StringProtocol {
    public func localizedStandardSorted(_ result: ComparisonResult) -> [Element] {
        return sorted { $0.localizedStandardCompare($1) == result }
    }
}
