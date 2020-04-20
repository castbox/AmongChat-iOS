//
//  PremiumFreqControl.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/9/26.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import Firebase

class PremiumFreqControl {
    private let bag = DisposeBag()
    private let timeupSignal = PublishSubject<Void>()
    
    let appInstallDate: Date
    
    var lastRecord: Record {
        didSet {
            Settings.shared.premiumShowRecord = lastRecord
            recordSubject.onNext(lastRecord)
        }
    }
    
    private let recordSubject: PublishSubject<Record>
    
    let showSubject = PublishSubject<Int>()
    
    
    init() {
        appInstallDate = Settings.shared.appInstallDate
        lastRecord = Settings.shared.premiumShowRecord
        recordSubject = PublishSubject<Record>()
        Observable.combineLatest(FireRemote.shared.remoteValue().debug("premium"), recordSubject.debug("premium")) { [weak self] (config, rec) -> Observable<Int> in
            guard let `self` = self else { return .never()}
            return self.nextShowTime(config: config.value.premiumPromopt, rec: rec)
        }
        .flatMapLatest({ $0 })
        .subscribe(showSubject)
        .disposed(by: bag)
    }
    
    /// check and active if possible
    public func show() -> Bool {
        if canShow(with: FireRemote.shared.value.premiumPromopt) {
            let newRecord = Record(lastImpressionTime: Date(), currentTimes: lastRecord.currentTimes + 1)
            DispatchQueue.global().async {
                self.lastRecord = newRecord
            }
            NSLog("show permitted")
            return true
        } else {
            NSLog("show denied")
            return false
        }
    }
    
    public func forceShow() {
        let newRecord = Record(lastImpressionTime: Date(), currentTimes: lastRecord.currentTimes + 1)
        DispatchQueue.global().async {
            self.lastRecord = newRecord
        }
    }
    
    private func nextShowTime(config: FireRemote.Value.PremiumPrompt, rec: Record) -> Observable<Int> {
        if !config.enable || config.maxTimes <= rec.currentTimes {
            return .never()
        }
        let newUserFireDate = appInstallDate.addingTimeInterval(TimeInterval(config.newUserSeconds))
        let now = Date()
        if now < newUserFireDate {
            return .never()
        }
        if let lastTime = rec.lastImpressionTime,
            now < lastTime.addingTimeInterval(TimeInterval(config.intervalSeconds)) {
            let waitingSeconds = config.intervalSeconds - Int(now.timeIntervalSince(lastTime)) + 1
            return Observable<Int>.timer(.seconds(waitingSeconds), scheduler: MainScheduler.instance)
        } else {
            return Observable.timer(.milliseconds(100), scheduler: MainScheduler.instance)
        }
    }
    
    private func canShow(with remoteConfig: FireRemote.Value.PremiumPrompt) -> Bool {
        guard remoteConfig.enable,
            lastRecord.currentTimes < remoteConfig.maxTimes else { return false }
        let now = Date()
        guard Int(now.timeIntervalSince(appInstallDate)) >= remoteConfig.newUserSeconds else { return false }
        if let lastShowDate = lastRecord.lastImpressionTime,
            Int(now.timeIntervalSince(lastShowDate)) < remoteConfig.intervalSeconds {
            return false
        } else {
            return true
        }
    }
    
//    public func canShowSignal() -> Signal<Void> {
//        return timeupSignal.asSignal { (error) -> SharedSequence<SignalSharingStrategy, ()> in
//
//        }
//    }
}

extension PremiumFreqControl {
    struct Record {
        
        private static var dateFormatter: DateFormatter?

        static var jsonDateTimeFormatter: DateFormatter {
            if (dateFormatter == nil) {
                dateFormatter = DateFormatter()
                dateFormatter!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
            }
            return dateFormatter!
        }

        
        let lastImpressionTime: Date?
        let currentTimes: Int
        
        
        init?(str: String) {
            let json = JSON(parseJSON: str)
            guard let ct = json["current_times"].int else {
                    return nil
            }
            if let lastImpressionStr = json["last_impression_time"].string,
                let dt = Record.jsonDateTimeFormatter.date(from: lastImpressionStr) {
                lastImpressionTime = dt
            } else {
                lastImpressionTime = nil
            }
            currentTimes = ct
        }
        
        init(lastImpressionTime: Date?, currentTimes: Int) {
            self.lastImpressionTime = lastImpressionTime
            self.currentTimes = currentTimes
        }
        
        func toString() -> String {
            var json = JSON(dictionaryLiteral: ("current_times", currentTimes))
            if let dt = lastImpressionTime {
                json["last_impression_time"] = JSON(Record.jsonDateTimeFormatter.string(from: dt))
            }
            return json.rawString() ?? ""
        }
    }
}
