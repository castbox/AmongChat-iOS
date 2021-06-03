//
//  Feed.ListViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 02/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift

extension Feed {
    class ListViewModel {
        let bag = DisposeBag()
        
        func reportPlay(_ pid: String?) {
            guard let pid = pid else {
                return
            }
//            Request.feedReportPlay(pid)
//                .subscribe()
//                .disposed(by: bag)
        }
        
        func reportPlayFinish(_ pid: String?) {
            guard let pid = pid else {
                return
            }
//            Request.feedReportPlayFinish(pid)
//                .subscribe()
//                .disposed(by: bag)
        }
        
        func reportNotIntereasted(_ pid: String?) -> Single<Bool> {
//            guard let pid = pid else {
                return .just(false)
//            }
//            return Request.feedReportNotIntereasted(pid: pid)
//                .subscribe()
//                .disposed(by: bag)
        }
        
        func reportShare(_ pid: String?) {
            guard let pid = pid else {
                return
            }
            Request.feedReportShare(pid)
                .subscribe()
                .disposed(by: bag)
        }
        
        func feedDelete(_ pid: String?) -> Single<Bool> {
            guard let pid = pid else {
                return .just(false)
            }
            return Request.feedDelete(pid)
        }
    }
}
