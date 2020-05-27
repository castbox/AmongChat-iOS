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
import BetterSegmentedControl

enum UserStatus {
    case audiance
    case broadcaster
    case music
    case end
}

class RoomViewController: ViewController {
    @IBOutlet private weak var speakButton: UIButton!
    @IBOutlet weak var speakButtonTrigger: UIView!
    
    @IBOutlet weak var segmentControl: BetterSegmentedControl!
    @IBOutlet weak var screenContainer: ScreenContainer!
    @IBOutlet weak var buttonContainer: UIView!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var pushToTalkButton: UIButton!
    @IBOutlet weak var musicButton: FrozenButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var spackButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolsView: RoomToolsView!
    
    private lazy var mManager: ChatRoomManager = {
        let manager = ChatRoomManager.shared
        manager.delegate = self
        return manager
    }()
    
    private var joinChannelSubject = BehaviorSubject<String?>(value: nil)
    private lazy var viewModel = RoomViewModel()

    @IBOutlet weak var adContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var adContainer: UIView!

    private var adView: MPAdView!
    
    private var searchViewModel: SearchViewModel {
        screenContainer.searchViewModel
    }
    
    private var mode: Mode {
        screenContainer.mode
    }
    
    private var channel: Room! {
        didSet {
            screenContainer.channel = channel
            channel.updateJoinInterval()
            Defaults.set(channel: channel, mode: mode)
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
        HapticFeedback.Impact.light()
        guard let room = searchViewModel.previousRoom(channelName) else {
            return
        }
        guard room.name != channel.name else {
            if mode == .private {
                view.raft.autoShow(.text(R.string.localizable.toastSingleSecretChannal()))
            }
            return
        }
        self.channel = room
        if mManager.isConnectingState {
            joinChannelSubject.onNext(room.name)
        }
        Logger.UserAction.log(.channel_up, room.name)
    }
    
    @IBAction func downChannelAction(_ sender: Any) {
        HapticFeedback.Impact.light()
        guard let room = searchViewModel.nextRoom(channelName) else {
            return
        }
        guard room.name != channel.name else {
            if mode == .private {
                view.raft.autoShow(.text(R.string.localizable.toastSingleSecretChannal()))
            }
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
//                    view.raft.autoShow(.text(R.string.localizable.channelNotExist()))
                    showCreateSecretChannel(with: .errorPasscode)
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
        switch mode {
        case .private:
            showCreateSecretChannel()
        case .public:
            showCreateGlobalChannelController()
        }
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
            let value = NSNumber(booleanLiteral: muted)
            if !muted {
                perform(#selector(updateIsMuted(_:)), with: value, afterDelay: 0.4)
                //延迟播音
            } else {
                perform(#selector(updateIsMuted(_:)), with: value)
            }
        }
    }
    
    @objc
    func updateIsMuted(_ value: NSNumber) {
        let isMute = value.boolValue
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

// MARK: ScreenContainerDelegate
extension RoomViewController: ScreenContainerDelegate {
    
    func containerShouldUpdate(channel: Room?) {
        guard let channel = channel else {
            return
        }
        self.channel = channel
    }
    
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
    
    func containerDidUpdate(to mode: Mode) {
        if segmentControl.index != mode.intValue {
            segmentControl.setIndex(mode.intValue, animated: true)
        }
    }
    
    func containerShouldShowCreateView(with alertType: CreateSecretChannelController.AlertType) {
        showCreateSecretChannel(with: alertType)
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

//MARK: Private method
private extension RoomViewController {
    
    func showCreateSecretChannel(with alert: CreateSecretChannelController.AlertType = .none) {
        CreateSecretChannelController.show(from: self, alert: alert) { [weak self] name, autoShare in
            //join channels
            self?.joinChannelSubject.onNext(name)
            //show code
            if autoShare {
                self?.showShareController(channelName: name)
            }
        }
    }
    
    func showCreateGlobalChannelController() {
        let controller = CreateGlobalChannelController()
        controller.joinChannel = { [weak self] name, autoShare in
            //join channels
            self?.joinChannelSubject.onNext(name)
            //show code
            if autoShare {
                self?.showShareController(channelName: name)
            }
        }
        controller.showModal(in: self)
    }
        
    
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
    
    func updateButtonsEnable() {
//        print("[RoomViewController] updateButtonsEnable with state: \(state.title)")
        switch state {
        case .talking:
            speakButton.alpha = 1
        case .maxMic:
            speakButton.alpha = 1
        case .connected, .preparing:
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
            powerButton.setBackgroundImage(R.image.home_connect_btn_bg_b(), for: .normal)
            powerButton.setImage(R.image.btn_power(), for: .normal)
        }
    }

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
        
        segmentControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                //正在连接
                if self.mManager.isConnectedState {
                    self.leaveChannel()
                }
                //已断开
                //change the style
                let mode = Mode(index: self.segmentControl.index)
                self.screenContainer.update(mode: mode)
            })
            .disposed(by: bag)
        
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
        
        if Frame.Height.deviceDiagonalIsMinThan4_7 {
            spackButtonBottomConstraint.constant = 45
        } else if Frame.Height.deviceDiagonalIsMinThan5_5 {
            spackButtonBottomConstraint.constant = 65
        } else {
            adContainerHeightConstraint.constant = 90
        }
        speakButton.imageView?.contentMode = .scaleAspectFit
        
        toolsView.addShadow(ofColor: "60521C".color(), radius: 6.5, offset: CGSize(width: 0, height: 1), opacity: 0.31)
        
        segmentControl.segments = LabelSegment.segments(
            withTitles: ["Global", "Secret"],
            normalFont: R.font.nunitoBold(size: 14),
            normalTextColor: UIColor.white.alpha(0.78),
            selectedBackgroundColor: "221F1F".color(),
            selectedFont: R.font.nunitoBold(size: 15),
            selectedTextColor: UIColor.white
        )
        
        let mode = Defaults[\.mode]
        //set index
        screenContainer.update(mode: mode)
        //update style
        screenContainer.updateSubviewStyle()
        segmentControl.setIndex(mode.intValue)
    }
    
    func loadAdView() {
        adView = MPAdView(adUnitId: "3cc10f8823c6428daf3bbf136dfbb761")
        adView.delegate = self
        adView.frame = CGRect(x: 0, y: 0, width: 320, height: adContainerHeightConstraint.constant)
        adContainer.addSubview(adView)
        adView.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
//        if adContainerHeightConstraint.constant > 50 {
//            adView.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
//        } else {
//            adView.loadAd(withMaxAdSize: kMPPresetMaxAdSize50Height)
//        }
        Logger.Ads.logEvent(.ads_load, .channel)
        adView.startAutomaticallyRefreshingContents()
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
