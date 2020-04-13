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
//import Alamofire
import SwifterSwift
import SnapKit
import AgoraRtcKit
import SwiftyUserDefaults
import MoPub

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
    case end
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

class RoomViewModel {
    let bag = DisposeBag()
    
    func requestEnterRoom() {
        ApiManager.default.reactiveRequest(.enterRoom)
            .subscribe(onNext: { _ in
                
            })
            .disposed(by: bag)
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
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var upButtonWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var toolsView: UIView!
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    private var gradientLayer: CAGradientLayer!
    private var joinChannelSubject = BehaviorSubject<String?>(value: nil)
    private lazy var viewModel = RoomViewModel()
    
    private lazy var searchController: SearchViewController = {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        controller.viewModel = searchViewModel
        return controller
    }()
    private var adView: MPAdView!
    
    private let searchViewModel = SearchViewModel()
    private var channelName: String? {
        didSet {
            channelTextField.text = channelName
            //save to cache
            Defaults[.channelName] = channelName
        }
    }
    
    private let bag = DisposeBag()
    private var hotBag: DisposeBag? = DisposeBag()
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = screenContainer.bounds
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func screenContainerTapped(_ sender: Any) {
        _ = channelTextField.becomeFirstResponder()
    }
    
    @IBAction func playMusicAction(_ sender: Any) {
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
            mManager.leaveChannel()
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
        Android: https://play.google.com/store/apps/details?id=walkie.talkie.talk
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
        if mManager.state == .connected && mManager.channelName == name {
           return
        }
        channelName = name
        checkMicroPermission { [weak self] in
            self?.viewModel.requestEnterRoom()
            self?.mManager.joinChannel(channelId: name)
            HapticFeedback.Impact.medium()
        }
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

extension ViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        sendQueryEvent()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let length = textField.text?.count ?? 0
        let result = length >= 2 && length <= 8
        if result {
            _ = textField.resignFirstResponder()
            joinChannelSubject.onNext(textField.text?.uppercased())
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
            powerButton.setImage(R.image.btn_power_on(), for: .normal)
            powerButton.setBackgroundImage(UIColor.white.image, for: .normal)
        default:
            speakButton.isEnabled = false
            musicButton.isEnabled = false
            pushToTalkButton.isHidden = true
            powerButton.setBackgroundImage(UIColor(hex: 0x363636)?.image, for: .normal)
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
    
        if channelName.wrappedValue.isEmpty, let bag = hotBag {
             searchViewModel.hotRoomsSubject
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] rooms in
                    self?.channelName = rooms.first?.name
                    self?.channelTextField.text = rooms.first?.name
                    self?.hotBag = nil
                })
                .disposed(by: bag)
        }
        
        joinChannelSubject
            .filterNil()
            .filter { !$0.isEmpty }
            .observeOn(MainScheduler.asyncInstance)
            .do(onNext: { [weak self] name in
                self?.channelName = name
            })
            .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] name in
                self?.joinChannel(name)
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
            self?.joinChannel(room.name)
            self?.hideSearchView()
        }
    }
    
    func configureSubview() {
        if Frame.Height.deviceDiagonalIsMinThan4_7 {
            upButtonWidthConstraint.constant = 60
        } else {
            upButtonWidthConstraint.constant = Frame.Scale.width(80)
        }
        upButton.setBackgroundImage(UIColor(hex: 0x363636)?.image, for: .normal)
        downButton.setBackgroundImage(UIColor(hex: 0x363636)?.image, for: .normal)
        musicButton.setBackgroundImage(UIColor(hex: 0x363636)?.image, for: .normal)
        shareButton.setBackgroundImage(UIColor(hex: 0x363636)?.image, for: .normal)
        powerButton.setBackgroundImage(UIColor(hex: 0x363636)?.image, for: .normal)
        
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect.init(x: 0, y: 0, width: 375, height: 100);//CAGradientLayer的控件大小
        gradientLayer.colors = [UIColor(hex: 0xb7fc39)?.cgColor, UIColor(hex: 0x8ed951)?.cgColor, UIColor(hex: 0xb7fc39)?.cgColor]//渐变颜色
        gradientLayer.type = .radial
        gradientLayer.locations = [0.2,0.5,0.8]//渐变起始位置
        gradientLayer.startPoint = CGPoint.init(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint.init(x: 1, y: 0)
        screenContainer.layer.insertSublayer(gradientLayer, at: 0)
        
        adView = MPAdView(adUnitId: "3cc10f8823c6428daf3bbf136dfbb761")
        adView.delegate = self
        adView.frame = CGRect(x: 10, y: Frame.Height.safeAeraTopHeight + 10, width: Frame.Screen.width - 10 * 2, height: 50)
        view.addSubview(adView)
        adView.loadAd(withMaxAdSize: adView.size)
    }
}

extension ViewController: MPAdViewDelegate {
    func viewControllerForPresentingModalView() -> UIViewController! {
        if let naviVC = self.navigationController {
            return naviVC
        } else {
            return self
        }
    }

    func adViewDidLoadAd(_ view: MPAdView!, adSize: CGSize) {
//        Logger.Ads.logEvent(.load)
//        AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .banner, event: .rendered, eventTime: Date(), requestTime: Date()))
//        removeAmazonKeywordsV2(for: view)
//        adsLoadedSignal.onNext((view, adSize))
//        Logger.Ads.logEvent(.impl)
//        makeAwsBid()
        containerTopConstraint.constant = adView.frame.maxY + 10
        UIView.springAnimate(animation: { [weak self] in
            self?.view.layoutIfNeeded()
        })
    }

    func adView(_ view: MPAdView!, didFailToLoadAdWithError error: Error!) {
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
