//
//  Social.CustomAvatarViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/2/24.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import YPImagePicker
import RxSwift

extension Social {
    
    class CustomAvatarViewController: WalkieTalkie.ViewController {
        
        private enum CustomAvatarSource {
            case album
            case camera
        }
        
        private lazy var containerView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            return v
        }()
        
        private lazy var useAvatarButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.amongChatCustomAvatarUseDefault(), for: .normal)
            btn.backgroundColor = UIColor(hex6: 0x3D3D3D)
            btn.layer.cornerRadius = 24
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    let vc = Social.SelectAvatarViewController()
                    self?.dismiss(animated: false)
                    if let nav = self?.presentingViewController as? UINavigationController {
                        nav.pushViewController(vc)
                    } else {
                        self?.navigationController?.pushViewController(vc)
                    }
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var takePhotoButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.amongChatCustomAvatarTakePhoto(), for: .normal)
            btn.backgroundColor = UIColor(hex6: 0x3D3D3D)
            btn.layer.cornerRadius = 24
            btn.setImage(R.image.ac_pro_icon_24(), for: .normal)
            btn.adjustsImageWhenHighlighted = false
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            btn.addTarget(self, action: #selector(onUploadButtonTouched(_:)), for: .primaryActionTriggered)
            return btn
        }()

        private lazy var selectImageButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.amongChatCustomAvatarSelectImage(), for: .normal)
            btn.backgroundColor = UIColor(hex6: 0x3D3D3D)
            btn.layer.cornerRadius = 24
            btn.setImage(R.image.ac_pro_icon_24(), for: .normal)
            btn.adjustsImageWhenHighlighted = false
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            btn.addTarget(self, action: #selector(onUploadButtonTouched(_:)), for: .primaryActionTriggered)
            return btn
        }()

        private lazy var closeButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.amongChatCustomAvatarClose(), for: .normal)
            btn.backgroundColor = .clear
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.dismiss(animated: false)
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var bgTapGR: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event
                .subscribe(onNext: { [weak self] (g) in
                    guard let `self` = self,
                    !self.containerView.frame.contains(g.location(in: self.view)) else { return }
                    self.dismiss(animated: false)
                })
                .disposed(by: bag)
            return g
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            containerView.addCorner(with: 20)
        }
        
        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            UIView.animate(withDuration: AnimationDuration.normalSlow.rawValue, animations: { [weak self] in
                
                self?.view.backgroundColor = .clear
                self?.containerView.transform = CGAffineTransform(translationX: 0, y: Frame.Screen.bounds.height)
                
            }, completion: { (_) in
                super.dismiss(animated: false, completion: completion)
            })
        }
    }
    
}

extension Social.CustomAvatarViewController {
    
    @objc
    private func onUploadButtonTouched(_ sender: UIButton) {
        
        var source = CustomAvatarSource.album
        
        switch sender {
        case takePhotoButton:
            source = .camera
        case selectImageButton:
            source = .album
        default:
            return
        }
        
        let hudRemoval = self.view.raft.show(.loading)
        
        uploadAvatar(via: source)
            .subscribe(onSuccess: { (_) in
                hudRemoval()
                self.dismiss(animated: false)
            }, onError: { [weak self] (error) in
                hudRemoval()
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
        
    }
    
}

extension Social.CustomAvatarViewController {
    
    private func setupLayout() {
        
        view.backgroundColor = .clear
        view.addGestureRecognizer(bgTapGR)
        
        let stack = UIStackView(arrangedSubviews: [useAvatarButton, takePhotoButton, selectImageButton, closeButton],
                                axis: .vertical,
                                spacing: 12,
                                alignment: .fill,
                                distribution: .fillEqually)
        
        containerView.addSubviews(views: stack)
        
        stack.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(40)
            maker.height.equalTo(48 * 4 + 12 * 3)
            maker.top.equalToSuperview().offset(40)
            maker.bottom.equalToSuperview().offset( -(11 + Frame.Height.safeAeraBottomHeight) )
        }
        
        view.addSubviews(views: containerView)
        
        containerView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
        containerView.transform = CGAffineTransform(translationX: 0, y: Frame.Screen.bounds.height)
        
    }
    
    private func setupEvents() {
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { [weak self] () in
                
                self?.view.backgroundColor = .clear
                UIView.animate(withDuration: AnimationDuration.normalSlow.rawValue, animations: {
                    
                    self?.view.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.7)
                    self?.containerView.transform = .identity
                })
            })
            .disposed(by: bag)
        
        Settings.shared.amongChatAvatarListShown.replay()
            .subscribe(onNext: { [weak self] (ts) in
                if let _ = ts {
                    self?.useAvatarButton.titleLabel?.redDotOff()
                } else {
                    self?.useAvatarButton.titleLabel?.redDotOn(hAlignment: .tailByTail(-8), topInset: 2.5, diameter: 8)
                }
            })
            .disposed(by: bag)
    }
    
    private func uploadAvatar(via source: CustomAvatarSource) -> Single<Bool> {
        
        weak var weakSelf = self
        
        guard let `self` = weakSelf else {
            return Single.just(false)
        }
        
        return upgradeProIfNeeded(source: .upload_avatar)
            .flatMap({ _ in self.selectImage(via: source) })
            .flatMap({ self.uploadImage(image: $0) })
            .flatMap({ self.useAvatar($0) })
            .map ({ _ in true })
    }
    
    private func selectImage(via source: CustomAvatarSource) -> Single<UIImage> {
        
        var config = YPImagePickerConfiguration()
        
        switch source {
        case .album:
            config.screens = [.library]
            config.wordings.permissionPopup.message = R.string.infoplist.nsPhotoLibraryUsageDescription()
        case .camera:
            config.screens = [.photo]
            config.usesFrontCamera = true
            config.wordings.permissionPopup.message = R.string.infoplist.nsCameraUsageDescription()
        }
        
        config.showsPhotoFilters = false
        config.hidesStatusBar = false
        let picker = YPImagePicker(configuration: config)
        picker.imagePickerDelegate = self
        present(picker, animated: true, completion: nil)
        
        return Single<UIImage>.create(subscribe: { (subscriber) -> Disposable in
            
            picker.didFinishPicking { [unowned picker] items, _ in
                
                defer {
                    picker.dismiss(animated: true, completion: nil)
                }

                guard let photo = items.singlePhoto else {
                    subscriber(.error(MsgError.default))
                    return
                }
                
                subscriber(.success(photo.image))
                
            }
            
            return Disposables.create()
            
        })
        
    }
    
    private func uploadImage(image: UIImage) -> Single<(String, UIImage)> {
        
        guard let imgPng = image.scaled(toWidth: 200) else {
            return Single.error(MsgError.default)
        }
        
        return Request.uploadPng(image: imgPng)
            .map { ($0, image) }
    }
    
    private func useAvatar(_ avatarTuple: (String, UIImage)) -> Single<Entity.UserProfile> {
        let profileProto = Entity.ProfileProto(birthday: nil, name: nil, pictureUrl: avatarTuple.0)
        return Request.updateProfile(profileProto)
            .map({ (p) -> Entity.UserProfile in
                guard let profile = p else {
                    throw MsgError.default
                }
                
                return profile
            })
            .do(onSuccess: { (_) in
                AvatarImageView.placeholder = avatarTuple.1
            })
    }
    
    private func upgradeProIfNeeded(source: Logger.IAP.ActionSource) -> Single<Bool> {
        
        guard !Settings.shared.isProValue.value else {
            return Single.just(true)
        }
        
        let purchasedObservable = Single<Bool>.create { [weak self] (subscriber) -> Disposable in
            
            guard let `self` = self else {
                return Disposables.create()
            }
            
            self.presentPremiumView(source: source) { (purchased) in
                
                guard let loginResult = Settings.shared.loginResult.value,
                      !loginResult.isAnonymousUser else {
                    subscriber(.error(MsgError.default))
                    return
                }
                
                subscriber(.success(purchased))
            }
            
            return Disposables.create()
        }
        
        return purchasedObservable
            .flatMap { (purchased) in
                
                guard purchased else {
                    return Single.error(MsgError.default)
                }
                
                return Settings.shared.isProValue.replay()
                    .filter { $0 }
                    .take(1)
                    .timeout(.seconds(10), scheduler: MainScheduler.asyncInstance)
                    .asSingle()
            }
    }

}

extension Social.CustomAvatarViewController: YPImagePickerDelegate {
    
    func noPhotos() {
        view.raft.autoShow(.text(MsgError.default.msg ?? R.string.localizable.amongChatUnknownError()))
    }
    
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return true
    }
}
