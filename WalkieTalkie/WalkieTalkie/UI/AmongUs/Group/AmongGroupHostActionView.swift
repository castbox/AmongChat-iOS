//
//  AmongGroupHostActionView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/7/1.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

class AmongGroupHostActionView: UIView {
    
    private let bag = DisposeBag()
    
    private(set) lazy var icon: UIImageView = {
        let i = UIImageView()
        return i
    }()
    
    private(set) lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = R.font.nunitoExtraBold(size: 12)
        l.textColor = .white
        return l
    }()
    
    private lazy var tapGr: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer()
        gr.rx.event.subscribe(onNext: { [weak self] _ in
            self?.actionHandler?()
        })
        .disposed(by: bag)
        return gr
    }()
    
    var actionHandler: (() -> Void)? = nil
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpLayout() {
        
        addSubviews(views: icon, titleLabel)
        
        icon.snp.makeConstraints { maker in
            maker.width.height.equalTo(24)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(39)
        }
        
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(8)
            maker.height.equalTo(16)
            maker.top.equalTo(icon.snp.bottom).offset(7)
        }
        
        addGestureRecognizer(tapGr)
    }
    
}
