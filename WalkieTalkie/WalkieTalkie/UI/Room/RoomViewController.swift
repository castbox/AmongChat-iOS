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
    
    @IBOutlet weak var reportButton: UIButton!
    
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
    @IBOutlet weak var toolsView: RoomToolsView!
    
    private lazy var speakingListView: RoomSpeakingListView = {
        let v = RoomSpeakingListView(frame: .zero)
        v.moreUserBtnAction = { [weak self] in
            guard let `self` = self else { return }
            guard !self.channel.showName.isEmpty else {
                return
            }
            let vc = ChannelUserListController(channel: self.channel)
            self.navigationController?.pushViewController(vc)
        }
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private lazy var avatarBtn: Social.Widgets.AvatarView = {
        let iv = Social.Widgets.AvatarView()
        iv.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(reportButtonAction(_:)))
        iv.addGestureRecognizer(tapGR)
        iv.a_cornerRadius = 15
        iv.a_borderWidth = 2
        iv.a_borderColor = UIColor(hex6: 0xFFFFFF, alpha: 0.25)
        return iv
    }()
    
    private lazy var premiumBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(R.image.icon_setting_diamonds(), for: .normal)
        btn.addTarget(self, action: #selector(onPremiumBtn), for: .primaryActionTriggered)
        btn.isHidden = true
        return btn
    }()
    
    private lazy var avatarDot: Social.Widgets.AvatarView = {
        let iv = Social.Widgets.AvatarView()
        iv.a_backgroundColor = UIColor(hex6: 0xFF6679, alpha: 1.0)
        iv.a_cornerRadius = 5
        iv.a_borderWidth = 1
        iv.a_borderColor = UIColor(hex6: 0xFFFFFF, alpha: 1.0)
        iv.isHidden = true
        return iv
    }()
    
    private lazy var mManager: ChatRoomManager = {
        let manager = ChatRoomManager.shared
        manager.delegate = self
        return manager
    }()
    
    private var joinChannelSubject = BehaviorSubject<String?>(value: nil)
    private lazy var viewModel = RoomViewModel()

    @IBOutlet weak var adContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var adContainer: UIView!
    
    private var confetti: ConfettiView!

    private var adView: MPAdView!
    
    private var isFirstConnectSecretChannel: String = ""
    
    private var isFirstShowSecretChannel: Bool {
        set {
            Defaults[\.isFirstShowSecretChannel] = newValue
        }
        get { Defaults[\.isFirstShowSecretChannel] }
    }
    
    
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
            reportButton.isEnabled = !channel.showName.isEmpty
            speakingListView.update(with: channel)
        }
    }
    
    private var channelName: String {
        return channel.name
    }
//    private var isEnableForSegmentControlRelay = BehaviorRelay(value: true)
    private var hotBag: DisposeBag? = DisposeBag()
    var isSegmentControlEnable: Bool = true {
        didSet {
            segmentControl.isEnabled = isSegmentControlEnable
        }
    }
    
    private var state: ConnectState = .disconnected {
        didSet {
            updateButtonsEnable()
            screenContainer.update(state: state)
            updateObserverEmojiState()
            updateState(new: state, old: oldValue)
        }
    }
    
    private var speakingModalRecord: String? = nil
    
    var myUserId: String {
        return String(Constants.sUserId)
    }
    var timer: SwiftTimer?
    var userStatus: UserStatus = .audiance
    var shareTimeDispose: Disposable?
    //only show once
    var previousShowShareViewName: String?

    override var screenName: Logger.Screen.Node.Start {
        return .channel
    }
    
    private let joinedChannelSubject = PublishSubject<String>()
    var joinedChannelObservable: Observable<String> {
        return joinedChannelSubject.asObservable()
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
            leaveChannel()
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
            leaveChannel()
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
                    let showErrorBlock = { [weak self] in
                        guard let `self` = self else { return }
                        //show error
                        if self.channelName.count > 1 { //only have _
                            if self.channelName == self.isFirstConnectSecretChannel {
                                //clear invalid secret channel
                                Defaults.set(channel: nil, mode: .private)
                                self.searchViewModel.joinedSecretRemove(self.channelName)
                                self.showCreateSecretChannel(with: .invalid)
                            } else {
                                self.showCreateSecretChannel(with: .errorPasscode)
                            }
                        } else {
                            self.showCreateSecretChannel(with: .emptySecretRooms)
                        }
                    }
                    
                    let removeHUDBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
                    FireStore.shared.fetchSecretChannel(of: channelName)
                        .catchErrorJustReturn(nil)
                        .subscribe(onSuccess: { [weak self] (room) in
                            removeHUDBlock()
                            guard let _ = room else {
                                showErrorBlock()
                                return
                            }
                            self?.joinChannel(self?.channelName)
                        })
                        .disposed(by: bag)

                }
            } else {
                joinChannel(channelName)
            }
        }
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        Logger.Share.log(.share_clk, category: channelName.isPrivate ? .secret : .global, channelName)
        showShareView()
    }
    
    @IBAction func privateButtonAction(_ sender: Any) {
        switch mode {
        case .private:
            showCreateSecretChannel()
        case .public:
            showCreateGlobalChannelController()
        }
    }
    
    @IBAction func reportButtonAction(_ sender: UIButton) {
//        guard !channel.showName.isEmpty else {
//            return
//        }
//        let vc = ChannelUserListController(channel: channel)
//        navigationController?.pushViewController(vc)
        
        let vc = Social.ProfileViewController()
        navigationController?.pushViewController(vc)
        avatarDot.isHidden = true
    }
    
    func showShareView(_ isAutomaticShow: Bool = false) {
        //检查是否有 controller 再上面
        guard children.isEmpty else {
            return
        }
        if channel.isPrivate {
            guard !channelName.showName.isEmpty else {
                showCreateSecretChannel(with: .emptySecretRooms)
                return
            }
        }
        previousShowShareViewName = channelName
        ShareView.showWith(channel: channel, shareButton: shareButton, isAutomaticShow: isAutomaticShow)
    }
    
    func leaveChannel() {
        UIApplication.shared.isIdleTimerDisabled = false
        speakButtonTrigger.isUserInteractionEnabled = false
        mManager.leaveChannel { [weak self] (name) in
            ChannelUserListViewModel.shared.leavChannel(name)
        }
        speakButtonTrigger.isUserInteractionEnabled = true
        speakingListView.isUserInteractionEnabled = false
        speakingModalRecord = nil
    }
  
    private func joinChannel(_ name: String?) {
        joinChannelSubject.onNext(name)
    }
    
    @discardableResult
    private func _joinChannel(_ name: String?, completionBlock: (() -> Void)? = nil) -> Bool {
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
        SpeechRecognizer.default.requestAuthorize { [weak self] _ in
            guard let `self` = self else { return }
            self.checkMicroPermission { [weak self] in
                guard let `self` = self else { return }
                self.mManager.joinChannel(channelId: name) { [weak self] in
                    HapticFeedback.Impact.success()
                    UIApplication.shared.isIdleTimerDisabled = true
                    self?.isSegmentControlEnable = true
                    completionBlock?()
                    self?.joinedChannelSubject.onNext(name)
                    self?.speakingListView.isUserInteractionEnabled = true
                    ChannelUserListViewModel.shared.didJoinedChannel(name)
                }
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
    
    func update(mode: Int) {
        //正在连接
//        if self.mManager.isConnectedState {
            self.leaveChannel()
//        }
        //已断开
        //change the style
        let mode = Mode(index: mode)
        self.screenContainer.update(mode: mode)
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
                self?.isSegmentControlEnable = true
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
                self?.isSegmentControlEnable = true
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

    func onUserStatusChanged(userId: UInt, muted: Bool) {
        debugPrint("uid: \(userId) muted: \(muted)")
        if Constants.isMyself(userId) {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            let value = NSNumber(booleanLiteral: muted)
            if !muted {
                perform(#selector(updateIsMuted(_:)), with: value, afterDelay: 0.4)
                //延迟播音
            } else {
                perform(#selector(updateIsMuted(_:)), with: value)
            }
            #if DEBUG
            if !SpeechRecognizer.default.isAvaliable {
                view.raft.autoShow(.text("Speech text is not avaliable"))
            }
            #endif
        } else {
            //check block
            if let user = ChannelUserListViewModel.shared.blockedUsers.first(where: { $0.uid.uIntValue == userId }) {
                mManager.adjustUserPlaybackSignalVolume(user, volume: 0)
            } else if ChannelUserListViewModel.shared.mutedUserValue.contains(userId) {
                mManager.adjustUserPlaybackSignalVolume(ChannelUser.randomUser(uid: userId), volume: 0)
            }
        }
    }
    
    @objc
    func updateIsMuted(_ value: NSNumber) {
        guard mManager.isConnectedState else {
            return
        }
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

    func onAudioVolumeIndication(userId: UInt, volume: UInt) {
        ChannelUserListViewModel.shared.updateVolumeIndication(userId: userId, volume: volume)
    }
    
    func onChannelUserChanged(users: [ChannelUser]) {
        ChannelUserListViewModel.shared.update(users)
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
            let result = _joinChannel(name)
            isSegmentControlEnable = !result
            return result
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
            segmentControl.alwaysAnnouncesValue = false
            segmentControl.setIndex(mode.intValue, animated: true)
            segmentControl.alwaysAnnouncesValue = true
        }
        
        if mode == .private,
            channelName.showName.isEmpty,
            isFirstShowSecretChannel {
            isFirstShowSecretChannel = false
            showCreateSecretChannel(with: .emptySecretRooms)
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
    
    func startShowShareViewTimer() {
        guard state.isConnectedState else {
            shareTimeDispose?.dispose()
            return
        }
        guard previousShowShareViewName == nil else {
            return
        }
        shareTimeDispose?.dispose()
        shareTimeDispose =
            Observable.just(())
                .delay(.seconds(FireRemote.shared.value.delayShowShareDialog), scheduler: MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                    guard self?.previousShowShareViewName == nil else {
                        return
                    }
                    Logger.Share.log(.share_dialog_pop)
                    self?.showShareView(true)
                })
        shareTimeDispose?.disposed(by: bag)
    }
    
    func play(emojis: [String]) {
        guard self.confetti.isAvailable else {
            return
        }
        let contents = emojis.map { item -> ConfettiView.Content in
            .text(item)
        }.last(2)
        guard !contents.isEmpty else {
            return
        }
        Logger.Action.log(.emoji_imp)
        self.confetti.emit(with: contents)
    }
    
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
    
    func updateObserverEmojiState() {
        guard state.isConnectedState || state.isConnectingState else {
            viewModel.removeEmojiObserver()
            return
        }
        if viewModel.observeEmojiAtRoom?.name != channel.name {
            //replace
            viewModel.observerEmoji(at: channel, searchViewModel: searchViewModel) { [weak self] emojis in
                guard let `self` = self,
                    self.state.isConnectedState else {
                        return
                }
                self.play(emojis: emojis)
            }
        }
    }
    
    func updateButtonsEnable() {
//        print("[RoomViewController] updateButtonsEnable with state: \(state.title)")
        switch state {
        case .talking:
            speakButton.alpha = 1
            ()
        case .maxMic:
            ()
//            speakButton.alpha = 1
        case .connected, .preparing:
            speakButton.isEnabled = true
//            speakButton.alpha = 1
            musicButton.isEnabled = true
            pushToTalkButton.isHidden = false
            powerButton.setImage(R.image.btn_power_on(), for: .normal)
            powerButton.setBackgroundImage(R.image.home_btn_bg(), for: .normal)
        default:
//            micView.alpha = 0
//            speakButton.alpha = 1
            speakButton.isEnabled = false
            musicButton.isEnabled = false
            pushToTalkButton.isHidden = true
            powerButton.setBackgroundImage(R.image.home_connect_btn_bg_b(), for: .normal)
            powerButton.setImage(R.image.btn_power(), for: .normal)
        }
        startShowShareViewTimer()
    }

    func bindSubviewEvent() {
        let mode = Defaults[\.mode]
        //set index
        screenContainer.update(mode: mode)
        //update style
        screenContainer.updateSubviewStyle()
        segmentControl.setIndex(mode.intValue)
        //保存
        isFirstConnectSecretChannel = Defaults.channel(for: .private).name
        //        segmentControl.announcesValueImmediately = false

        searchViewModel.startListenerList()
            
        joinChannelSubject
            .filterNil()
            .filter { !$0.isEmpty }
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] name in
                //find
                self?.isSegmentControlEnable = false
                self?.channel = FireStore.shared.findValidRoom(with: name)
            })
            .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] name in
                guard let `self` = self else { return }
                self.prompProfileInitialIfNeeded {
                    let result = self._joinChannel(name)
                    self.isSegmentControlEnable = !result                    
                }
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
//            .debug()
            .flatMap { [weak self] value -> Observable<(Bool, Mode)> in
                //            return Observable.just((true, .public))
                guard let mode = self?.mode else {
                    return .just((false, .public))
                }
                guard !value else {
                    return Observable.just((value, mode))
                }
                return Observable.just((value, mode))
                    .delay(.fromSeconds(0.3), scheduler: MainScheduler.asyncInstance)
            }
//            .debug()
            .subscribe(onNext: { [weak self] (highlighted, mode) in
                guard let `self` = self,
                    self.mode == mode else {
                    return
                }
                if highlighted {
                    HapticFeedback.Impact.light()
                }
                self.speakButton.setImage(highlighted ? R.image.speak_button_pre() : R.image.speak_button_nor(), for: .normal)
//                self.speakButton.alpha = highlighted ? 1 : 0.6
                let previousState = self.state
                self.state = highlighted ? .preparing : .connected
                self.segmentControl.isEnabled = !highlighted
                self.userStatus = highlighted ? .broadcaster : .audiance
                self.screenContainer.updateMicView(alpha: highlighted ? 1 : 0.3)
//                cdPrint("state: \(self.state) highlighted: \(highlighted)")
                //play sounds with highlighted
                if !highlighted {
                    if previousState.isConnectingState {
                        return
                    }
                }
                self.updateRole(highlighted)
            })
            .disposed(by: bag)
        
        segmentControl.rx.controlEvent(.valueChanged)
            .do(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.view.endEditing(true)
            })
            .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
            .do(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.update(mode: self.segmentControl.index)
                self.segmentControl.isEnabled = false
            })
            .delay(.fromSeconds(segmentControl.animationDuration), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
//                self.update(mode: self.segmentControl.index)
                self.segmentControl.isEnabled = true
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
        
        SpeechRecognizer.default.didRecongnizedEmojiHandler = { [weak self] emojis in
            cdPrint("SpeechRecognizer: \(emojis)")
            guard let `self` = self,
                !emojis.isEmpty else {
                return
            }
            let key = FireStore.shared.update(emoji: emojis, for: self.channel.name)
            self.viewModel.addEmojiObserveIgnored(key: key)
            //
            if self.confetti.isAvailable {
                Logger.Action.log(.emoji_sent)
            }
            self.play(emojis: emojis)
        }
        
        RxKeyboard.instance.visibleHeight
            .map { $0 <= 0 }
            .asObservable()
            .bind(to: reportButton.rx.isEnabled)
            .disposed(by: bag)
        
        Settings.shared.firestoreUserProfile.replay()
            .filterNil()
            .subscribe(onNext: { [weak self] (profile) in
                let _ = profile.avatarObservable
                    .subscribe(onSuccess: { (image) in
                        self?.avatarBtn.image = image
                    })
            })
            .disposed(by: bag)
        
        Observable.combineLatest(FireStore.shared.isInReviewSubject, Settings.shared.isProValue.replay())
            .subscribe(onNext: { [weak self] (t) in
                let (isInReview, isPro) = t
                self?.premiumBtn.isHidden = isInReview || isPro
            })
            .disposed(by: bag)
    }
    
    func configureSubview() {
        screenContainer.mManager = mManager
        screenContainer.delegate = self
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
        
        confetti = ConfettiView()
        confetti.isUserInteractionEnabled = false
        view.addSubview(confetti)
        confetti.snp.makeConstraints { maker in
            maker.left.right.top.bottom.equalToSuperview()
        }
        
        #if DEBUG
        
        let btn = UIButton(type: .custom)
        btn.setImage(R.image.iconReport(), for: .normal)
        btn.addTarget(self, action: #selector(gotoChannelUserList), for: .primaryActionTriggered)
        
        view.addSubview(btn)
        btn.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(segmentControl)
            maker.left.equalTo(segmentControl.snp.right).offset(10)
        }
        
        #endif
        
        view.addSubview(premiumBtn)
        premiumBtn.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(60)
            maker.centerY.equalTo(segmentControl)
            maker.right.equalTo(0)
        }
        
        view.addSubview(avatarBtn)
        avatarBtn.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(30)
            maker.left.equalTo(15)
            maker.centerY.equalTo(segmentControl)
        }
        
        screenContainer.addSubview(speakingListView)
        speakingListView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
        }
        
        view.insertSubview(avatarDot, aboveSubview: avatarBtn)
        avatarDot.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(10)
            maker.right.equalTo(avatarBtn).offset(2)
            maker.bottom.equalTo(avatarBtn).offset(-4)
        }
    }
    
    #if DEBUG
    @objc
    private func gotoChannelUserList() {
        guard !channel.showName.isEmpty else {
            return
        }
//        let vc = ChannelUserListController(channel: channel)
//        navigationController?.pushViewController(vc)
        
        guard let topVC = UIApplication.topViewController() else { return }
        let msg = FireStore.Entity.User.CommonMessage(msgType: .enterRoom, uid: "WT-YYYYJR", channel: nil, username: "JJJJ", avatar: "3", docId: "")
//        let modal = Social.TopToastModal(with: msg)
        let modal = Social.JoinChannelRequestModal(with: msg)
        topVC.present(modal, animated: false)

    }
    #endif
    
    @objc
    private func onPremiumBtn() {
        let premium = R.storyboard.main.premiumViewController()!
        premium.style = .likeGuide
        premium.source = .iap_home
        premium.dismissHandler = {
            premium.dismiss(animated: true, completion: nil)
        }
        premium.modalPresentationStyle = .fullScreen
        present(premium, animated: true, completion: nil)
    }
    
    func loadAdView() {
        adView = MPAdView(adUnitId: "4334cad9c4e244f8b432635d48104bb9")
        adView.delegate = self
        adView.frame = CGRect(x: 0, y: 0, width: adContainer.width, height: adContainerHeightConstraint.constant)
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

extension RoomViewController {
    
    func prompProfileInitialIfNeeded(completion: @escaping (() -> Void)) {
        
        #if DEBUG
        let shouldShow = true
        #else
        let loggedIn = Settings.shared.loginResult.value != nil
        let shouldShow = loggedIn && Defaults[\.profileInitialShownTsKey] == nil
        #endif
        
        if shouldShow {
            let vc = Social.InitialProfileViewController()
            vc.onDismissHandler = {
                completion()
            }
            vc.showModal(in: self)
        } else {
            completion()
        }
        
    }
    
    func joinRoom(_ name: String) {
        if name.isPrivate {
            let removeHandler = view.raft.show(.doing(R.string.localizable.channelChecking()))
            let _ = FireStore.shared.fetchSecretChannel(of: name)
                .catchErrorJustReturn(nil)
                .subscribe(onSuccess: { [weak self] (room) in
                    removeHandler()
                    
                    guard let _ = room else {
                        self?.view.raft.autoShow(.text(R.string.localizable.channelNotExist()))
                        return
                    }
                    self?.update(mode: Mode.private.intValue)
                    self?.joinChannel(name)
                    
                })
        } else {
            update(mode: Mode.public.intValue)
            joinChannel(name)
        }
    }
    
    func onPushReceived() {
        avatarDot.isHidden = false
    }
    
}

extension RoomViewController {
    private func updateState(new: ConnectState, old: ConnectState) {
        switch (new, old) {
        case (.connected, .maxMic):
            promptSpeakingModalIfNeeded(for: channelName)
        default:
            ()
        }
    }
    
    private func promptSpeakingModalIfNeeded(for channel: String) {
        guard speakingModalRecord == nil || channel != speakingModalRecord else {
            return
        }
        
        speakingModalRecord = channel
        
        let modal = SpeakingModal()
        modal.showModal(in: self)
    }
}
