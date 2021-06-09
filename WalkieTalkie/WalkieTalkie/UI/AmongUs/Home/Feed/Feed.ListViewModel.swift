//
//  Feed.ListViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 02/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire

extension Feed {
    class ListViewModel {
        let bag = DisposeBag()
        
        func reportPlay(_ pid: String?) {
            guard let pid = pid else {
                return
            }
            Request.feedReportPlay(pid)
                .subscribe()
                .disposed(by: bag)
        }
        
        func reportPlayFinish(_ pid: String?) {
            guard let pid = pid else {
                return
            }
            Request.feedReportPlayFinish(pid)
                .subscribe()
                .disposed(by: bag)
        }
        
        func reportNotIntereasted(_ pid: String?) -> Single<Bool> {
            guard let pid = pid else {
                return .just(false)
            }
            return Request.feedReportNotIntereasted(pid: pid)
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
        
        func download(fileUrl: String, progressHandler: @escaping (CGFloat) -> Void, completionHandler: @escaping (URL?) -> Void) {
            
            let destination: DownloadRequest.Destination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent("/downloadForExport/\(Date().timeIntervalSince1970.int).mp4")
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            AF.download(fileUrl, to: destination)
                .downloadProgress(closure : { (progress) in
                    cdPrint("progress: \(progress.fractionCompleted)")
                    progressHandler(progress.fractionCompleted.cgFloat)
                }).response { (response) in
                    completionHandler(response.fileURL)
//                    print(response)
                }
        }
    }
}
