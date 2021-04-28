//
//  Notice.AllNoticeViewModel.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Notice {
    
    class AllNoticeViewModel {
        
        private let systemNoticeRelay = BehaviorRelay<[Entity.Notice]>(value: [])
        private let socialNoticeRelay = BehaviorRelay<[Entity.Notice]>(value: [])
        
        var systemNoticeObservable: Observable<[Entity.Notice]> {
            return systemNoticeRelay.asObservable()
        }
        
        var socialNoticeObservable: Observable<[Entity.Notice]> {
            return socialNoticeRelay.asObservable()
        }
        
        private func loadData() {
                        
            NoticeManager.shared.latestNotice()
                .flatMap { (n) in
                    Request.peerNoticeMessge(skipMs: n?.ms ?? 0)
                }
                .flatMap { (list) in
                    NoticeManager.shared.addNoticeList(list)
                }
                .flatMap({ () in
                    NoticeManager.shared.noticeList()
                })
                .subscribe(onSuccess: { [weak self] (list) in
                    
                    self?.systemNoticeRelay.accept(list.filter({ $0.fromUid == 1001 }))
                    self?.socialNoticeRelay.accept(list.filter({ $0.fromUid == 1002 }))
                    
                }, onError: { (error) in
                    
                })
            
        }
        
    }
    
}
