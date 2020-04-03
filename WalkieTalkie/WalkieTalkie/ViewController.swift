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
        
        channelName = Defaults[.channelName]
        configureSubview()
        bindSubviewEvent()
        channelTextField.text = channelName
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
        joinChannel(room.name)
    }
    
    @IBAction func downChannelAction(_ sender: Any) {
        guard let channelName = channelName,
            let room = viewModel.nextRoom(channelName) else {
            return
        }
        joinChannel(room.name)
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
            HapticFeedback.Impact.medium()
        } else {
            joinChannel(channelName)
        }
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        guard let channelName = channelName else {
            return
        }
        let url = "https://apps.apple.com/app/id1505959099"
        let shareString = """
        #\(channelName) is my Walkie Talkie Channel. Free download to talk with me.
        iOS: https://apps.apple.com/app/id1505959099
        Android: https://play.google.com/store/apps/details?id=com.talkie.walkie
        """
        
        let textToShare = shareString
        let imageToShare = R.image.share_logo()!
        let urlToShare = NSURL(string: url)
        let items = [textToShare, imageToShare, urlToShare] as [Any]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.completionWithItemsHandler =  { activity, success, items, error in

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
        HapticFeedback.Impact.medium()
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
                if mManager.state == .connected {
                    pushToTalkButton.isHidden = false
                }
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        sendQueryEvent()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        let checkLength = checkTextLength(textField, shouldChangeCharactersIn: range, replacementString: string)
        let length = textField.text?.count ?? 0
        let result = length >= 2 && length <= 8
        if result {
            _ = textField.resignFirstResponder()
        }
        return result
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let set = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-").inverted
        let filteredString = string.components(separatedBy: set).joined(separator: "")
        let checkLength = checkTextLength(textField, shouldChangeCharactersIn: range, replacementString: string)
        if filteredString == string && checkLength {
//             sendQueryEvent()
            return true
        }else {
            return false
        }
    }
    
    func checkTextLength(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let limitation = 8
        let currentLength = textField.text?.count ?? 0 // 当前长度
        if (range.length + range.location > currentLength){
            return false
        }
        // 禁用启用按钮
        let newLength = currentLength + string.count - range.length // 加上输入的字符之后的长度
        return newLength <= limitation
    }
}

private extension ViewController {
    
    func sendQueryEvent() {
        if let text = channelTextField.text?.uppercased(),
            text.count >= 2,
            text != channelName {
            searchController.set(query: text)
        } else {
            searchController.set(query: "")
        }
    }
    
    func updateButtonsEnable() {
        switch mManager.state {
        case .connected:
            speakButton.isEnabled = true
            musicButton.isEnabled = true
            pushToTalkButton.isHidden = false
//        case .connecting:
//            speakButton.isEnabled = false
//            musicButton.isEnabled = false
//            pushToTalkButton.isHidden = true
//        case .reconnecting:
//            speakButton.isEnabled = false
//            musicButton.isEnabled = false
//            pushToTalkButton.isHidden = true
//        case .disconnected:
//            speakButton.isEnabled = false
//            musicButton.isEnabled = false
//            pushToTalkButton.isHidden = true
//        case .failed:
//            speakButton.isEnabled = false
//            musicButton.isEnabled = false
//            pushToTalkButton.isHidden = true
        default:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
            pushToTalkButton.isHidden = true
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
    
    func bindSubviewEvent() {
        viewModel.startListenerList()
    
        if channelName.wrappedValue.isEmpty {
             viewModel.hotRoomsSubject
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] rooms in
                    self?.channelName = rooms.first?.name
                    self?.channelTextField.text = rooms.first?.name
                })
                .disposed(by: bag)
        }
        
        speakButton.rx.isHighlighted
            .skip(1)
            .subscribe(onNext: { [weak self] highlighted in
//                print("speakButton is highlighted: \(highlighted)")
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
        
        channelTextField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                self?.sendQueryEvent()
            })
            .disposed(by: bag)
        
        searchController.selectRoomHandler = { [weak self] room in
            self?.joinChannel(room.name)
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

extension Optional where Wrapped == String {
    var wrappedValue: String {
        return self ?? ""
    }
}

