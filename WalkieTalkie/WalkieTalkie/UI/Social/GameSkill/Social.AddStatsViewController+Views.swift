//
//  Social.AddStatsViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/24.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension Social.AddStatsViewController {
    
    class StatsView: UIView {
        
        class DashedLineBorderView: UIView {
            
            override class var layerClass: AnyClass {
                return CAShapeLayer.self
            }
            
            override var layer: CAShapeLayer {
                return super.layer as! CAShapeLayer
            }
            
            override func layoutSubviews() {
                super.layoutSubviews()
                layer.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
            }
        }
        
        enum Style {
            case add
            case added
            case demo
        }
        
        private let bag = DisposeBag()
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.textAlignment = .left
            return lb
        }()
        
        private(set) lazy var descLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.numberOfLines = 0
            lb.textAlignment = .left
            return lb
        }()
        
        private lazy var addView: DashedLineBorderView = {
            let v = DashedLineBorderView()
            
            v.layer.strokeColor = UIColor(hex6: 0x313131).cgColor
            v.layer.lineDashPattern = [15, 15]
            v.layer.fillColor = nil
            v.layer.lineWidth = 4
            v.layer.lineCap = .round
            v.layer.cornerRadius = 12
            
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_add_stats_add(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.addHandler?()
                })
                .disposed(by: bag)
            
            v.addSubview(btn)
            
            btn.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            return v
        }()
        
        private(set) lazy var screenshotIV: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.contentMode = .scaleAspectFill
            i.clipsToBounds = true
            let tapGR = UITapGestureRecognizer()
            i.isUserInteractionEnabled = true
            i.addGestureRecognizer(tapGR)
            tapGR.rx.event.subscribe(onNext: { [weak self] (_) in
                self?.viewImageHandler?(self?.screenshotIV.image)
            })
            .disposed(by: bag)
            return i
        }()
        
        private lazy var removeBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_add_stats_remove(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.screenshotIV.image = nil
                    self?.style = .add
                    self?.removeHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        var style: Style {
            didSet {
                updateLayout()
            }
        }
        
        var addHandler: (() -> Void)? = nil
        var removeHandler: (() -> Void)? = nil
        var viewImageHandler: ((UIImage?) -> Void)? = nil
        
        init(_ style: Style) {
            self.style = style
            super.init(frame: .zero)
            setUpLayout()
            updateLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            addSubviews(views: titleLabel, descLabel, addView, screenshotIV, removeBtn)
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalToSuperview()
                maker.height.equalTo(27)
            }
            
            descLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(titleLabel)
                maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            }
            
            addView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(titleLabel)
                maker.top.equalTo(descLabel.snp.bottom).offset(16)
                maker.bottom.equalToSuperview()
                maker.height.equalTo(addView.snp.width).multipliedBy(180.0 / 335.0)
            }
            
            screenshotIV.snp.makeConstraints { (maker) in
                maker.edges.equalTo(addView)
            }
            
            removeBtn.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(24)
                maker.top.trailing.equalTo(addView).inset(12)
            }
        }
        
        private func updateLayout() {
            switch style {
            case .add:
                screenshotIV.isHidden = true
                removeBtn.isHidden = true
                addView.isHidden = false
            case .added:
                screenshotIV.isHidden = false
                removeBtn.isHidden = false
                addView.isHidden = true
            case .demo:
                screenshotIV.isHidden = false
                removeBtn.isHidden = true
                addView.isHidden = true
            }
        }
    }
    
}
