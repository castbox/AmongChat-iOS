//
//  AmongChat.Home.MainTabController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import NotificationBannerSwift
import SwiftyUserDefaults
import RAMAnimatedTabBarController

extension AmongChat.Home {
    
    class MainTabController: RAMAnimatedTabBarController {
        
        private let imViewModel = IMViewModel()
        private let bag = DisposeBag()
        
        var canShowAvatarGuide = true
        
        private weak var notificationBanner: FloatingNotificationBanner?
        
        var topVC: WalkieTalkie.ViewController? {
            UIApplication.topViewController() as? WalkieTalkie.ViewController
        }
        
        override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private lazy var tabs = Tab.allCases.map { $0.tabTuple }
        
        private let unredVideoRelay = BehaviorRelay(value: true)
        
        override func viewDidLoad() {
            super.viewDidLoad()
            delegate = self
            
            setupLayout()
            setupViewControllers()
            setupEvent()
            InstalledChecker.default.update()
            
            updateDefaultSelectedIndexIfNeed()
            
            //add log for default index
            Logger.Action.log(.home_tab, categoryValue: Tab.allCases[selectedIndex].loggerSource)
            
        }
        
        func dismissNotificationBanner() {
            notificationBanner?.dismiss()
        }
        
    }
}

extension AmongChat.Home.MainTabController {
    
    func updateDefaultSelectedIndexIfNeed() {
        let defaultMainTabIndex = FireRemote.shared.value.defaultMainTabIndex
        if selectedIndex != defaultMainTabIndex, defaultMainTabIndex < Tab.allCases.count {
            setSelectIndex(from: selectedIndex, to: defaultMainTabIndex)
            if defaultMainTabIndex == 1 {
                unredVideoRelay.accept(false)
            }
        }
    }
    
    func showAvatarGuideViewController(with setting: Entity.GlobalSetting) {
        guard let avatarList = setting.changeTip(.avatar)?.list, canShowAvatarGuide,
              let vc =
                UIApplication.navigationController?.viewControllers.first,
              vc.isVisible,
              (vc is AmongChat.Home.TopicsViewController || vc is AmongChat.Home.RelationsViewController),
              Settings.shared.canShowAvatarGuide else {
            return
        }
        let avatarVc = AvatarGuideViewController(avatarList)
        avatarVc.showModal(in: self)
        avatarVc.goHandler = {
            Routes.handle("/avatars")
        }
    }
    
    func onReceive(strangerInvigation user: Entity.UserProfile, room: Peer.FriendUpdatingInfo.Room) {
        guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController else {
            return
        }
        //dismiss previous
        dismissNotificationBanner()

        if (topVC is AmongChat.Home.TopicsViewController) || (topVC is AmongChat.Home.RelationsViewController) || (topVC is AmongChat.CreateRoom.ViewController) || (topVC is Feed.RecommendViewController) || (topVC is AmongChat.Home.ConversationListController) {
            
            Logger.Action.log(.invite_top_dialog_imp, categoryValue: room.topicId)
            
            let view = AmongChat.Home.StrangeInvitationView()
            view.updateContent(user: user, room: room)
            view.bindEvent { [weak self] in
                self?.notificationBanner?.isDismissedByTapEvent = true
                Logger.Action.log(.invite_top_dialog_clk, categoryValue: room.topicId, "join")
                //
                self?.enter(room: room)
                self?.dismissNotificationBanner()
            } ignore: { [weak self] in
                self?.notificationBanner?.isDismissedByTapEvent = true
                Logger.Action.log(.invite_top_dialog_clk, categoryValue: room.topicId, "ignore")
                
                self?.dismissNotificationBanner()
            }
            
            let banner = FloatingNotificationBanner(customView: view)
            banner.autoDismiss = false
            banner.bannerHeight = 112 + (Frame.Height.isXStyle ? 20 : 0)
            banner.onTap = { [weak banner] in
                banner?.isDismissedByTapEvent = true
                Logger.Action.log(.invite_top_dialog_clk, categoryValue: room.topicId, "join")
            }

            banner.rx.notificationBannerDidDisappear
                .subscribe(onCompleted: { [weak banner] in
                    if banner?.isDismissedByTapEvent != true {
                        Logger.Action.log(.invite_top_dialog_auto_dismiss, categoryValue: room.topicId)
                    }
                })
                .disposed(by: bag)
            var topSpace: CGFloat {
                if #available(iOS 13.0, *) {
                    return Frame.Height.isXStyle ? 8 : 0
                } else {
                    return 8 + (Frame.Height.isXStyle ? 0 : 12)
                }
            }
            var hInset: CGFloat = 20
            adaptToIPad {
                hInset = 40
            }
            banner.show(on: self, edgeInsets: UIEdgeInsets(top: topSpace, left: hInset, bottom: 8, right: hInset), cornerRadius: 12)
            notificationBanner = banner
        }
        
    }
    
    
    func enter(room: Peer.FriendUpdatingInfo.Room) {
        guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController else {
            return
        }
        if room.isGroup, let gid = room.gid {
            topVC.enter(group: gid, logSource: .init(.invite))
        } else {
            topVC.enterRoom(roomId: room.roomId, topicId: room.topicId, logSource: .init(.invite))
        }
    }
    
    private func setupLayout() {
        
        if #available(iOS 13.0, *) {
            let appearance = tabBar.standardAppearance
            appearance.shadowImage = R.image.ac_home_tab_shadow()
            appearance.shadowColor = nil
            appearance.backgroundColor = Theme.mainBgColor
            appearance.stackedLayoutAppearance.selected.iconColor = Theme.mainTintColor
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex6: 0x5D5D5D)
            tabBar.standardAppearance = appearance;
        } else {
            // Fallback on earlier versions
            UITabBar.appearance().backgroundColor = Theme.mainBgColor
            tabBar.backgroundImage = UIImage()
            tabBar.tintColor = Theme.mainTintColor
            tabBar.unselectedItemTintColor = UIColor(hex6: 0x5D5D5D)
            tabBar.shadowImage = R.image.ac_home_tab_shadow()
        }
        
    }
    
    private func setupViewControllers() {
        setViewControllers(tabs.map({ $0.0 }), animated: false)
    }
    
    private func setupEvent() {
        imViewModel.invitationObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] user, room in
                guard let `self` = self, let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController,
                      !(topVC is AmongChat.Room.ContainerController) && !(topVC is AmongChat.GroupRoom.ContainerController),
                      !topVC.isRequestingRoom else {
                    return
                }
                
//                self.onReceive(strangerInvigation: user, room: room)
                
                let invitationModal: AmongChat.Home.RoomInvitationModal

                if let currentModal = topVC as? AmongChat.Home.RoomInvitationModal {
                    invitationModal = currentModal
                } else {
                    invitationModal = AmongChat.Home.RoomInvitationModal()
                    invitationModal.modalPresentationStyle = .overCurrentContext
                    topVC.present(invitationModal, animated: false)
                }

                invitationModal.updateContent(user: user, room: room)
                invitationModal.bindEvent(join: { [weak self] in
                    guard let `self` = self else { return }
                    invitationModal.dismiss(animated: false) { [weak self] in
                        self?.enter(room: room)
                    }
                    Logger.Action.log(.invite_dialog_clk, categoryValue: room.topicId, "join")
                }, ignore: {
                    invitationModal.dismiss(animated: false)
                    Logger.Action.log(.invite_dialog_clk, categoryValue: room.topicId, "ignore")
                })
                //                self.onReceive(strangerInvigation: user, room: room)
                HapticFeedback.Impact.warning()
            })
            .disposed(by: bag)
        
        imViewModel.invitationRecommendObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] user, room in
                self?.onReceive(strangerInvigation: user, room: room)
            })
            .disposed(by: bag)
        
        Settings.shared.globalSetting.replay()
            .filterNilAndEmpty()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] setting in
                self?.showAvatarGuideViewController(with: setting)
            })
            .disposed(by: bag)
        //
        checkHaveGroupLiveRoom()
        
        //TODO: combine unread messages and unread notices
        let messageTabHasUnreadReply =
            Observable.combineLatest(Settings.shared.hasUnreadNoticeRelay,
                                     Settings.shared.hasUnreadMessageRelay, Settings.shared.hasUnreadInteractiveMsgRelay)
            .map { $0 || $1 || $2 }
        Observable.combineLatest(messageTabHasUnreadReply,
                                 tabs.first(where: { $0.2 == .messages })?.1
                                    .filterNil()
                                    .take(1) ?? Observable.empty())
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { unread, icon in
                if unread {
                    icon.badgeOn(topInset: 4)
                } else {
                    icon.badgeOff()
                }
            })
            .disposed(by: bag)
        
        Observable.combineLatest(unredVideoRelay,
                                 tabs.first(where: { $0.2 == .video })?.1
                                    .filterNil()
                                    .take(1) ?? Observable.empty())
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { unread, icon in
                if unread {
                    icon.badgeOn(topInset: 4)
                } else {
                    icon.badgeOff()
                }
            })
            .disposed(by: bag)
    }
    
    func checkHaveGroupLiveRoom() {
        Request.groupCheckHaveLive()
            .compactMap { $0 }
            .subscribe(onSuccess: { [weak self] group in
                guard let `self` = self else { return }
                self.topVC?.showAmongAlert(title: R.string.localizable.groupRoomResumeTitle(), message: nil, cancelTitle: R.string.localizable.toastCancel(), confirmTitle: R.string.localizable.groupRoomResumeOk(), confirmAction: { [weak self] in
                    self?.topVC?.enter(group: group)
                })
                
            }, onError: { error in
                
            })
            .disposed(by: bag)

    }
}

extension AmongChat.Home.MainTabController {
    
    enum Tab: CaseIterable {
        case topics
        case video
        case friends
        case messages
        
        var tabTuple: (NavigationViewController, Observable<UIImageView?>, Tab) {
            
            let vc = rootViewController
            let item = RAMAnimatedTabBarItem()
            item.image = normalIcon
            item.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
            item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6.5)
            let anim = AmongChat.Home.MainTabItemAnimation()
            anim.selectedImage = selectedIcon
            anim.normalImage = normalIcon
            item.animation = anim
            vc.tabBarItem = item
            let nav = NavigationViewController(rootViewController: vc)
            nav.tabBarItem = item
            return (nav, anim.iconRelay.asObservable(), self)
        }
        
        private var rootViewController: UIViewController {
            switch self {
            case .topics:
                return AmongChat.Home.TopicsViewController()
            case .video:
                return Feed.RecommendViewController()
            case .friends:
                return AmongChat.Home.RelationsViewController()
            case .messages:
                return AmongChat.Home.ConversationListController()
            }
            
        }
        
        private var normalIcon: UIImage? {
            switch self {
            case .topics:
                return R.image.ac_home_topic_tab_normal()
            case .video:
                return R.image.ac_home_video_tab_normal()
            case .friends:
                return R.image.ac_home_friends_tab_normal()
                
            case .messages:
                return R.image.ac_home_messge_tab_normal()
            }

        }
        
        private var selectedIcon: UIImage? {
            switch self {
            case .topics:
                return R.image.ac_home_topic_tab_selected()
            case .video:
                return R.image.ac_home_video_tab_selected()
            case .friends:
                return R.image.ac_home_friends_tab_selected()
                
            case .messages:
                return R.image.ac_home_messge_tab_selected()
            }

        }
        
        var loggerSource: String {
            switch self {
            case .friends:
                return "friends"
            case .video:
                return "feed"
            case .topics:
                return "game"
            case .messages:
                return "dm"
            }
        }
        
        var index: Int {
            switch self {
            case .friends:
                return 0
            case .video:
                return 1
            case .topics:
                return 2
            case .messages:
                return 3
            }
        }
        
    }
    
}

extension AmongChat.Home.MainTabController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        HapticFeedback.Impact.light()
        let tab = tabs.first { $0.0 == viewController }
        Logger.Action.log(.home_tab, categoryValue: tab?.2.loggerSource)
        
        if tab?.2 == .video {
            unredVideoRelay.accept(false)
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        guard let nav = viewController as? UINavigationController else { return true }
        
        if let _ = nav.viewControllers.first as? AmongChat.Home.ConversationListController {
            
            if AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .chat)) {
                return true
            } else {
                return false
            }
            
        } else {
            return true
        }
        
    }
}

extension AmongChat.Home {
    
    class MainTabItemAnimation: RAMItemAnimation {
        
        var selectedImage: UIImage?
        var normalImage: UIImage?
        
        let iconRelay = BehaviorRelay<UIImageView?>(value: nil)
        
        override func playAnimation(_ icon: UIImageView, textLabel _: UILabel) {
            selectedAnimation(icon)
        }
        
        override func deselectAnimation(_ icon: UIImageView, textLabel _: UILabel, defaultTextColor _: UIColor, defaultIconColor _: UIColor) {
            deselectAnimation(icon)
        }
        
        override func selectedState(_ icon: UIImageView, textLabel _: UILabel) {
            icon.image = selectedImage
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            icon.layer.transform = CATransform3D(scaleX: 1.08, y: 1.08, z: 1).rotated(by: (-25).degreesToRadians.cgFloat, x: 0.001, y: 0, z: 1)
            iconRelay.accept(icon)
        }
        
        override func deselectedState(_ icon: UIImageView, textLabel _: UILabel) {
            icon.image = normalImage
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            icon.layer.transform = CATransform3D(scaleX: 0.8, y: 0.8, z: 1).rotated(by: 0.001, x: 0.001, y: 0, z: 1)
            iconRelay.accept(icon)
        }
        
        private func selectedAnimation(_ icon: UIImageView) {
            icon.image = selectedImage
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            
            UIView.animateKeyframes(withDuration: 0.9, delay: 0.0) {
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1.08, y: 1.08).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1, y: 1).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1.08, y: 1.08).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
            }
        }
        
        private func deselectAnimation(_ icon: UIImageView) {
            icon.image = normalImage
            icon.layer.removeAllAnimations()
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            icon.layer.transform = CATransform3D(scaleX: 0.8, y: 0.8, z: 1)
        }
        
    }
    
}
