//
//  FansGroup.CreateGroupViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/29.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension FansGroup {
    
    class CreateGroupViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatCreateAGroup()
            return n
        }()
        
        private lazy var layoutScrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            if #available(iOS 11.0, *) {
                s.contentInsetAdjustmentBehavior = .never
            }
            s.keyboardDismissMode = .onDrag
            return s
        }()
        
        private typealias InfoSetUpView = FansGroup.Views.GroupInfoSetUpView
        private lazy var setUpInfoView: InfoSetUpView = {
            let s = InfoSetUpView()
            return s
        }()
        
        private lazy var bottomTipLabel: UILabel = {
            let l = UILabel()
            l.numberOfLines = 0
            return l
        }()
        
        private lazy var nextButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.amongChatLoginNext(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onNextBtn), for: .primaryActionTriggered)
            btn.rx.isEnable
                .subscribe(onNext: { [weak btn] (_) in
                    
                    guard let `btn` = btn else { return }
                    
                    if btn.isEnabled {
                        btn.backgroundColor = UIColor(hexString: "#FFF000")
                    } else {
                        btn.backgroundColor = UIColor(hexString: "#2B2B2B")
                    }
                })
                .disposed(by: bag)
            btn.isEnabled = false
            return btn
        }()

        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: nextButton)
            nextButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(-33)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            return v
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            bindSubviewEvents()
        }
        
    }
    
}

extension FansGroup.CreateGroupViewController {
    
    // MARK: - UI action
    
    @objc
    private func onNextBtn() {
        
    }
}

extension FansGroup.CreateGroupViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: layoutScrollView, navView, bottomGradientView)
        
        layoutScrollView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.equalToSuperview()
        }
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
        
        layoutScrollView.addSubviews(views: setUpInfoView, bottomTipLabel)
        
        setUpInfoView.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.width.equalToSuperview()
        }
                
        bottomTipLabel.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.top.equalTo(setUpInfoView.snp.bottom).offset(36)
            maker.bottom.equalToSuperview().offset(-150)
        }
        
    }
    
    private func bindSubviewEvents() {
        
        setUpInfoView.addCoverBtn.tapHandler = { [weak self] in
            let vc = FansGroup.SelectCoverModal()
            vc.imageSelectedHandler = { image in
                
            }
            vc.showModal(in: self)
        }
        
        setUpInfoView.topicSetView.tapHandler = { [weak self] in
            let vc = FansGroup.AddTopicViewController()
            vc.topicSelectedHandler = { topic in
                
            }
            self?.presentPanModal(vc)
        }
    }
    
}
