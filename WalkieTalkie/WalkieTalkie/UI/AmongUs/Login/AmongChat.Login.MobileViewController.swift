//
//  AmongChat.Login.MobileViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/19.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension AmongChat.Login {
    
    class MobileViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private lazy var mobileIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_login_mobile())
            return i
        }()
        
        private lazy var mobileTitle: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 28)
            lb.textColor = .white
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatLoginMobileTitle()
            return lb
        }()
        
        private lazy var mobileInputContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            v.layer.cornerRadius = 24
            let seperator = UIView()
            seperator.backgroundColor = UIColor(hex6: 0xD8D8D8)
            
            let tapView: UIView = {
                let v = UIView()
                v.backgroundColor = .clear
                v.isUserInteractionEnabled = true
                return v
            }()
            
            let regionLabelTap = UITapGestureRecognizer()
            
            regionLabelTap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.showRegionPicker()
                })
                .disposed(by: bag)
            
            tapView.addGestureRecognizer(regionLabelTap)
            
            v.addSubviews(views: tapView, flagLabel, regionLabel, seperator, mobileInputField)
            
            tapView.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.trailing.equalTo(seperator.snp.leading)
            }
            
            flagLabel.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(16)
                maker.centerY.equalTo(mobileInputField)
            }
            
            regionLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(flagLabel.snp.trailing).offset(4)
                maker.centerY.equalTo(mobileInputField)
                maker.trailing.equalTo(seperator.snp.leading).offset(-8)
            }
            
            seperator.snp.makeConstraints { (maker) in
                maker.height.equalTo(27)
                maker.width.equalTo(2)
                maker.leading.equalToSuperview().inset(84)
                maker.centerY.equalToSuperview()
            }
            
            mobileInputField.snp.makeConstraints { (maker) in
                maker.leading.equalTo(seperator.snp.trailing).offset(8)
                maker.trailing.equalToSuperview().inset(16)
                maker.top.bottom.equalToSuperview()
            }
            flagLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            regionLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            return v
        }()
        
        private lazy var flagLabel: UILabel = {
            let lb = UILabel()
            lb.font = UIFont.systemFont(ofSize: 20)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var regionLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .black
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var mobileInputField: UITextField = {
            let f = MobileInputField(frame: CGRect.zero)
            f.backgroundColor = .clear
            f.borderStyle = .none
            f.keyboardType = .numberPad
            f.textColor = .black
            f.delegate = self
            f.font = R.font.nunitoExtraBold(size: 20)
            f.adjustsFontSizeToFitWidth = true
            return f
        }()
        
        private lazy var smsTip: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 14)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatLoginSmsTip()
            return lb
        }()
        
        private lazy var nextBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onNextBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.amongChatLoginNext(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.backgroundColor = UIColor(hex6: 0x2B2B2B)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 24
            btn.isEnabled = false
            return btn
        }()
                
        private typealias Region = Entity.Region
        
        private var currentRegion: Region? = nil {
            didSet {
                
                guard let region = currentRegion else {
                    return
                }
                flagLabel.text = region.regionCode.emojiFlag
                regionLabel.text = region.telCode
            }
        }
        
        private var regions: [Region] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            setupEvent()
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            
            guard let touches = event?.allTouches else {
                return
            }
            
            for touch in touches {
                if !mobileInputContainer.frame.contains(touch.location(in: view)) {
                    view.endEditing(true)
                    break
                }
            }
        }
        
    }
    
}

extension AmongChat.Login.MobileViewController {
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
    
    @objc
    private func onNextBtn() {
        
        guard let region = currentRegion else {
            return
        }
        
        guard let phone = mobileInputField.text else {
            return
        }
        
        let hudRemoval = view.raft.show(.loading)
        
        let completion = { [weak self] in
            hudRemoval()
            self?.view.isUserInteractionEnabled = true
        }
        
        view.isUserInteractionEnabled = false
        Request.requestSmsCode(telRegion: region.telCode, phoneNumber: phone)
            .subscribe(onSuccess: { (response) in
                completion()
                
            }, onError: { [weak self] (_) in
                completion()
                self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
    }
    
}

extension AmongChat.Login.MobileViewController {
    
    private func setupLayout() {
        
        view.addSubviews(views: backBtn, mobileIcon, mobileTitle, mobileInputContainer, smsTip, nextBtn)
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
            maker.width.height.equalTo(24)
        }
        
        mobileIcon.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom).offset(24)
        }
        
        mobileTitle.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.top.equalTo(mobileIcon.snp.bottom).offset(8)
        }
        
        mobileInputContainer.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.height.equalTo(48)
            maker.top.equalTo(mobileTitle.snp.bottom).offset(Frame.Scale.height(72))
        }
        
        smsTip.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.top.equalTo(mobileInputContainer.snp.bottom).offset(12)
        }
        
        nextBtn.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.height.equalTo(48)
            maker.top.equalTo(smsTip.snp.bottom).offset(Frame.Scale.height(60))
        }
        
    }
    
    private func setupData() {
        
        Observable<[Region]>.create { (subscriber) -> Disposable in
            DispatchQueue.global().async {
                guard let fileURL = R.file.mobileRegionsJson(),
                      let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
                      let regions = try? JSONDecoder().decodeAnyData([Region].self, from: data),
                      regions.count > 0 else {
                    subscriber.onNext([Region.default])
                    return
                }
                subscriber.onNext(regions.sorted(by: \.region))
            }
            return Disposables.create()
        }
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(onNext: { [weak self] (regions) in
            self?.currentRegion = regions.first(where: { $0.regionCode == Constants.countryCode }) ?? Region.default
            self?.regions = regions
        })
        .disposed(by: bag)
        
    }
    
    private func setupEvent() {
        
        mobileInputField.rx.text
            .subscribe(onNext: { [weak self] (str) in
                
                if let str = str,
                   str.count > 6 {
                    self?.nextBtn.isEnabled = true
                    self?.nextBtn.backgroundColor = UIColor(hex6: 0xFFF000)
                } else {
                    self?.nextBtn.isEnabled = false
                    self?.nextBtn.backgroundColor = UIColor(hex6: 0x2B2B2B)
                }
                
            })
            .disposed(by: bag)
        
    }
    
    private func showRegionPicker() {
        guard regions.count > 0 else { return }
        
        let modal = AmongChat.Login.RegionModal(dataSource: regions,
                                                initialRegion: currentRegion ?? Region.default)
        modal.selectRegion = { [weak self] (region) in
            self?.currentRegion = region
        }
        modal.showModal(in: self)
    }
        
}

extension AmongChat.Login.MobileViewController: UITextFieldDelegate {
    
}

fileprivate extension AmongChat.Login.MobileViewController {
    
    class MobileInputField: UITextField {
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            
            if (action == #selector(UIResponderStandardEditActions.paste(_:))) {
                return false
            }
            
            return super.canPerformAction(action, withSender: sender)
        }
        
    }
    
}
