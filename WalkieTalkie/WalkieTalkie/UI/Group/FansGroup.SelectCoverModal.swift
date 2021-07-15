//
//  FansGroup.SelectCoverModal.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/31.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension FansGroup {
    
    class SelectCoverModal: WalkieTalkie.ViewController {
        
        private enum CustomAvatarSource {
            case album
            case selfie
        }
        
        private lazy var takeSelfieButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.amongChatGroupCoverTakePhoto(), for: .normal)
            btn.backgroundColor = UIColor(hex6: 0x3D3D3D)
            btn.layer.cornerRadius = 24
            btn.addTarget(self, action: #selector(onActionButtonTouched(_:)), for: .primaryActionTriggered)
            return btn
        }()

        private lazy var selectImageButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitle(R.string.localizable.amongChatGroupCoverSelectImage(), for: .normal)
            btn.backgroundColor = UIColor(hex6: 0x3D3D3D)
            btn.layer.cornerRadius = 24
            btn.addTarget(self, action: #selector(onActionButtonTouched(_:)), for: .primaryActionTriggered)
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
                    self?.dismissModal()
                })
                .disposed(by: bag)
            return btn
        }()
        
        var imageSelectedHandler: ((UIImage) -> Void)? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
        }
    }
    
}

extension FansGroup.SelectCoverModal {
    
    @objc
    private func onActionButtonTouched(_ sender: UIButton) {
        
        var source = CustomAvatarSource.album
        
        switch sender {
        case takeSelfieButton:
            source = .selfie
        case selectImageButton:
            source = .album
        default:
            return
        }
                
        selectImage(via: source)
            .subscribe(onSuccess: {[weak self] (image) in
                self?.imageSelectedHandler?(image)
                self?.dismissModal()
            })
            .disposed(by: bag)
        
    }
    
}

extension FansGroup.SelectCoverModal {
    
    private func setUpLayout() {
        
        view.backgroundColor = UIColor(hex6: 0x222222)

        let stack = UIStackView(arrangedSubviews: [takeSelfieButton, selectImageButton, closeButton],
                                axis: .vertical,
                                spacing: 12,
                                alignment: .fill,
                                distribution: .fillEqually)
        
        view.addSubviews(views: stack)
        
        stack.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(40)
            maker.height.equalTo(48 * 3 + 12 * 2)
            maker.top.equalToSuperview().offset(40)
        }
        
    }
        
    private func selectImage(via source: CustomAvatarSource) -> Single<UIImage> {
        return Single<UIImage>.create(subscribe: { (subscriber) -> Disposable in
            
            ImagePickerManager.shared.selectMedia(for: .squareImage, sourceType: source == .album ? .photoLibrary: .camera) { result in
                guard let item = result,
                      let image = item.image else {
                    subscriber(.error(MsgError.default))
                    return
                }
                subscriber(.success(image))
            }
            return Disposables.create()
        })

//
//        var config = YPImagePickerConfiguration()
//
//        switch source {
//        case .album:
//            config.screens = [.library]
//            config.wordings.permissionPopup.message = R.string.infoplist.nsPhotoLibraryUsageDescription()
//        case .selfie:
//            config.screens = [.photo]
//            config.usesFrontCamera = true
//            config.wordings.permissionPopup.message = R.string.infoplist.nsCameraUsageDescription()
//        }
//
//        config.showsPhotoFilters = false
//        config.hidesStatusBar = false
//        let picker = YPImagePicker(configuration: config)
//        present(picker, animated: true, completion: nil)
//
//        return Single<UIImage>.create(subscribe: { (subscriber) -> Disposable in
//
//            picker.didFinishPicking { [unowned picker] items, _ in
//
//                defer {
//                    picker.dismiss(animated: true, completion: nil)
//                }
//
//                guard let photo = items.singlePhoto else {
//                    subscriber(.error(MsgError.default))
//                    return
//                }
//
//                subscriber(.success(photo.image))
//
//            }
//
//            return Disposables.create()
//
//        })
        
    }
    
}

extension FansGroup.SelectCoverModal: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 243 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    override func cornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0.7
    }
    
}
