//
//  UIImageViewNetwork.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import Kingfisher
import RxSwift

extension UIImageView {
//    func setImage(with urlString: String?, placeholder: UIImage? = nil) {
//        kf.cancelDownloadTask()
//        guard let url = URL(string: urlString) else {
//            image = placeholder
//            return
//        }
//        let resource = ImageResource(downloadURL: url, cacheKey: urlString)
//        var kf = self.kf
//        kf.indicatorType = .activity
//        self.kf.setImage(with: resource, placeholder: placeholder)
//    }
}


protocol ResourceComaptible {
    func asResource() -> Resource?
}

extension String: ResourceComaptible {
    func asResource() -> Resource? {
        return self.robustURL
    }
}

extension URL: ResourceComaptible {
    func asResource() -> Resource? {
        return self
    }
}

extension UIImageView {
    
    @discardableResult
    func setImage(
        with resource: ResourceComaptible?,
        placeholder: Placeholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask? {
    
        switch resource?.asResource() {
        case .some(let element):
            var optionsInfo: KingfisherOptionsInfo = [.transition(.fade(0.3))]
            if let option = options {
                optionsInfo.append(contentsOf: option)
            }
            return kf.setImage(with: element, placeholder: placeholder, options: optionsInfo, progressBlock: progressBlock, completionHandler: completionHandler)
        case .none:
            kf.cancelDownloadTask()
            if let placeholder = placeholder {
                placeholder.add(to: self)
            } else {
                image = nil
            }
            return nil
        }
    }
}

extension UIButton {
    
    @discardableResult
    func setImage(
        with source: ResourceComaptible?,
        for state: UIControl.State,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask? {
        
        switch source?.asResource() {
        case .some(let element):
            var optionsInfo: KingfisherOptionsInfo = [.transition(.fade(0.3))]
            if let option = options {
                optionsInfo.append(contentsOf: option)
            }
            return kf.setImage(with: element, for: state, placeholder: placeholder, options: optionsInfo, progressBlock: progressBlock, completionHandler: completionHandler)
        case .none:
            kf.cancelImageDownloadTask()
            if let placeholder = placeholder {
                setImage(placeholder, for: state)
            } else {
                setImage(nil, for: state)
            }
            return nil
        }
    }
    
    @discardableResult
    func setBackgroundImage(
        with source: ResourceComaptible?,
        for state: UIControl.State,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) -> DownloadTask? {
        
        switch source?.asResource() {
        case .some(let element):
            var optionsInfo: KingfisherOptionsInfo = [.transition(.fade(0.3))]
            if let option = options {
                optionsInfo.append(contentsOf: option)
            }
            return kf.setBackgroundImage(with: element, for: state, placeholder: placeholder, options: optionsInfo, progressBlock: progressBlock, completionHandler: completionHandler)
        case .none:
            kf.cancelBackgroundImageDownloadTask()
            setBackgroundImage(placeholder, for: state)
            return nil
        }
    }
}

extension KingfisherManager {
    
    func retrieveImageObservable(with url: URL) -> Observable<UIImage> {
        return Observable.create { observer -> Disposable in
            let task = KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let value):
                    observer.onNext(value.image)
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        }
    }
}
