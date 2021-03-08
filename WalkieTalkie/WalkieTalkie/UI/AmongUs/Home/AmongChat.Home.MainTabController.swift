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
        override func viewDidLoad() {
            super.viewDidLoad()
            delegate = self
            setupLayout()
            setupViewControllers()
            setupEvent()
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
    
    func onReceive(strangerInvigation user: Entity.UserProfile, room: Entity.FriendUpdatingInfo.Room) {
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
    
    
    func enter(room: Entity.FriendUpdatingInfo.Room) {
        guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController else {
            return
        }
        topVC.enterRoom(roomId: room.roomId, topicId: room.topicId)
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
        viewControllers = Tab.allCases.map({ $0.viewController })
    }
    
    private func setupEvent() {
        imViewModel.invitationObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { user, room in
                guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController,
                      !(topVC is AmongChat.Room.ViewController),
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
                invitationModal.bindEvent(join: {
                    invitationModal.dismiss(animated: false) {
                        guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController else {
                            return
                        }
                        topVC.enterRoom(roomId: room.roomId, topicId: room.topicId)
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
    }
    
}

extension AmongChat.Home.MainTabController {
    
    enum Tab: CaseIterable {
        case topics
        case friends
        
        var viewController: UIViewController {
            
            switch self {
            case .topics:
                let topicVC = AmongChat.Home.TopicsViewController()
                let item = RAMAnimatedTabBarItem()
                item.animation = AmongChat.Home.MainTabItemAnimation()
                topicVC.tabBarItem = item
                topicVC.tabBarItem.image = R.image.ac_home_topic_tab()
                topicVC.tabBarItem.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
                return NavigationViewController(rootViewController: topicVC)
                
            case .friends:
                let relationVC = AmongChat.Home.RelationsViewController()
                let item = RAMAnimatedTabBarItem()
                item.animation = AmongChat.Home.MainTabItemAnimation()
                relationVC.tabBarItem = item
                relationVC.tabBarItem.image = R.image.ac_home_friends_tab()
                relationVC.tabBarItem.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
                relationVC.loadViewIfNeeded()
                return NavigationViewController(rootViewController: relationVC)
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
    
}

extension AmongChat.Home {
    
    class MainTabItemAnimation: RAMItemAnimation {
        
        override func playAnimation(_ icon: UIImageView, textLabel _: UILabel) {
            selectedAnimation(icon)
        }
        
        override func deselectAnimation(_ icon: UIImageView, textLabel _: UILabel, defaultTextColor _: UIColor, defaultIconColor _: UIColor) {
            deselectAnimation(icon)
        }
        
        override func selectedState(_ icon: UIImageView, textLabel _: UILabel) {
            if let iconImage = icon.image {
                let renderImage = iconImage.withRenderingMode(.alwaysTemplate)
                icon.image = renderImage
                icon.tintColor = Theme.mainTintColor
            }
            icon.layer.transform = CATransform3DMakeRotation((-25) / 180.0 * .pi, 1.0, 1.0, 1.0)
        }
        
        private func selectedAnimation(_ icon: UIImageView) {
            
            if let iconImage = icon.image {
                let renderImage = iconImage.withRenderingMode(.alwaysTemplate)
                icon.image = renderImage
                icon.tintColor = Theme.mainTintColor
            }
            
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.0) {
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.1) {
                    icon.layer.transform = CATransform3D(scaleX: 0.72, y: 0.72, z: 1)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.3) {
                    icon.layer.transform = CATransform3D(scaleX: 1.07, y: 1.07, z: 1)
                    icon.layer.transform.rotate(by: (-25) / 180.0 * .pi, x: 1, y: 1, z: 1)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.25) {
                    icon.layer.transform = CATransform3D(scaleX: 0.9, y: 0.9, z: 1)
                    icon.layer.transform.rotate(by: (-25) / 180.0 * .pi, x: 1, y: 1, z: 1)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.65, relativeDuration: 0.35) {
                    icon.layer.transform = CATransform3D(scaleX: 1, y: 1, z: 1)
                    icon.layer.transform.rotate(by: (-25) / 180.0 * .pi, x: 1, y: 1, z: 1)
                }
                
            }
        }
        
        private func deselectAnimation(_ icon: UIImageView) {
            
            if let iconImage = icon.image {
                let renderImage = iconImage.withRenderingMode(.alwaysTemplate)
                icon.image = renderImage
                icon.tintColor = UIColor(hex6: 0x5D5D5D)
            }
            
            icon.transform = .identity
            
        }
        
    }
    
}
