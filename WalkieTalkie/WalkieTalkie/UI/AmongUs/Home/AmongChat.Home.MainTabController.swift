//
//  AmongChat.Home.MainTabController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension AmongChat.Home {
    
    class MainTabController: UITabBarController {
        
        private let imViewModel = IMViewModel()
        private let bag = DisposeBag()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            delegate = self
            setupLayout()
            setupViewControllers()
            setupEvent()
        }
        
    }
    
}

extension AmongChat.Home.MainTabController {
    
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
                
            })
            .disposed(by: bag)
        
        imViewModel.invitationRecommendObservable
            .subscribe(onNext: { user, room in
                guard let topVC = UIApplication.topViewController() as? WalkieTalkie.ViewController else {
                    return
                }
                
                if (topVC is AmongChat.Home.TopicsViewController) || (topVC is AmongChat.Home.RelationsViewController) || (topVC is AmongChat.CreateRoom.ViewController) {
                    
                    
                    let invitationModal: AmongChat.Home.RoomJoinViewController
                    
                    if let currentModal = topVC as? AmongChat.Home.RoomJoinViewController {
                        invitationModal = currentModal
                    } else {
                        invitationModal = AmongChat.Home.RoomJoinViewController()
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
                        //                    Logger.Action.log(.invite_dialog_clk, categoryValue: room.topicId, "join")
                    })
                }
                
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
                topicVC.tabBarItem.image = R.image.ac_home_topic_tab()
                topicVC.tabBarItem.imageInsets = UIEdgeInsets(top: 6.5, left: 0, bottom: -6.5, right: 0)
                return NavigationViewController(rootViewController: topicVC)
                
            case .friends:
                let relationVC = AmongChat.Home.RelationsViewController()
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
    }
    
}
