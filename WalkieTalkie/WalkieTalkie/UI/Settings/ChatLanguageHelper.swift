//
//  ChatLanguageHelper.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2021/1/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct ChatLanguageHelper {
    
    private typealias Language = Entity.GlobalSetting.KeyValue
    
    static var supportedLanguages: Observable<[Entity.GlobalSetting.KeyValue]> {
        
        return Settings.shared.globalSetting.replay()
            .flatMap { (setting) -> Observable<[Language]> in
                if let lans = setting?.chatLanguage,
                   lans.count > 0 {
                    return Observable.just(lans)
                }
                
                return Observable<[Language]>.create { (subscriber) -> Disposable in
                    DispatchQueue.global().async {
                        guard let fileURL = R.file.supportedLanguagesJson(),
                              let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
                              let lans = try? JSONDecoder().decodeAnyData([Language].self, from: data),
                              lans.count > 0 else {
                            subscriber.onError(NSError(domain: "ChatLanguageHelper", code: 500, userInfo: nil))
                            return
                        }
                        subscriber.onNext(lans)
                    }
                    return Disposables.create()
                }
            }
    }
    
    static func currentLanguage(from languages: [Entity.GlobalSetting.KeyValue]) -> Entity.GlobalSetting.KeyValue {
        
        let currentLan: Language
        
        if let lanCode = Settings.shared.amongChatUserProfile.value?.chatLanguage,
           let lan = languages.first(where: { $0.key == lanCode }) {
            currentLan = lan
        } else if let value = Settings.shared.preferredChatLanguage.value {
            currentLan = value
        } else if !Constants.languageCode.isEmpty,
                  let lan = languages.first(where: { $0.key == Constants.languageCode }) {
            currentLan = lan
        } else {
            currentLan = Language(key: "en", value: "English")
        }
        
        return currentLan
    }
    
    static func updateCurrentLanguage(_ language: Entity.GlobalSetting.KeyValue) {
        Settings.shared.preferredChatLanguage.value = language
    }
}

fileprivate extension Entity.GlobalSetting.KeyValue {
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
