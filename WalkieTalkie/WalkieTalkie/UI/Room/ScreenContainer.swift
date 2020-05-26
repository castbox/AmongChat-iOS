//
//  ScreenContainer.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults

protocol ScreenContainerDelegate: class {
    func containerShouldUpdate(channel: Room?)
    func containerShouldJoinChannel(name: String?, directly: Bool) -> Bool
    func containerShouldLeaveChannel()
}

enum Mode: String, DefaultsSerializable {
    case `public`
    case `private`
    
    init(index: Int) {
        switch index {
        case 1:
            self = .private
        default:
            self = .public
        }
    }
    
    var intValue: Int {
        switch self {
        case .public:
            return 0
        case .private:
            return 1
        }
    }
    
    var channelType: ChannelType {
        switch self {
        case .public:
            return .public
        case .private:
            return .private
        }
    }
}

class ScreenContainer: XibLoadableView {
        
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var innerShadowView: UIImageView!
    @IBOutlet weak var connectStateLabel: UILabel!
    @IBOutlet weak var tagView: UILabel!
    @IBOutlet weak var lockIconView: UIImageView!
    @IBOutlet weak var channelTextField: ChannelNameField!
    @IBOutlet weak var micView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    
    let searchViewModel = SearchViewModel()
    weak var delegate: ScreenContainerDelegate?
    
    private lazy var searchController: SearchViewController = {
        let controller = R.storyboard.main.searchViewController()!
        controller.viewModel = searchViewModel
        return controller
    }()
    private var isShowSearchPage: Bool = false
    
    private (set) var mode: Mode = .public
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bindSubviewEvent()
    }

    private let bag = DisposeBag()
    
    private var state: ConnectState = .disconnected
    var mManager: ChatRoomManager!
    
    var channel: Room! {
        didSet {
            updateSubviewStyle()
            updateMemberCount(with: channel)
            channel.updateJoinInterval()
            //            Defaults[\.channel] = channel
        }
    }
    
    private var channelName: String {
        return channel.name
    }
    
    override var intrinsicContentSize: CGSize {
        let height: CGFloat
        //        isShowSearchPage = true
        if isShowSearchPage {
            height = 125 + 215
        } else {
            height = 125
        }
        return CGSize(width: Frame.Screen.width - 50 * 2, height: height)
    }
    
    
    override func becomeFirstResponder() -> Bool {
        return channelTextField.becomeFirstResponder()
    }
    
    func update(state: ConnectState) {
        update(state: state, old: self.state)
        self.state = state
    }
    
    func updateMicView(alpha: CGFloat) {
        micView.alpha = alpha
    }
    
    func update(mode: Mode) {
        self.mode = mode
        searchViewModel.mode = mode
        Defaults[\.mode] = mode
        
        //检查当前频道名称，如果和模式不相符则处理
        let previousChannel = Defaults.channel(for: mode)
//        switch mode {
//        case .public:
////            if channelName.isPrivate {
//                //find previous channel
////            }
//        case .private:
//            if !channelName.isPrivate {
//                //find previous channel
//                delegate?.containerShouldUpdate(channel: previousChannel)
//            }
//        }
        delegate?.containerShouldUpdate(channel: previousChannel)
        
        UIView.transition(with: backgroundView, duration: AnimationDuration.fast.rawValue, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.backgroundView.image = mode.channelType.screenImage(with: false)
        })
    }
    
    private func update(state to: ConnectState, old state: ConnectState) {
        switch to {
        case .maxMic:
            micView.image = R.image.icon_mic_disable()
            micView.alpha = 1
        case .connected, .preparing:
            micView.image = R.image.icon_mic()
            micView.alpha = 0.3
        case .talking:
            micView.image = R.image.icon_mic()
            micView.alpha = 1
        default:
            micView.alpha = 0
        }
        connectStateLabel.text = to.title.uppercased()
        let channelType = channel.name.channelType
        backgroundView.image = channelType.screenImage(with: mManager.isConnectedState)
        innerShadowView.image = channelType.screenInnerShadowImage(with: mManager.isConnectedState)
        
    }
    
    func updateMemberCount(with room: Room?) {
        guard let room = room else {
            numberLabel.text = ""
            return
        }
        if !mManager.isConnectedState,
            room.isReachMaxUser {
            numberLabel.text = "--"
        } else {
            numberLabel.text = room.userCountForShow
        }
    }
    
    func updateSubviewStyle() {
        channelTextField.text = channel.showName
        backgroundView.image = mode.channelType.screenImage(with: false)
        innerShadowView.image = mode.channelType.screenInnerShadowImage(with: false)
        //        backgroundColor = channel.name.channelType.screenColor
        //        searchController.setChannel(type: channel.name.channelType)
        lockIconView.isHidden = !channel.isPrivate
        tagView.isHidden = !lockIconView.isHidden
    }
}

extension ScreenContainer {
    func showCanEnterSecretChannelAlert(_ completionHandler: @escaping (Bool) -> Void) {
        let alertVC = UIAlertController(title: R.string.localizable.enterSecretChannelAlertTitle(),
                                        message: R.string.localizable.enterSecretChannelAlertDesc(),
                                        preferredStyle: UIAlertController.Style.alert)
        let resetAction = UIAlertAction(title: R.string.localizable.alertOk(), style: .default, handler: { _ in
            completionHandler(true)
        })
        
        let cancelAction = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel) { _ in
            completionHandler(false)
        }
        alertVC.addAction(cancelAction)
        alertVC.addAction(resetAction)
        viewContainingController()?.present(alertVC, animated: true, completion: nil)
    }
    
    func sendQueryEvent() {
        if let text = channelTextField.text?.uppercased(),
            text.count >= 2,
            text != channelName.showName {
            searchController.set(query: text)
        } else {
            searchController.set(query: "")
        }
    }
    
    func showSearchView() {
        guard let superController = viewContainingController(),
            searchController.view.superview == nil else {
                return
        }
        Logger.UserAction.log(.channel_list)
        searchController.willMove(toParent: superController)
        superController.view.addSubview(searchController.view)
        searchController.didMove(toParent: superController)
//        searchController.view.addCorner(with: 50, corners: [.bottomLeft, .bottomRight])
        searchController.view.snp.makeConstraints { make in
            make.left.width.equalTo(self)
            make.top.equalTo(self).offset(125)
            make.height.equalTo(200)
        }
        isShowSearchPage = true
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
//        UIView.propertyAnimation(dampingRatio: 1, animation: { [weak self] in
//        UIView.animate(withDuration: 0.4) { [weak self] in
//            self?.roundCorners(topLeft: 12, topRight: 12, bottomLeft: 50, bottomRight: 50)
//            self?.searchController.view.roundCorners([.bottomLeft, .bottomRight], radius: 50)
//        }
    }
    
    func hideSearchView() {
        isShowSearchPage = false
        searchController.willMove(toParent: nil)
        searchController.removeFromParent()
        searchController.view.removeFromSuperview()
        endEditing(true)
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
//        UIView.animate(withDuration: 0.4) { [weak self] in
//            self?.roundCorners(.allCorners, radius: 12)
//        }
//        UIView.propertyAnimation(dampingRatio: 1, animation: { [weak self] in
//            self?.layoutIfNeeded()
//        })
    }
    
    func bindSubviewEvent() {
        channelTextField.enableAutoClear = true
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
        
        searchController.selectRoomHandler = { [weak self] room in
            guard let `self` = self,
                let delegate = self.delegate else { return }
            if delegate.containerShouldJoinChannel(name: room.name, directly: true) {
                Logger.UserAction.log(.channel_choice, room.name)
                self.updateMemberCount(with: room)
            }
            self.hideSearchView()
        }
        
        channelTextField.didBeginEditing = { [weak self] _ in
            self?.sendQueryEvent()
        }
        channelTextField.didReturn = { [weak self] text in
            guard let text = text else {
                //offline
                self?.delegate?.containerShouldLeaveChannel()
                return
            }
            let joinChannelBlock: (String?) -> Void = { name in
                //                self?.joinChannelSubject.onNext(name)
                _ = self?.delegate?.containerShouldJoinChannel(name: name, directly: false)
                Logger.UserAction.log(.channel_create, name)
            }
            //check if in private channel
            if text.count == PasswordGenerator.shared.totalCount,
                FireStore.shared.secretChannels.contains(where: { $0.name == "_\(text)"}) {
                //show text
                self?.showCanEnterSecretChannelAlert { confirm in
                    if confirm {
                        joinChannelBlock("_\(text)")
                    } else {
                        joinChannelBlock(text)
                    }
                }
            } else {
                joinChannelBlock(text)
            }
        }
        
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
    }
}
