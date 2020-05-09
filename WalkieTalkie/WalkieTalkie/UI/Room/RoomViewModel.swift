//
//  RoomViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class RoomViewModel {
    let bag = DisposeBag()
    
    func requestEnterRoom() {
        ApiManager.default.reactiveRequest(.enterRoom)
            .subscribe(onNext: { _ in
                
            })
            .disposed(by: bag)
    }
}
