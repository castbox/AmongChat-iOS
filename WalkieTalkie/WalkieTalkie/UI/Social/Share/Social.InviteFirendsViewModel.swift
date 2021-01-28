//
//  Social.InviteFirendsViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 20/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Contacts
import SwiftyContacts

extension Social {
    class InviteFirendsViewModel {
        public var dataSourceReplay = BehaviorRelay<[Item]>(value: [])
        
        fileprivate var items: [Item] = [] {
            didSet {
                dataSourceReplay.accept(items)
            }
        }
        
        private var frientds: [Entity.UserProfile] = []
        
        private let bag = DisposeBag()
        
        
        func updateContactsObservable() -> Observable<[Entity.ContactFriend]> {
            return Observable.create { observer -> Disposable in
                //loading
                SwiftyContacts.fetchContactsOnBackgroundThread { result in
                    //
                    switch result {
                    case .success(let contacts):
                        let arrays = contacts.filter { $0.phoneNumbers.first?.value.stringValue != nil
                        }.map { item -> Entity.ContactFriend in
                            let contact = Entity.ContactFriend(phone: item.phoneNumbers.first!.value.stringValue, name: item.name, count: 1)
                            return contact
                        }
                        .sorted { $0.name.localizedCompare($1.name) == ComparisonResult.orderedAscending }
//                        contacts.forEach {
//                            cdPrint("contact: \($0)")
//                        }
                        observer.onNext(arrays)
                    case .failure(let error):
                        observer.onError(error)
                    }
                }
                return Disposables.create {
                    
                }
            }
        }
        
        func updateContacts() {
            updateContactsObservable()
                .observeOn(SerialDispatchQueueScheduler(qos: .default))
                .do(onNext: { [weak self] items in
                    self?.append(items, group: .contacts)
                })
                .flatMap { items -> Observable<Entity.ListData<Entity.ContactFriend>?> in
                    return Request.upload(contacts: items)
                        .asObservable()
                }
                .subscribe(onNext: { [weak self] item in
                    self?.append(item, group: .contacts)
                })
                .disposed(by: bag)
        }
        
        func fetchContacts() {
            Request.contactList()
                .subscribe { [weak self] listData in
                    self?.append(listData?.list, group: .contacts)
                } onError: { _ in

                }
                .disposed(by: bag)
        }
        
        func showFindCell() {
            append([], group: .find)
        }
        
//        func requestFriends(skipMs: Double = 0) {
//            Request.inviteFriends(skipMs: skipMs)
//                .subscribe(onSuccess: { [weak self](data) in
//                    guard let `self` = self, let data = data else {
//                        return
//                    }
//                    self.frientds.append(contentsOf: data.list ?? [])
//                    self.append(self.frientds, group: .contacts)
//                    guard data.more == true, let lastOpTime = data.list?.last?.opTime else {
//                        return
//                    }
//                    self.requestFriends(skipMs: lastOpTime)
//                }, onError: { (error) in
//                    cdPrint("inviteFriends error: \(error.localizedDescription)")
//                }).disposed(by: bag)
//        }
        
        func append(_ list: [Entity.ContactFriend]?, group: Item.Group) {
            guard let list = list else {
                return
            }
            var items = self.items.filter { item -> Bool in
                return item.group != group
            }
            if group == .contacts {
                items = []
            }
            items.append(Item(userLsit: list, group: group))
            self.items = items.sorted { (old, previous) -> Bool in
                old.group.rawValue < previous.group.rawValue
            }
        }
    }
    
    class ContactsViewModel: InviteFirendsViewModel {
        func search(name key: String?) {
            guard let key = key, !key.isEmpty, let item = items.first else {
                dataSourceReplay.accept(items)
                return
            }
            let result = item.userLsit.filter {
                $0.name.lowercased().contains(key.lowercased()) || $0.phone.lowercased().contains(key.lowercased())
            }
            let filterItem = Item(userLsit: result, group: item.group)
            dataSourceReplay.accept([filterItem])
        }
    }
}

extension Social.InviteFirendsViewModel {
    struct Item {
        enum Group: Int {
            case find
            case contacts
        }
        
        var userLsit: [Entity.ContactFriend]
        let group: Group
        
    }
    
}

extension Social.InviteFirendsViewModel.Item.Group {
    var title: String {
        switch self {
        case .contacts:
            return R.string.localizable.socialInviteContact()
        default:
            return ""
        }
    }
}


extension CNContact {
    var name: String {
        var name = ""
        if !givenName.isEmpty {
            name += givenName
        }
        if !middleName.isEmpty {
            name += middleName
        }
        if !familyName.isEmpty {
            name += familyName
        }
        return name
    }
}
