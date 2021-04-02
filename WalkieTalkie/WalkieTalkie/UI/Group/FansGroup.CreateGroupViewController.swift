//
//  FansGroup.CreateGroupViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/29.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

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
            s.keyboardDismissMode = .interactive
            s.delegate = self
            return s
        }()
        
        private typealias InfoSetUpView = FansGroup.Views.GroupInfoSetUpView
        private lazy var setUpInfoView: InfoSetUpView = {
            let s = InfoSetUpView()
            s.addCoverBtn.editable = true
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
        
        private let viewModel = ViewModel()
        
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
        
        let hudRemoval = self.view.raft.show(.loading)

        viewModel.createGroup()
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (group) in
                let vc = FansGroup.AddMemberController(groupId: group.gid)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)

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
                self?.viewModel.coverRelay.accept(image)
            }
            vc.showModal(in: self)
        }
        
        setUpInfoView.topicSetView.tapHandler = { [weak self] in
            let vc = FansGroup.AddTopicViewController(self?.viewModel.topicRelay.value?.topic.topicId)
            vc.topicSelectedHandler = { [weak self] topic in
                self?.viewModel.topicRelay.accept(topic)
            }
            self?.presentPanModal(vc)
        }
        
        viewModel.coverRelay
            .bind(to: setUpInfoView.addCoverBtn.coverRelay)
            .disposed(by: bag)
        
        setUpInfoView.nameView.inputField.rx.text
            .bind(to: viewModel.nameRelay)
            .disposed(by: bag)
        
        setUpInfoView.descriptionView.inputTextView.rx.text
            .bind(to: viewModel.descriptionRelay)
            .disposed(by: bag)
        
        viewModel.topicRelay
            .subscribe(onNext: { [weak self] (topic) in
                self?.setUpInfoView.topicSetView.bindViewModel(topic)
            })
            .disposed(by: bag)
        
        viewModel.isValid
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: bag)
        
        let textingView = Observable.merge(
            setUpInfoView.nameView.isEdtingRelay
                .map({ [weak self] (isEditing) -> UIView? in
                    return isEditing ? self?.setUpInfoView.nameView : nil
                }),
            setUpInfoView.descriptionView.isEdtingRelay
                .map({ (isEditing) -> UIView? in
                    return isEditing ? self.setUpInfoView.descriptionView : nil
                })
        )
        .filterNil()
        
        Observable.combineLatest(RxKeyboard.instance.visibleHeight.asObservable(), textingView)
            .subscribe(onNext: { [weak self] keyboardVisibleHeight, textingView in
                                
                guard let `self` = self else { return }
                
                guard keyboardVisibleHeight > 0 else {
                    self.layoutScrollView.contentOffset = .zero
                    return
                }
                
                let rect = self.setUpInfoView.convert(textingView.frame, to: self.view)
                let distance = Frame.Screen.height - keyboardVisibleHeight - rect.maxY
                
                guard distance < 0 else {
                    return
                }
                
                UIView.animate(withDuration: RxKeyboard.instance.animationDuration) {
                    self.layoutScrollView.contentOffset.y = self.layoutScrollView.contentOffset.y - distance
                }
            })
            .disposed(by: bag)

    }
    
}

extension FansGroup.CreateGroupViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let distance = scrollView.contentOffset.y
        
        setUpInfoView.enlargeTopGbHeight(extraHeight: -distance)
        
        navView.snp.updateConstraints { (maker) in
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(min(0, -distance / 3))
        }
        
        navView.alpha = 1 - distance / 49
    }
    
}

extension FansGroup.CreateGroupViewController {
    
    class ViewModel {
        
        let coverRelay = BehaviorRelay<UIImage?>(value: nil)
        
        let nameRelay = BehaviorRelay<String?>(value: nil)

        let descriptionRelay = BehaviorRelay<String?>(value: nil)
        
        let topicRelay = BehaviorRelay<FansGroup.TopicViewModel?>(value: nil)
        
        var isValid: Observable<Bool> {
            return Observable.combineLatest(coverRelay, nameRelay, descriptionRelay, topicRelay)
                .map({ cover, name, desc, topic -> Bool in
                    
                    guard let _ = cover,
                          let name = name,
                          !name.isEmpty,
                          let desc = desc,
                          !desc.isEmpty,
                          let _ = topic else {
                        return false
                    }
                    
                    return true
                })
        }
        
        func createGroup() -> Single<Entity.Group> {
            
            guard let cover = coverRelay.value,
                  let name = nameRelay.value,
                  let desc = descriptionRelay.value,
                  let topic = topicRelay.value else {
                return Single.error(MsgError.default)
            }
            
            return uploadCover(coverImage: cover)
                .flatMap { (coverUrl) in
                    let groupProto = Entity.GroupProto(topicId: topic.topic.topicId, cover: coverUrl, name: name, description: desc)
                    return Request.createGroup(group: groupProto)
                }
        }
        
        private func uploadCover(coverImage: UIImage) -> Single<String> {
            guard let imgPng = coverImage.scaled(toWidth: 300) else {
                return Single.error(MsgError.default)
            }
            
            return Request.uploadPng(image: imgPng)
        }
        
    }
    
}
