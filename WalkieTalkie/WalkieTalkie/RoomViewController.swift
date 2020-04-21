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

enum AudioType: String, CaseIterable {
    case begin
    case end
    case call
}

enum UserStatus {
    case audiance
    case broadcaster
    case music
    case end
}

enum ChannelType {
    case `public`
    case `private`
}

extension ChannelType {
    var screenColor: UIColor {
        switch self {
        case .public:
            return UIColor(hex: 0xBFFF58)!
        case .private:
            return UIColor(hex: 0xFFC800)!
        }
    }
}

class RoomViewController: ViewController {
    @IBOutlet private weak var speakButton: UIButton!
    @IBOutlet weak var speakButtonTrigger: UIView!
    @IBOutlet weak var connectStateLabel: UILabel!
    
    @IBOutlet weak var numberLabel: UILabel!
    private lazy var mManager: ChatRoomManager = {
        let manager = ChatRoomManager.shared
        manager.delegate = self
        return manager
    }()
    
    @IBOutlet weak var tagView: UILabel!
    @IBOutlet weak var lockIconView: UIImageView!
    @IBOutlet weak var channelTextField: ChannelNameField!
    @IBOutlet weak var screenContainer: UIView!
    @IBOutlet weak var buttonContainer: UIView!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var pushToTalkButton: UIButton!
    @IBOutlet weak var musicButton: FrozenButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
//    @IBOutlet weak var upButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var spackButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toolsView: UIView!
    private var gradientLayer: CAGradientLayer!
    private var joinChannelSubject = BehaviorSubject<String?>(value: nil)
    private lazy var viewModel = RoomViewModel()

    private lazy var searchController: SearchViewController = {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        controller.viewModel = searchViewModel
        return controller
    }()
    
    @IBOutlet weak var adContainer: UIView!

    private var adView: MPAdView!
    
    private let searchViewModel = SearchViewModel()
    private var channelName: String? {
        didSet {
            channelTextField.text = channelName?.showName
            screenContainer.backgroundColor = channelName?.channelType.screenColor
            searchController.setChannel(type: channelName?.channelType)
            lockIconView.isHidden = !(channelName?.isPrivate ?? false)
            tagView.isHidden = !lockIconView.isHidden
            //save to cache
            Defaults[.channelName] = channelName ?? ""
        }
    }
    
    private var hotBag: DisposeBag? = DisposeBag()
    
    var myUserId: String {
        return String(Constant.sUserId)
    }
    var timer: SwiftTimer?
    var userStatus: UserStatus = .audiance
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isNavigationBarHiddenWhenAppear = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelName = Defaults[.channelName]
        configureSubview()
        bindSubviewEvent()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = screenContainer.bounds
        adView?.frame = adContainer.bounds
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func screenContainerTapped(_ sender: Any) {
        _ = channelTextField.becomeFirstResponder()
    }
    
    func playMusicAction() {
        userStatus = .music
        if let role = mManager.role, role == .broadcaster {
            playAudio(type: .call) { [weak self] in
                self?.updateRole(false)
            }
        } else {
            updateRole(true)
        }
    }
    
    @IBAction func upChannelAction(_ sender: Any) {
        guard let channelName = channelName,
            let room = searchViewModel.previousRoom(channelName) else {
            return
        }
        self.channelName = room.name
        updateMemberCount(with: room)
        if mManager.isConnectingState {
            joinChannelSubject.onNext(room.name)
        }
    }
    
    @IBAction func downChannelAction(_ sender: Any) {
        guard let channelName = channelName,
            let room = searchViewModel.nextRoom(channelName) else {
            return
        }
        self.channelName = room.name
        updateMemberCount(with: room)
        if mManager.isConnectingState {
            joinChannelSubject.onNext(room.name)
        }
    }
    
    @IBAction func connectChannelAction(_ sender: UIButton) {
        if mManager.isConnectingState {
            //disconnect
            leaveChannel()
        } else {
            joinChannel(channelName)
        }
    }
    
    @IBAction func shareButtonAction(_ sender: Any) {
        guard let name = channelName else {
            return
        }
        if name.isPrivate {
            showShareController(channelName: name)
        } else {
            shareChannel(name: name)
        }
    }
    
    @IBAction func privateButtonAction(_ sender: Any) {
        let controller = R.storyboard.main.privateChannelController()
        controller?.joinChannel = { [weak self] name, autoShare in
            //join channels
            self?.joinChannelSubject.onNext(name)
            //show code
            if autoShare {
                self?.showShareController(channelName: name)
            }
        }
        controller?.showModal(in: self)
    }
    
    func leaveChannel() {
        mManager.leaveChannel()
        HapticFeedback.Impact.medium()
    }
  
    func joinChannel(_ name: String?) {
        joinChannelSubject.onNext(name)
    }
    
    @discardableResult
    private func _joinChannel(_ name: String?) -> Bool {
        guard let name = name else {
            return false
        }
        if mManager.state == .connected && mManager.channelName == name {
           return false
        }
        channelName = name
        searchViewModel.add(private: name)
        checkMicroPermission { [weak self] in
            guard let `self` = self else { return }
            self.mManager.joinChannel(channelId: name) { [weak self] in
                self?.viewModel.requestEnterRoom()
            }
            HapticFeedback.Impact.medium()
        }
        return true
    }
    
    func playAudio(type: AudioType, completionHandler: (() -> Void)? = nil) {
        timer?.cancel()
        timer = nil
        mManager.getRtcManager().startAudioMixing(type.path)
        let duration = mManager.getRtcManager().getAudioMixingDuration()
        timer = SwiftTimer(interval: .milliseconds(duration)) { timer in
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
extension RoomViewController: ChatRoomDelegate {
    
    func onJoinChannelFailed(channelId: String?) {
        Observable.just(())
            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .subscribe(onNext: { [weak self] _ in
                self?.connectStateLabel.text = "OCCOR ERROR"
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
                self?.connectStateLabel.text = "TIMEOUT"
            })
            .disposed(by: bag)
    }

    func onConnectionChangedTo(state: AgoraConnectionStateType, reason: AgoraConnectionChangedReason) {
        connectStateLabel.text = state.title.uppercased()
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
//        updateMemberCountLabel()
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

private extension RoomViewController {
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
    
    func sendQueryEvent() {
        if let text = channelTextField.text?.uppercased(),
            text.count >= 2,
            text != channelName?.showName {
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
            powerButton.setImage(R.image.btn_power_on(), for: .normal)
            powerButton.setBackgroundImage(R.image.home_btn_bg(), for: .normal)
        default:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
            pushToTalkButton.isHidden = true
            powerButton.setBackgroundImage(R.image.home_btn_bg_b(), for: .normal)
            powerButton.setImage(R.image.btn_power(), for: .normal)
        }
    }
    
    func updateMemberCount(with room: Room?) {
        numberLabel.text = room?.user_count.string
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
        searchViewModel.startListenerList()
            
        joinChannelSubject
            .filterNil()
            .filter { !$0.isEmpty }
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] name in
                self?.channelName = name
            })
            .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] name in
                self?._joinChannel(name)
            })
            .disposed(by: bag)
        
        searchViewModel.dataSourceSubject
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { [weak self] rooms -> Room? in
                guard let `self` = self else {
                    return nil
                }
                return rooms.first(where: { $0.name == self.channelName })
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] room in
                self?.updateMemberCount(with: room)
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
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] highlighted in
//                cdPrint("speakButton is highlighted: \(highlighted)")
                self?.speakButton.setImage(highlighted ? R.image.speak_button_pre() : R.image.speak_button_nor(), for: .normal)
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
//                self?.joinChannelSubject.onNext(self?.channelTextField.text?.uppercased())
                self?.hideSearchView()
            })
            .disposed(by: bag)
        
        channelTextField.rx.controlEvent(.editingChanged)
            .subscribe(onNext: { [weak self] _ in
                self?.sendQueryEvent()
            })
            .disposed(by: bag)
        
        searchController.selectRoomHandler = { [weak self] room in
            guard let `self` = self else { return }
            if self._joinChannel(room.name) {
                self.updateMemberCount(with: room)
            }
            self.hideSearchView()
        }
        
        channelTextField.didBeginEditing = { [weak self] _ in
            self?.sendQueryEvent()
        }
        channelTextField.didReturn = { [weak self] textField in
            self?.joinChannelSubject.onNext(textField.text?.uppercased())
        }
        
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
        
        if Frame.Height.deviceDiagonalIsMinThan4_7 {
            spackButtonBottomConstraint.constant = 45
        }
        
        speakButton.imageView?.contentMode = .scaleAspectFit
        
        gradientLayer = CAGradientLayer()
//        gradientLayer.frame = CGRect.init(x: 0, y: 0, width: 375, height: 100);//CAGradientLayer的控件大小
//        gradientLayer.colors = [UIColor(hex: 0xb7fc39)?.cgColor, UIColor(hex: 0x8ed951)?.cgColor, UIColor(hex: 0xb7fc39)?.cgColor]//渐变颜色
//        gradientLayer.type = .radial
//        gradientLayer.locations = [0.2,0.5,0.8]//渐变起始位置
//        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
//        gradientLayer.endPoint = CGPoint.init(x: 1, y: 0)
//        screenContainer.layer.insertSublayer(gradientLayer, at: 0)
        toolsView.roundCorners(topLeft: 17, topRight: 17, bottomLeft: 50, bottomRight: 50)
    }
    
    func loadAdView() {
        adView = MPAdView(adUnitId: "3cc10f8823c6428daf3bbf136dfbb761")
        adView.delegate = self
        adView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        adContainer.addSubview(adView)
        adView.loadAd(withMaxAdSize: adView.size)
//        adView.startAutomaticallyRefreshingContents()
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
//        Logger.Ads.logEvent(.load)
//        AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .banner, event: .rendered, eventTime: Date(), requestTime: Date()))
//        removeAmazonKeywordsV2(for: view)
//        adsLoadedSignal.onNext((view, adSize))
//        Logger.Ads.logEvent(.impl)
//        makeAwsBid()
    }

    func adView(_ view: MPAdView!, didFailToLoadAdWithError error: Error!) {
        cdPrint("[AD]-load ad error: \(error.localizedDescription)")
//        Logger.Ads.logEvent(.nofill)
//        AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .banner, event: .nofill, eventTime: Date(), requestTime: Date()))
//        removeAmazonKeywordsV2(for: view)
//        NSLog("mopub: fail to load ads with error: \(error.debugDescription)")
//        adsLoadedSignal.onNext((nil, .zero))
//        makeAwsBid()
    }

    func willPresentModalView(forAd view: MPAdView!) {
//        showSource = .adModal
//        Logger.Ads.logEvent(.click)
    }
    
    func willLeaveApplication(fromAd view: MPAdView!) {
//        Logger.Ads.logEvent(.click)
//        showSource = .adLeave
    }
    
    func didDismissModalView(forAd view: MPAdView!) {
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
        @unknown default:
            return "failed"
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

extension UIColor {
    var image: UIImage {
        return UIImage(color: self, size: CGSize(width: 10, height: 10))
    }
}
