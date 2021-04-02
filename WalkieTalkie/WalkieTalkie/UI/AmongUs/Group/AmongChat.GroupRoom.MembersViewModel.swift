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
        private let groupId: String;
        init(groupId: String) {
            self.groupId = groupId
        }
        
        func loadData(withCompletionHandler: ((Error?) -> Void)? = nil) {
            Request.roomUserList(groupId: groupId)
                .subscribe { room in
                    
                } onError: { error in
                    
                }
//                Request.followingList(uid: uid, skipMs: 0)
//                    .subscribe(onSuccess: { [weak self](data) in
//                        removeBlock()
//                        guard let `self` = self, let data = data else { return }
//                        self.userList = data.list ?? []
//                        if self.userList.isEmpty {
//                            self.addNoDataView(R.string.localizable.errorNoFollowing())
//                        }
//                        self.tableView.endLoadMore(data.more ?? false)
//                    }, onError: { [weak self](error) in
//                        removeBlock()
//                        self?.addErrorView({ [weak self] in
//                            self?.loadData()
//                        })
//                        cdPrint("followingList error: \(error.localizedDescription)")
//                    }).disposed(by: bag)
        }
        
//        func loadMore() {
//            let skipMS = userList.last?.opTime ?? 0
//            
//            Request.followingList(uid: uid, skipMs: skipMS)
//                .subscribe(onSuccess: { [weak self](data) in
//                    guard let data = data else { return }
//                    let list =  data.list ?? []
//                    var origenList = self?.userList
//                    list.forEach({ origenList?.append($0)})
//                    self?.userList = origenList ?? []
//                    self?.tableView.endLoadMore(data.more ?? false)
//                }, onError: { (error) in
//                    cdPrint("followingList error: \(error.localizedDescription)")
//                }).disposed(by: bag)
//        }
//
        
    }
}
