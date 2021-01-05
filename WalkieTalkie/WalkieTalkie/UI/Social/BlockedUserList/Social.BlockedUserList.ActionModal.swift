//
//  Social.BlockedUserList.ActionModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/11.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social.BlockedUserList {
    
    class ActionModal: WalkieTalkie.ViewController, Modalable {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 45
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 20)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var unblockBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xFF7989, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onUnblockBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.alertUnblock(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.appendKern()
            return btn
        }()
                
        private lazy var bgView: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            return v
        }()
                
        private let viewModel: ChannelUserViewModel
        
        var unblockedCallback: (() -> Void)? = nil
        
        
        init(with userViewModel: ChannelUserViewModel) {
            viewModel = userViewModel
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = .clear
            
            view.addSubviews(views: bgView, avatarIV, nameLabel, unblockBtn)
            
            bgView.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.top.equalTo(30)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
                maker.size.equalTo(CGSize(width: 90, height: 90))
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(avatarIV.snp.bottom).offset(10)
                maker.height.equalTo(27)
                maker.left.greaterThanOrEqualToSuperview().offset(25)
            }
            
            unblockBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(59)
                maker.width.equalTo(225)
                maker.centerX.equalToSuperview()
                maker.height.equalTo(48)
            }
            
            let user = viewModel.channelUser
            
            viewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                guard let `self` = self else { return }
                if let _ = image {
                    self.avatarIV.backgroundColor = .clear
                } else {
                    self.avatarIV.backgroundColor = user.iconColor.color()
                }
                self.avatarIV.image = image
            })
                .disposed(by: bag)
            
            nameLabel.text = viewModel.name
            nameLabel.appendKern()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            bgView.addCorner(with: 6)
        }
        
        @objc
        private func onUnblockBtn() {
            defer {
                dismissModal(animated: true)
            }
            // unblock_clk log
            GuruAnalytics.log(event: "unblock_clk", category: "user_list", name: nil, value: nil, content: nil)
            //
//            ChannelUserListViewModel.shared.unblockedUser(viewModel)
            unblockedCallback?()
        }
        
        // MARK: - Modalable
        
        func style() -> Modal.Style {
            return .customHeight
        }
        
        func height() -> CGFloat {
            return 259 + Frame.Height.safeAeraBottomHeight
        }
        
        func modalPresentationStyle() -> UIModalPresentationStyle {
            return .overCurrentContext
        }
        
        func cornerRadius() -> CGFloat {
            return 6
        }
        
        func coverAlpha() -> CGFloat {
            return 0.5
        }
        
        func canAutoDismiss() -> Bool {
            return true
        }
        
    }
    
}
