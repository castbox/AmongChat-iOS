//
//  FansGroup.GroupsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/30.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension FansGroup {
    
    class GroupsViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroup()
            return n
        }()
        
        private lazy var gotoCreateButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.amongChatCreateNewGroup(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    let vc = FansGroup.CreateGroupViewController()
                    self?.navigationController?.pushViewController(vc)
                })
                .disposed(by: bag)
            return btn
        }()

        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: gotoCreateButton)
            gotoCreateButton.snp.makeConstraints { (maker) in
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
        }
    }
    
}

extension FansGroup.GroupsViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, bottomGradientView)
        
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
        
    }
    
}
