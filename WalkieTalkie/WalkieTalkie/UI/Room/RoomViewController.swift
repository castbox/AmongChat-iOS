//
//  RoomViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
//import Alamofire
import SwifterSwift
import SnapKit
import AgoraRtcKit
import SwiftyUserDefaults
import MoPub
import RxGesture

enum UserStatus {
    case audiance
    case broadcaster
    case music
    case end
}

class RoomViewController: ViewController {
    @IBOutlet private weak var speakButton: UIButton!
    @IBOutlet weak var speakButtonTrigger: UIView!
    
    private lazy var mManager: ChatRoomManager = {
        let manager = ChatRoomManager.shared
        manager.delegate = self
        return manager
    }()
    
    @IBOutlet weak var screenBackgroundView: UIImageView!
    @IBOutlet weak var connectStateLabel: UILabel!
    @IBOutlet weak var tagView: UILabel!
    @IBOutlet weak var lockIconView: UIImageView!
    @IBOutlet weak var channelTextField: ChannelNameField!
    @IBOutlet weak var micView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
//    @IBOutlet weak var screenContainer: UIView!
    @IBOutlet weak var screenContainer: ScreenContainer!
    @IBOutlet weak var buttonContainer: UIView!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var pushToTalkButton: UIButton!
    @IBOutlet weak var musicButton: FrozenButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var spackButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toolsView: UIView!
    
    private var joinChannelSubject = BehaviorSubject<String?>(value: nil)
    private lazy var viewModel = RoomViewModel()

//    private lazy var searchController: SearchViewController = {
//        let controller = R.storyboard.main.searchViewController()!
//        controller.viewModel = searchViewModel
//        return controller
//    }()
    
    @IBOutlet weak var adContainer: UIView!

    private var adView: MPAdView!
    
    private var searchViewModel: SearchViewModel {
        screenContainer.searchViewModel
    }
    
    private var channel: Room! {
        didSet {
//            updateSubviewStyle()
//            updateMemberCount(with: channel)
            screenContainer.channel = channel
            channel.updateJoinInterval()
            Defaults[\.channel] = channel
        }
    }
    
    private var channelName: String {
        return channel.name
    }
    
    private var hotBag: DisposeBag? = DisposeBag()
    
    private var state: ConnectState = .disconnected {
        didSet {
            cdPrint("state: \(state)")
            updateButtonsEnable()
            screenContainer.update(state: state)
        }
    }
    
    var myUserId: String {
        return String(Constant.sUserId)
    }
    var timer: SwiftTimer?
    var userStatus: UserStatus = .audiance
    
    override var screenName: Logger.Screen.Node.Start {
        return .channel
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isNavigationBarHiddenWhenAppear = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSubview()
        bindSubviewEvent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adView?.frame = adContainer.bounds
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard children.isEmpty else {
            return
        }
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func screenContainerTapped(_ sender: Any) {
//        _ = channelTextField.becomeFirstResponder()
        _ = screenContainer.becomeFirstResponder()
    }
    
    func playMusicAction() {
        Logger.UserAction.log(.music)
        userStatus = .music
        if let role = mManager.role, role == .broadcaster {
            playAudio(type: .call) { [weak self] in
                self?.updateRole(false)
            }
        } else {
            updateRole(true)
        }
        Logger.UserAction.log(.channel_up, channelName)
    }
    
    @IBAction func upChannelAction(_ sender: Any) {
        guard let room = searchViewModel.previousRoom(channelName) else {
            return
        }
        self.channel = room
        if mManager.isConnectingState {
            joinChannelSubject.onNext(room.name)
        }
        Logger.UserAction.log(.channel_up, room.name)
    }
    
    @IBAction func downChannelAction(_ sender: Any) {
        guard let room = searchViewModel.nextRoom(channelName) else {
            return
        }
        self.channel = room
        if mManager.isConnectingState {
            joinChannelSubject.onNext(room.name)
        }
        Logger.UserAction.log(.channel_down, room.name)
    }
    
    @IBAction func connectChannelAction(_ sender: UIButton) {
        Logger.UserAction.log(.connect, channelName)
        if mManager.isConnectedState {
            //disconnect
            leaveChannel()
        } else {
            //如果和当前存储相同，
            if channelName.isPrivate {
                if FireStore.shared.isValidSecretChannel(channelName) { //则检查是否存在
                    joinChannel(channelName)
                } else {
                    //show error
                    view.raft.autoShow(.text(R.string.localizable.channelNotExist()))
                }
            } else {
                joinChannel(channelName)
            }
        }
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {

        if channel.isPrivate {
            showShareController(channelName: channelName)
        } else {
            Logger.UserAction.log(.share_channel, channelName)
            shareChannel(name: channelName)
        }
    }
    
    @IBAction func privateButtonAction(_ sender: Any) {
        let controller = AddChannelViewController()
        controller.joinChannel = { [weak self] name, autoShare in
            //join channels
            self?.joinChannelSubject.onNext(name)
            //show code
            if autoShare {
                self?.showShareController(channelName: name)
            }
        }
        controller.showModal(in: self)
        Logger.UserAction.log(.secret)
    }
    
    func leaveChannel() {
        UIApplication.shared.isIdleTimerDisabled = false
        mManager.leaveChannel()
    }
  
    func joinChannel(_ name: String?) {
        joinChannelSubject.onNext(name)
    }
    
    @discardableResult
    private func _joinChannel(_ name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        if mManager.isConnectedState && mManager.channelName == name {
           return false
        }
        channel = FireStore.shared.findValidRoom(with: name)
        guard !channel.isReachMaxUser else {
            //离开当前房间
            leaveChannel()
//            connectStateLabel.text = R.string.localizable.channelUserMaxState()
            screenContainer.update(state: .maxUser)
            return false
        }
        searchViewModel.add(private: name)
        checkMicroPermission { [weak self] in
            guard let `self` = self else { return }
            self.mManager.joinChannel(channelId: name) { [weak self] in
                HapticFeedback.Impact.medium()
                self?.viewModel.requestEnterRoom()
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        return true
    }
    
    func playAudio(type: AudioType, completionHandler: (() -> Void)? = nil) {
        timer?.cancel()
        timer = nil
        mManager.getRtcManager().startAudioMixing(type.path)
        let duration = mManager.getRtcManager().getAudioMixingDuration()
        timer = SwiftTimer(interval: .milliseconds(duration)) { timer in
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
extension RoomViewController: ChatRoomDelegate {
    
    func onJoinChannelFailed(channelId: String?) {
        Observable.just(())
            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .subscribe(onNext: { [weak self] _ in
//                self?.connectStateLabel.text = "OCCOR ERROR"
                self?.screenContainer.update(state: .timeout)
            })
            .disposed(by: bag)
    }
    
    func onJoinChannelTimeout(channelId: String?) {
        Observable.just(())
            .observeOn(MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .do(onNext: { [weak self] _ in
                self?.leaveChannel()
            })
            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .subscribe(onNext: { [weak self] _ in
//                self?.connectStateLabel.text = "TIMEOUT"
                self?.screenContainer.update(state: .timeout)
            })
            .disposed(by: bag)
    }

    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason) {
        self.state = state
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
//        updateMemberCountLabel()
    }

    func onUserStatusChanged(userId: String, muted: Bool) {
        debugPrint("uid: \(userId) muted: \(muted)")
        if Constant.isMyself(userId) {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            if !muted {
                perform(#selector(updateState(with:)), with: muted, afterDelay: 0.4)
                //延迟播音
//                mainQueueDispatchAsync(after: 0.4) { [unowned self] in
//                    if self.userStatus == .broadcaster {
//                        self.state = .talking
//                        HapticFeedback.Impact.light()
//                        self.playAudio(type: .begin)
//                        self.pushToTalkButton.isHidden = true
//                    } else if self.userStatus == .music {
//                        self.playAudio(type: .call) { [weak self] in
//                            self?.mManager.updateRole(false)
//                        }
//                    } else {
//                        self.state = .connected
//                    }
//                }
            } else {
                perform(#selector(updateState(with:)), with: muted)
//                //已链接，但为上麦，提示上麦说话
//                if mManager.state == .connected {
//                    pushToTalkButton.isHidden = false
//                }
//                self.state = .connected
            }
        }
//        mSeatVC?.reloadItems(userId)
//        mMemberVC?.reloadRowsByUserId(userId)
        
    }
    
    @objc
    func updateState(with isMute: Bool) {
        if isMute {
            if mManager.state == .connected {
                pushToTalkButton.isHidden = false
            }
            self.state = .connected
        } else {
            if self.userStatus == .broadcaster {
                self.state = .talking
                HapticFeedback.Impact.medium()
                self.playAudio(type: .begin)
                self.pushToTalkButton.isHidden = true
            } else if self.userStatus == .music {
                self.playAudio(type: .call) { [weak self] in
                    self?.mManager.updateRole(false)
                }
            } else {
                self.state = .connected
            }
        }
    }

    func onAudioMixingStateChanged(isPlaying: Bool) {

    }

    func onAudioVolumeIndication(userId: String, volume: UInt) {

    }
}

private extension RoomViewController {
//    func showCanEnterSecretChannelAlert(_ completionHandler: @escaping (Bool) -> Void) {
//        let alertVC = UIAlertController(title: R.string.localizable.enterSecretChannelAlertTitle(),
//                                        message: R.string.localizable.enterSecretChannelAlertDesc(),
//                                        preferredStyle: UIAlertController.Style.alert)
//        let resetAction = UIAlertAction(title: R.string.localizable.alertOk(), style: .default, handler: { _ in
//            completionHandler(true)
//        })
//        
//        let cancelAction = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel) { _ in
//            completionHandler(false)
//        }
//        alertVC.addAction(cancelAction)
//        alertVC.addAction(resetAction)
//        present(alertVC, animated: true, completion: nil)
//    }
    
    func showShareController(channelName: String) {
        let controller = R.storyboard.main.privateShareController()
        controller?.channelName = channelName
        controller?.showModal(in: self)
    }
    
    /// 获取麦克风权限
    func checkMicroPermission(completion: @escaping ()->()) {
        weak var welf = self
        AVAudioSession.sharedInstance().requestRecordPermission { isOpen in
            if !isOpen {
                let alertVC = UIAlertController(title: NSLocalizedString("“WalkieTalkie” would like to Access the Microphone", comment: ""),
                                                message: NSLocalizedString("To join the channel, please switch on microphone permission.", comment: ""),
                                                preferredStyle: UIAlertController.Style.alert)
                let resetAction = UIAlertAction(title: NSLocalizedString("Go Settings", comment: ""), style: .default, handler: { _ in
                    
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                })
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    /// do nothing
                }
                alertVC.addAction(cancelAction)
                alertVC.addAction(resetAction)
                DispatchQueue.main.async {
                    welf?.present(alertVC, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
//    func sendQueryEvent() {
//        if let text = channelTextField.text?.uppercased(),
//            text.count >= 2,
//            text != channelName.showName {
//            searchController.set(query: text)
//        } else {
//            searchController.set(query: "")
//        }
//    }
    
    func updateButtonsEnable() {
        print("[RoomViewController] updateButtonsEnable with state: \(state.title)")
//        if state == .disconnected,
//            connectStateLabel.text == R.string.localizable.channelUserMaxState() {
//
//        } else {
//            connectStateLabel.text = state.title.uppercased()
//        }
        switch state {
        case .talking:
//            micView.image = R.image.icon_mic()
//            micView.alpha = 1
            speakButton.alpha = 1
        case .maxMic:
//            micView.image = R.image.icon_mic_disable()
//            micView.alpha = 1
            speakButton.alpha = 1
        case .connected, .preparing:
//            micView.image = R.image.icon_mic()
//            micView.alpha = 0.3
            speakButton.isEnabled = true
            speakButton.alpha = 0.6
            musicButton.isEnabled = true
            pushToTalkButton.isHidden = false
            powerButton.setImage(R.image.btn_power_on(), for: .normal)
            powerButton.setBackgroundImage(R.image.home_btn_bg(), for: .normal)
        default:
//            micView.alpha = 0
            speakButton.alpha = 1
            speakButton.isEnabled = false
            musicButton.isEnabled = false
            pushToTalkButton.isHidden = true
            powerButton.setBackgroundImage(R.image.home_btn_bg_b(), for: .normal)
            powerButton.setImage(R.image.btn_power(), for: .normal)
        }
    }
    
//    func updateMemberCount(with room: Room?) {
//        guard let room = room else {
//            numberLabel.text = "1"
//            return
//        }
//        if !mManager.isConnectedState,
//            room.isReachMaxUser {
//            numberLabel.text = "--"
//        } else {
//            numberLabel.text = room.userCountForShow
//        }
//    }
    
//    func showSearchView() {
//        guard searchController.view.superview == nil else {
//            return
//        }
//        Logger.UserAction.log(.channel_list)
//        searchController.willMove(toParent: self)
//        view.addSubview(searchController.view)
//        searchController.didMove(toParent: self)
//        searchController.view.snp.makeConstraints { make in
//            make.width.equalTo(screenContainer.snp.width)
//            make.leading.equalTo(screenContainer.snp.leading)
//            make.top.equalTo(screenContainer.snp.bottom).offset(-12)
//            make.height.equalTo(300)
//        }
//    }
    
//    func updateSubviewStyle() {
//        channelTextField.text = channel.showName
//        screenBackgroundView.image = channel.name.channelType.screenImage
//        screenContainer.backgroundColor = channel.name.channelType.screenColor
//        searchController.setChannel(type: channel.name.channelType)
//        lockIconView.isHidden = !channel.isPrivate
//        tagView.isHidden = !lockIconView.isHidden
//    }
    
//    func hideSearchView() {
//        searchController.willMove(toParent: nil)
//        searchController.removeFromParent()
//        searchController.view.removeFromSuperview()
//        view.endEditing(true)
//    }

    func bindSubviewEvent() {
        searchViewModel.startListenerList()
            
        joinChannelSubject
            .filterNil()
            .filter { !$0.isEmpty }
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] name in
                //find
                self?.channel = FireStore.shared.findValidRoom(with: name)
            })
            .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] name in
                self?._joinChannel(name)
            })
            .disposed(by: bag)
        
//        searchViewModel.dataSourceSubject
//            .observeOn(SerialDispatchQueueScheduler(qos: .default))
//            .map { [weak self] rooms -> Room? in
//                guard let `self` = self else {
//                    return nil
//                }
//                return rooms.first(where: { $0.name == self.channelName })
//            }
//            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { [weak self] room in
//                self?.updateMemberCount(with: room)
//            })
//            .disposed(by: bag)
        
        speakButtonTrigger.rx
            .longPressGesture(configuration: { gestureRecognizer, delegate in
                gestureRecognizer.minimumPressDuration = 0.5
            })
            .filter { [weak self] _ in
                return self?.speakButton.isEnabled ?? false
            }
            .map { gesture -> Bool in
                return gesture.state == .began || gesture.state == .changed
            }
            .filter { [weak self] value in
                guard let `self` = self else { //talking 状态不能改变
                    return false
                }
                //connecting -> speak
                if value { //prepareing to talking
                    //check if connect
                    if self.mManager.isReachMaxUnmuteUserCount, self.state != .talking {
                        //reach connect
                        self.state = .maxMic
                        return false
                    }
                } else {
                    //unmic
                    if self.state == .maxMic {
                        self.state = .connected
                        return false
                    }
                }
                return true
            }
            .distinctUntilChanged()
            .debug()
            .flatMap { value -> Observable<Bool> in
                guard !value else {
                    return Observable.just(value)
                }
                return Observable.just(value)
                    .delay(.fromSeconds(0.3), scheduler: MainScheduler.asyncInstance)
            }
            .debug()
            .subscribe(onNext: { [weak self] highlighted in
                if highlighted {
                    HapticFeedback.Impact.light()
                }
                self?.speakButton.setImage(highlighted ? R.image.speak_button_pre() : R.image.speak_button_nor(), for: .normal)
                self?.speakButton.alpha = highlighted ? 1 : 0.6
                self?.state = highlighted ? .preparing : .connected
                self?.userStatus = highlighted ? .broadcaster : .audiance
                self?.screenContainer.updateMicView(alpha: highlighted ? 1 : 0.3)
//                self?.micView.alpha = highlighted ? 1 : 0.3
                self?.updateRole(highlighted)
            })
            .disposed(by: bag)
        
//        channelTextField.rx.controlEvent(.editingDidBegin)
//            .subscribe(onNext: { [weak self] _ in
//                self?.showSearchView()
//            })
//            .disposed(by: bag)
//        
//        channelTextField.rx.controlEvent(.editingDidEnd)
//            .subscribe(onNext: { [weak self] _ in
////                self?.joinChannelSubject.onNext(self?.channelTextField.text?.uppercased())
//                self?.hideSearchView()
//            })
//            .disposed(by: bag)
//        
//        channelTextField.rx.controlEvent(.editingChanged)
//            .subscribe(onNext: { [weak self] _ in
//                self?.sendQueryEvent()
//            })
//            .disposed(by: bag)
        
//        searchController.selectRoomHandler = { [weak self] room in
//            guard let `self` = self else { return }
//            if self._joinChannel(room.name) {
//                Logger.UserAction.log(.channel_choice, room.name)
//                self.updateMemberCount(with: room)
//            }
//            self.hideSearchView()
//        }
        
//        channelTextField.didBeginEditing = { [weak self] _ in
//            self?.sendQueryEvent()
//        }
//        channelTextField.didReturn = { [weak self] text in
//            guard let text = text else {
//                //offline
//                self?.leaveChannel()
//                return
//            }
//            let joinChannelBlock: (String?) -> Void = { name in
//                self?.joinChannelSubject.onNext(name)
//                Logger.UserAction.log(.channel_create, name)
//            }
//            //check if in private channel
//            if text.count == PasswordGenerator.shared.totalCount,
//                FireStore.shared.secretChannels.contains(where: { $0.name == "_\(text)"}) {
//                //show text
//                self?.showCanEnterSecretChannelAlert { confirm in
//                    if confirm {
//                        joinChannelBlock("_\(text)")
//                    } else {
//                        joinChannelBlock(text)
//                    }
//                }
//            } else {
//                joinChannelBlock(text)
//            }
//        }
        
        AdsManager.shared.mopubInitializeSuccessSubject
            .filter { _ -> Bool in
                return !Settings.shared.isProValue.value
            }
            .filter { $0 }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.loadAdView()
            })
            .disposed(by: bag)
        
        Settings.shared.isProValue.replay()
            .observeOn(MainScheduler.asyncInstance)
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                //remove ad
                self?.adView?.stopAutomaticallyRefreshingContents()
                self?.adView?.removeSubviews()
            })
            .disposed(by: bag)
        
        musicButton.tapHandler = { [weak self] in
            self?.playMusicAction()
        }
    }
    
    func configureSubview() {
        screenContainer.mManager = mManager
        screenContainer.delegate = self
        
        channel = Defaults[\.channel]
        
        if Frame.Height.deviceDiagonalIsMinThan4_7 {
            spackButtonBottomConstraint.constant = 45
        } else if Frame.Height.deviceDiagonalIsMinThan5_5 {
            spackButtonBottomConstraint.constant = 65
        }
        speakButton.imageView?.contentMode = .scaleAspectFit
        
        toolsView.roundCorners(topLeft: 17, topRight: 17, bottomLeft: 50, bottomRight: 50)
        screenContainer.updateSubviewStyle()
    }
    
    func loadAdView() {
        adView = MPAdView(adUnitId: "3cc10f8823c6428daf3bbf136dfbb761")
        adView.delegate = self
        adView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        adContainer.addSubview(adView)
        adView.loadAd(withMaxAdSize: adView.size)
        Logger.Ads.logEvent(.ads_load, .channel)
//        adView.startAutomaticallyRefreshingContents()
    }
}

// MARK: ScreenContainerDelegate
extension RoomViewController: ScreenContainerDelegate {
    func containerShouldJoinChannel(name: String?, directly: Bool) -> Bool {
        if directly {
            return _joinChannel(name)
        } else {
            joinChannelSubject.onNext(name)
            return true
        }
    }
    
    func containerShouldLeaveChannel() {
        leaveChannel()
    }
}

extension RoomViewController: MPAdViewDelegate {
    func viewControllerForPresentingModalView() -> UIViewController! {
        if let naviVC = self.navigationController {
            return naviVC
        } else {
            return self
        }
    }

    func adViewDidLoadAd(_ view: MPAdView!, adSize: CGSize) {
        cdPrint("[AD]-adViewDidLoadAd")
        Logger.Ads.logEvent(.ads_loaded, .channel)
    }

    func adView(_ view: MPAdView!, didFailToLoadAdWithError error: Error!) {
        cdPrint("[AD]-load ad error: \(error.localizedDescription)")
        Logger.Ads.logEvent(.ads_failed, .channel)
    }

    func willPresentModalView(forAd view: MPAdView!) {
//        showSource = .adModal
        Logger.Ads.logEvent(.ads_imp, .channel)
    }
    
    
    func willLeaveApplication(fromAd view: MPAdView!) {
        Logger.Ads.logEvent(.ads_clk, .channel)
//        showSource = .adLeave
    }
    
    func didDismissModalView(forAd view: MPAdView!) {
//        Logger.Ads.logEvent(.ads_clk, .channel)
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

extension UIColor {
    var image: UIImage {
        return UIImage(color: self, size: CGSize(width: 10, height: 10))
    }
}
