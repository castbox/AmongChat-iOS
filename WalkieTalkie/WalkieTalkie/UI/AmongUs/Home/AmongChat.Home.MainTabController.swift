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
        private weak var notificationBannerDimmerView: UIView?
        
        var topVC: WalkieTalkie.ViewController? {
            UIApplication.topViewController() as? WalkieTalkie.ViewController
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            delegate = self
            setupLayout()
            setupViewControllers()
            setupEvent()
            InstalledChecker.default.update()
        }
        
        func dismissNotificationBanner() {
            notificationBanner?.dismiss()
        }
        
    }
}

extension AmongChat.Home.MainTabController {
    
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
        if (topVC is AmongChat.Home.TopicsViewController) || (topVC is AmongChat.Home.RelationsViewController) || (topVC is AmongChat.CreateRoom.ViewController) {
            //dismiss previous
            dismissNotificationBanner()
            
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
            banner.rx.notificationBannerWillDisappear
                .subscribe(onCompleted: { [weak self] in
                    self?.notificationBannerDimmerView?.removeFromSuperview()
                })
                .disposed(by: bag)
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
            banner.show(on: self, edgeInsets: UIEdgeInsets(top: topSpace, left: 20, bottom: 8, right: 20), cornerRadius: 12)
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
        setViewControllers(Tab.allCases.map({ $0.viewController }), animated: false)
    }
    
    private func setupEvent() {
        imViewModel.invitationObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { user, room in
                guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController,
                      !(topVC is AmongChat.Room.ContainerController) && !(topVC is AmongChat.GroupRoom.ContainerController),
                      !topVC.isRequestingRoom else {
                    return
                }
                
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
        case friends
        case messages
        
        var viewController: UIViewController {
            
            switch self {
            case .topics:
                let topicVC = AmongChat.Home.TopicsViewController()
                let item = RAMAnimatedTabBarItem()
                item.image = R.image.ac_home_topic_tab_normal()
                item.selectedImage = R.image.ac_home_topic_tab_selected()
                item.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6.5)
                let anim = AmongChat.Home.MainTabItemAnimation()
                anim.selectedImage = R.image.ac_home_topic_tab_selected()
                anim.normalImage = R.image.ac_home_topic_tab_normal()
                item.animation = anim
                let nav = NavigationViewController(rootViewController: topicVC)
                nav.tabBarItem = item
                return nav
                
            case .friends:
                let relationVC = AmongChat.Home.RelationsViewController()
                let item = RAMAnimatedTabBarItem()
                item.image = R.image.ac_home_friends_tab_normal()
                item.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6.5)
                let anim = AmongChat.Home.MainTabItemAnimation()
                anim.selectedImage = R.image.ac_home_friends_tab_selected()
                anim.normalImage = R.image.ac_home_friends_tab_normal()
                item.animation = anim
                relationVC.tabBarItem = item
                relationVC.loadViewIfNeeded()
                let nav = NavigationViewController(rootViewController: relationVC)
                nav.tabBarItem = item
                return nav
                
            case .messages:
                let vc = SampleViewController()
                let item = RAMAnimatedTabBarItem()
                item.image = R.image.ac_home_messge_tab_normal()
                item.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6.5)
                let anim = AmongChat.Home.MainTabItemAnimation()
                anim.selectedImage = R.image.ac_home_messge_tab_selected()
                anim.normalImage = R.image.ac_home_messge_tab_normal()
                item.animation = anim
                vc.tabBarItem = item
                let nav = NavigationViewController(rootViewController: vc)
                nav.tabBarItem = item
                return nav
            }
            
        }
        
    }
    
}

extension AmongChat.Home.MainTabController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let nav = viewController as? UINavigationController else { return }
        
        if let _ = nav.viewControllers.first as? AmongChat.Home.TopicsViewController {
            Logger.Action.log(.home_tab, categoryValue: "game")
        } else if let _ = nav.viewControllers.first as? AmongChat.Home.RelationsViewController {
            Logger.Action.log(.home_tab, categoryValue: "friends")
        }
        HapticFeedback.Impact.light()
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        guard let nav = viewController as? UINavigationController else { return true }
        
        if let _ = nav.viewControllers.first as? SampleViewController {
            
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
        
        override func playAnimation(_ icon: UIImageView, textLabel _: UILabel) {
            selectedAnimation(icon)
        }
        
        override func deselectAnimation(_ icon: UIImageView, textLabel _: UILabel, defaultTextColor _: UIColor, defaultIconColor _: UIColor) {
            deselectAnimation(icon)
        }
        
        override func selectedState(_ icon: UIImageView, textLabel _: UILabel) {
            icon.image = selectedImage
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            icon.layer.transform = CATransform3D(scaleX: 1.2, y: 1.2, z: 1).rotated(by: (-25).degreesToRadians.cgFloat, x: 0.001, y: 0, z: 1)
        }
        
        override func deselectedState(_ icon: UIImageView, textLabel _: UILabel) {
            icon.image = normalImage
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            icon.layer.transform = CATransform3D(scaleX: 0.9, y: 0.9, z: 1).rotated(by: 0.001, x: 0.001, y: 0, z: 1)
        }
        
        private func selectedAnimation(_ icon: UIImageView) {
            icon.image = selectedImage
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            
            UIView.animateKeyframes(withDuration: 0.9, delay: 0.0) {
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1.07, y: 1.07).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1.1, y: 1.1).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                    icon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2).rotated(by: (-25).degreesToRadians.cgFloat)
                }
                
            }
        }
        
        private func deselectAnimation(_ icon: UIImageView) {
            icon.image = normalImage
            icon.layer.removeAllAnimations()
            icon.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            icon.layer.transform = CATransform3D(scaleX: 0.9, y: 0.9, z: 1)
            
        }
        
    }
    
}
