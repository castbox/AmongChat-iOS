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
    
    enum ReportOperate: String {
        case mute = "room_mute"
        case unmute = "room_unmute"
        case muteIm = "room_mute_im"
        case unmuteIm = "room_unmute_im"
        case kick = "room_kick"
    }
    
    struct ImageItem {
        let image: UIImage?
    }
}

extension Report.ReportOperate {
    var title: String {
        switch self {
        case .mute:
            return R.string.localizable.adminMuteMicTips()
        case .unmute:
            return R.string.localizable.adminUnmuteMicTips()
        case .muteIm:
            return R.string.localizable.adminMuteImTips()
        case .unmuteIm:
            return R.string.localizable.adminUnmuteImTips()
        case .kick:
            return R.string.localizable.adminKickTips()
        
        }
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

extension Report {
    class ViewModel {
        
        //        private static let reportAlert = Alert.alert(with: .table)
        let bag = DisposeBag()
        
        let dataSourceObjecct = BehaviorSubject<[Entity.Report.Reason]>(value: [])
        
        //        /// 房间举报信息内容
        //                private var roomReportReason: [Entity.Livecast.Live.ReportReason.Reason] = []
        //        /// 个人举报信息内容
        private var userReportReason: [Entity.Report.Reason] = []
        
        let type: ReportType
        private let uid: String
        private let roomId: String
        private let operate: Report.ReportOperate?
        
        init(_ uid: String, type: ReportType, roomId: String, operate: Report.ReportOperate?) {
            self.uid = uid
            self.type = type
            self.roomId = roomId
            self.operate = operate
            
            getReportInfo(type: type)
                .observeOn(MainScheduler.instance)
                .subscribe()
                .disposed(by: bag)
            
        }
        /// 获取用户举报信息
        func getReportInfo(type: ReportType) -> Observable<Bool> {
            return Request.reportReasons().asObservable()
                .flatMap { [weak self] (reason) -> Observable<Bool> in
                    guard let `self` = self else {
                        return Observable.just(false)
                    }

                    switch self.type {
                    case .room:
                        self.dataSourceObjecct.onNext(reason?.reasonDict?.room ?? [])
                    case .user:
                        self.dataSourceObjecct.onNext(reason?.reasonDict?.user ?? [])
                    case .post:
                        self.dataSourceObjecct.onNext(reason?.reasonDict?.post ?? [])
                    case .comment:
                        self.dataSourceObjecct.onNext(reason?.reasonDict?.comment ?? [])
                    case .reply:
                        self.dataSourceObjecct.onNext(reason?.reasonDict?.reply ?? [])
                    }
                    return Observable.just(true)
                }
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
            let roomId = self.roomId
            let operate = self.operate
            return Observable.zip(uploadObservable)
                .flatMap { pics -> Observable<Bool> in
                    return Request.reportContent(type: type, targetID: uid, reasonID: reason.reasonId, note: note, pics: pics.compactMap { $0 }, roomId: roomId, operate: operate).asObservable()
                }
                .flatMap { result -> Observable<Bool> in
//                    guard result, let `self` = self else { return }
                    guard result, let operate = operate else {
                        return Observable.just(result)
                    }
                    switch operate {
                    case .mute:
                        return Request.adminMuteMic(user: uid, roomId: roomId).asObservable()
                    case .unmute:
                        return Request.adminUnmuteMic(user: uid, roomId: roomId).asObservable()
                    case .muteIm:
                        return Request.adminMuteIm(user: uid, roomId: roomId).asObservable()
                    case .unmuteIm:
                        return Request.adminUnmuteIm(user: uid, roomId: roomId).asObservable()
                    case .kick:
                        return Request.adminKick(user: uid, roomId: roomId).asObservable()
                    }
                }
        }
    }
}
