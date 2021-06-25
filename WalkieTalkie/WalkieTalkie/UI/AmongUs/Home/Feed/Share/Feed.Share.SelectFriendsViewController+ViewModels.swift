//
//  Feed.Share.SelectFriendsViewController+ViewModels.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/22.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Feed.Share.SelectFriendsViewController {
    
    class ViewModel {
        
        private let bag = DisposeBag()
        
        private var recentChatUsers: [UserViewModel] = [] {
            didSet {
                buildSections()
            }
        }
        
        private(set) var sectionModels: [SectionModel] = []
        
        private var followingUsers: [Entity.UserProfile] = [] {
            didSet {
                buildSections()
            }
        }
        
        private let maximumSelected = 10
        
        private let selectedUsersRelay = BehaviorRelay<[UserViewModel]>(value: [])
        private(set) var selectedUsers: [UserViewModel] {
            get {
                return selectedUsersRelay.value
            }
            
            set {
                selectedUsersRelay.accept(newValue)
            }
        }
        
        var hasSelectedUser: Observable<Bool> {
            return selectedUsersRelay.map { $0.count > 0 }
        }
        
        private(set) var hasMore: Bool = true
        
        private let dataUpdated = PublishSubject<Void>()
        var dataUpdatedSignal: Observable<Void> {
            return dataUpdated.asObservable().observeOn(MainScheduler.asyncInstance)
        }
        
        init(initialSelectedUsers: [Entity.UserProfile]) {
            selectedUsers = initialSelectedUsers.map({ UserViewModel(user: $0) })
            FollowingUsersManager.shared.allUsersObservable()
                .subscribe(onNext: { [weak self] users in
                    self?.followingUsers = users
                }, onError: { error in
                    
                })
                .disposed(by: bag)
            
            loadData().subscribe().disposed(by: bag)
            loadRecentData()
        }
        
        private func buildSections() {
            
            sectionModels.removeAll()
            
            if recentChatUsers.count > 0 {
                let recentSection = SectionModel(title: R.string.localizable.amongChatFeedRecentChats(), sectionType: .recentChats)
                recentSection.users = recentChatUsers
                sectionModels.append(recentSection)
            }
            
            let userViewModels = followingUsers.map { UserViewModel(user: $0)}
            
            let friends = userViewModels.filter({ $0.user.isFollower ?? false })
            
            if friends.count > 0 {
                let friendSection = SectionModel(title: R.string.localizable.amongChatFeedFriends(), sectionType: .friends)
                friendSection.users = friends
                sectionModels.append(friendSection)
            }
            
            if userViewModels.count > 0 {
                let followingPlaceholder = SectionModel(title: R.string.localizable.profileFollowing(), sectionType: .followingPlaceholder)
                sectionModels.append(followingPlaceholder)
            }
            
            let collation = UILocalizedIndexedCollation.current()
            
            var followingSections: [SectionModel] = collation.sectionTitles.map {
                SectionModel(title: $0, sectionType: .followingUsers)
            }

            for user in userViewModels {
                let index = collation.section(for: user, collationStringSelector: #selector(getter: user.userName))
                followingSections[index].users.append(user)
            }
            
            followingSections = followingSections.compactMap({
                guard $0.users.count > 0 else { return nil }
                return $0
            })
            
            sectionModels.append(contentsOf: followingSections)
                        
            dataUpdated.onNext(())
        }
        
        func loadData() -> Single<Bool> {
            
            guard let selfUid = Settings.shared.loginResult.value?.uid,
                  hasMore else {
                return Single.just(false)
            }
            
            return Request.followingList(uid: selfUid, limit: 20, skipMs: followingUsers.last?.opTime ?? 0)
                .do(onSuccess: { [weak self] data in
                    self?.hasMore = data.more
                })
                .map({ $0.more })
        }
        
        private func loadRecentData() {
            
            DMManager.shared.conversations(limit: 5)
                .map {
                    $0.compactMap { conversation in
                        conversation.message.fromUser.asUserProfile()
                    }
                }
                .subscribe(onSuccess: { [weak self] recentChatUsers in
                    self?.recentChatUsers = recentChatUsers.map({ UserViewModel(user: $0) })
                }, onError: { error in
                    
                })
                .disposed(by: bag)
            
        }
        
        func selectUser(_ user: UserViewModel) -> (actionValid: Bool, message: String?) {
            
            if selectedUsers.contains(where: { $0.user.uid == user.user.uid }) {
                selectedUsers.removeAll { $0.user.uid == user.user.uid }
                return (true, nil)
            } else {
                if selectedUsers.count >= maximumSelected {
                    return (false, R.string.localizable.feedShareUserSelectedReachMax())
                } else {
                    selectedUsers.append(user)
                    return (true, nil)
                }
            }
            
        }
        
        func isUserSelected(_ user: UserViewModel) -> Bool {
            return selectedUsers.contains { $0.user.uid == user.user.uid }
        }
        
        func searchUser(name: String) -> Single<[UserViewModel]> {
            
            return Single.create { [weak self] subscriber in
                
                let reult = self?.followingUsers.filter {
                    ($0.name ?? "").contains(name)
                }
                .map {
                    UserViewModel(user: $0)
                } ?? []
                
                subscriber(.success(reult))
                
                return Disposables.create()
            }
        }
        
        func mapIndexTitleToSection(index: NSInteger) -> Int {
            
            guard let section = sectionModels.safe(index), section.sectionType == .followingUsers else {
                return index
            }
            
            return index + 1
        }
        
    }
    
}

fileprivate extension Entity.DMProfile {
    
    func asUserProfile() -> Entity.UserProfile? {
        
        guard let jsonData = try? asDictionary().jsonData() else {
            return nil
        }
        
        return Entity.UserProfile(from: jsonData)
    }
    
}

extension Feed.Share.SelectFriendsViewController {
    
    class UserViewModel {
        
        private(set) var user: Entity.UserProfile
        
        init(user: Entity.UserProfile) {
            self.user = user
        }
        
        @objc var userName: String {
            return user.name ?? ""
        }
        
    }
    
}

extension Feed.Share.SelectFriendsViewController {
    
    class SectionModel {
        
        enum SectionType {
            case recentChats
            case friends
            case followingPlaceholder
            case followingUsers
        }
        
        var users: [UserViewModel] = []
        let title: String
        let sectionType: SectionType
        var icon: UIImage? {
            switch sectionType {
            case .recentChats:
                return R.image.ac_feed_share_recent()
            case .friends:
                return R.image.ac_feed_share_friends()
            case .followingPlaceholder:
                return R.image.ac_feed_share_followings()
            case .followingUsers:
                return nil
            }
        }
        
        var indexView: UIView? {
            
            switch sectionType {
            case .recentChats:
                let i = Feed.Share.SelectFriendsViewController.TableIndexImage(image: R.image.ac_feed_share_recent_index_normal()?.withRenderingMode(.alwaysTemplate))
                i.contentMode = .scaleAspectFill
                i.tintColor = UIColor(hex6: 0x595959)
                return i
            case .friends:
                let i = Feed.Share.SelectFriendsViewController.TableIndexImage(image: R.image.ac_feed_share_friend_index_normal()?.withRenderingMode(.alwaysTemplate))
                i.contentMode = .scaleAspectFill
                i.tintColor = UIColor(hex6: 0x595959)
                return i
            case .followingPlaceholder:
                return nil
            case .followingUsers:
                let l = Feed.Share.SelectFriendsViewController.TableIndexLabel(text: title)
                l.textAlignment = .center
                l.tintColor = UIColor(hex6: 0x595959)
                return l
            }
        }
        
        init(title: String, sectionType: SectionType) {
            self.title = title
            self.sectionType = sectionType
        }
    }
    
}
