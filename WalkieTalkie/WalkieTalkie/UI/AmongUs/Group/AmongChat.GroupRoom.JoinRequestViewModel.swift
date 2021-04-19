//
//  AmongChat.GroupRoom.JoinRequestViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 10/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import HWPanModal

extension AmongChat.GroupRoom {
    class JoinRequestViewModel {
//        static let shared: JoinRequestViewModel?
        let gid: String
        
        var countReplay = BehaviorRelay(value: 0)
        
        let bag = DisposeBag()
        
        init(with gid: String) {
            self.gid = gid
            
            IMManager.shared.newPeerMessageObservable
                .filter { $0.msgType == .groupApply }
                .subscribe(onNext: { [weak self] message in
                    guard let applyMsg = message as? Peer.GroupApplyMessage,
                          applyMsg.action == .request else {
                        return
                    }
                    self?.updateCount()
                })
                .disposed(by: bag)
            
            self.updateCount()
        }
        
        func updateCount() {
            //reqest
            loadData()
                .subscribe()
                .disposed(by: bag)
        }
        
        func loadData() -> Single<Entity.GroupUserList> {
            return Request.appliedUsersOfGroup(gid, skipMs: 0)
                .do(onSuccess: { [weak self](data) in
                    self?.countReplay.accept(data.count ?? 0)
                })
        }
        
        func loadMore(skipMs: Double) -> Single<Entity.GroupUserList> {
            Request.appliedUsersOfGroup(gid, skipMs: skipMs)
                .do(onSuccess: { [weak self](data) in
                    self?.countReplay.accept(data.count ?? 0)
                })
        }
    }
}
