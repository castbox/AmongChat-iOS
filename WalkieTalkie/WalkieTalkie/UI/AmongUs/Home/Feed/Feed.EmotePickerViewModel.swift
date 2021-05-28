//
//  Feed.EmotePickerViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Feed {
    
    class EmotePickerViewModel {
        var SHEER_ITEM_HEIGHT: CGFloat = 64
        var SHEET_ITEM_SPACE: CGFloat = 0
        
        var sheetHeight: CGFloat {
            return SHEER_ITEM_HEIGHT * 2
        }
        private var allSourceObservable = BehaviorSubject<[Entity.GlobalSetting.Emotes]>(value: [])
        
        var dataSourceSubject = BehaviorSubject<[[Entity.GlobalSetting.Emotes]]>(value: [[]])
        var dataSource: [[Entity.GlobalSetting.Emotes]] = []
        var itemIsSelectable: Bool = true {
            didSet {
                guard let source = try? allSourceObservable.value() else {
                    return
                }
//                let newSource = source.map { item -> Entity.EmojiItem in
//                    var item = item
//                    item.isEnable = itemIsSelectable
//                    return item
//                }
                allSourceObservable.onNext(source)
            }
        }
        
        private let bag = DisposeBag()
        
        init() {
            Settings.shared.globalSetting.replay()
                .map { $0?.feedEmotes }
                .filterNilAndEmpty()
                .bind(to: allSourceObservable)
                .disposed(by: bag)
            
            allSourceObservable
                .map { $0.chunked(into: 10) }
                .map { items -> [[Entity.GlobalSetting.Emotes]] in
                    var items = items
                    //补齐
                    if var last = items.last, last.count < 10 {
                        last.append(contentsOf: Array(repeating: Entity.GlobalSetting.Emotes(id: "", img: nil, resource: nil), count: 10 - last.count))
                        _ = items.removeLast()
                        items.append(last)
                    }
                    return items
                }
                .do(onNext: { [weak self] items in
                    self?.dataSource = items
                })
                .bind(to: dataSourceSubject)
                .disposed(by: bag)
        }
    }
}
