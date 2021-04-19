//
//  Report.ViewModel.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru. All rights reserved.
//

import Foundation
import SnapKit
import RxSwift

struct Report {
    enum ReportType: String {
        case room
        case user
        case post
        case comment
        case reply
    }
    
    struct ImageItem {
        let image: UIImage?
    }
}

extension Report.ReportType {
    var title: String {
        switch self {
//        case .room:
//            return R.string.localizable.reportRoom()
        case .user:
            return R.string.localizable.reportUser()
        default:
            return "Report " + self.rawValue
        }
    }
}

extension Entity {
    struct Report {
        
        struct Reason {
            let reason_id: Int
            let reason_text: String
        }
        
        struct Source {
            let room: [Reason]
            let user: [Reason]
            let post: [Reason]
            let comment: [Reason]
            let reply: [Reason]
        }
        
        let report_type: [String]
        let reason_dict: Source?
    }
}

extension Report {
    class ViewModel {
        
        //        private static let reportAlert = Alert.alert(with: .table)
        let bag = DisposeBag()
        
        let dataSourceObjecct = BehaviorSubject<[Entity.Report.Reason]>(value: [])
        
        /// 房间举报信息内容
        //        private var roomReportReason: [Entity.Livecast.Live.ReportReason.Reason] = []
        
        //        /// 个人举报信息内容
        //        private var userReportReason: [Entity.Livecast.Live.ReportReason.Reason] = []
        
        var selectedIndex: Int = -1
        private let uid: String
        private let type: ReportType
        
        init(_ uid: String, type: ReportType) {
            self.uid = uid
            self.type = type
            
            getReportInfo(type: type)
                .observeOn(MainScheduler.instance)
                .subscribe()
                .disposed(by: bag)
            
        }
        /// 获取用户举报信息
        func getReportInfo(type: ReportType) -> Observable<Bool> {
            //            return Request.Livecast.Live.reportReason()
            //                .flatMap { [weak self] (reason) -> Observable<Bool> in
            //                    guard let `self` = self else {
            //                        return Observable.just(false)
            //                    }
            //
            //                    switch self.type {
            //                    case .room:
            //                        self.dataSourceObjecct.onNext(reason.reason_dict?.room ?? [])
            //                    case .user:
            //                        self.dataSourceObjecct.onNext(reason.reason_dict?.user ?? [])
            //                    case .post:
            //                        self.dataSourceObjecct.onNext(reason.reason_dict?.post ?? [])
            //                    case .comment:
            //                        self.dataSourceObjecct.onNext(reason.reason_dict?.comment ?? [])
            //                    case .reply:
            //                        self.dataSourceObjecct.onNext(reason.reason_dict?.reply ?? [])
            //                    }
            //
            //                    return Observable.just(true)
            //                }
            
            return Observable.just(true)
        }
        
        func report(with reason: Entity.Report.Reason, note: String, images: [UIImage]) -> Observable<Bool> {
            //upload image
            var uploadObservable: [Observable<String?>] {
                guard !images.isEmpty else {
                    return [Observable.just(nil)]
                }
                return images.map { Request.uploadPng(image: $0).asObservable().map { Optional($0) } }
            }
            let uid = self.uid
            let type = self.type
            //            return Observable.zip(uploadObservable)
            //                .flatMap { pics -> Observable<Bool> in
            //                    return Request.Livecast.Live.reportContent(type: type.rawValue, targetID: uid, reasonID: reason.reason_id, note: note, pics: pics.compactMap { $0 })
            //                }
            return Observable.just(true)
        }
    }
}
