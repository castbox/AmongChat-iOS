//
//  ReportTableHeader.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReportTableHeader: XibLoadableView {
    @IBOutlet weak var titleLabel: UILabel!
    let bag = DisposeBag()
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
//        rx.backgroundColor
//            .setTheme(by: .backgroundWhite)
//            .disposed(by: bag)
//        
//        titleLabel.rx.textColor
//            .setTheme(by: .textBlack)
//            .disposed(by: bag)
    }
}
