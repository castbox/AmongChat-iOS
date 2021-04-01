//
//  AmongChat.GroupRoom.MembersViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Contacts
import SwiftyContacts

extension AmongChat.GroupRoom {
    class MembersViewModel {
        public var dataSourceReplay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        
        fileprivate var items: [Entity.UserProfile] = [] {
            didSet {
                dataSourceReplay.accept(items)
            }
        }
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
        
//        func updateContacts() {
//            updateContactsObservable()
//                .observeOn(SerialDispatchQueueScheduler(qos: .default))
//                .do(onNext: { [weak self] items in
//                    self?.append(items, group: .contacts)
//                })
//                .flatMap { items -> Observable<Entity.ListData<Entity.ContactFriend>?> in
//                    return Request.upload(contacts: items)
//                        .asObservable()
//                }
//                .subscribe(onNext: { [weak self] item in
//                    self?.append(item?.list, group: .contacts)
//                })
//                .disposed(by: bag)
//        }
//
//        func fetchContacts() {
//            Request.contactList()
//                .subscribe { [weak self] listData in
//                    self?.append(listData?.list, group: .contacts)
//                } onError: { _ in
//
//                }
//                .disposed(by: bag)
//        }
//
//        func showFindCell() {
//            append([], group: .find)
//        }
        
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
        
//        func append(_ list: [Entity.ContactFriend]?, group: Item.Group) {
//            guard let list = list else {
//                return
//            }
//            var items = self.items.filter { item -> Bool in
//                return item.group != group
//            }
//            if group == .contacts {
//                items = []
//            }
//            items.append(Item(userLsit: list, group: group))
//            self.items = items.sorted { (old, previous) -> Bool in
//                old.group.rawValue < previous.group.rawValue
//            }
//        }
    }
}
