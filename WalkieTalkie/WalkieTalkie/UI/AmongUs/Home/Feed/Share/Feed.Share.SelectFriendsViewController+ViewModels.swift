//
//  Feed.Share.SelectFriendsViewController+ViewModels.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/22.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
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
        
        private(set) var indexTitles: [String] = []
        
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
        
        init() {
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
            
            var followingSections: [SectionModel] = []
            
            for user in userViewModels {
                let title = String(user.user.name?.prefix(1) ?? "").uppercased()
                if let section = followingSections.first(where: { $0.sectionType == .followingUsers && $0.title == title }) {
                    section.users.append(user)
                } else {
                    let section = SectionModel(title: title, sectionType: .followingUsers)
                    section.users.append(user)
                    followingSections.append(section)
                }
            }
            
            followingSections = followingSections.sorted { $0.title < $1.title }
            
            sectionModels.append(contentsOf: followingSections)
            
            indexTitles = sectionModels.map({ $0.indexTitle })
            
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
        
        var indexTitle: String {
            
            switch sectionType {
            case .recentChats:
                return "0"
            case .friends:
                return "1"
            case .followingPlaceholder:
                return "2"
            case .followingUsers:
                return title
            }
        }
        
        init(title: String, sectionType: SectionType) {
            self.title = title
            self.sectionType = sectionType
        }
    }
    
}
