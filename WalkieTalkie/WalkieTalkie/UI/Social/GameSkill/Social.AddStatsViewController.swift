//
//  Social.AddStatsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/23.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import YPImagePicker

extension Social {
    
    class AddStatsViewController: WalkieTalkie.ViewController {
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatAddStats()
            return lb
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var layoutScrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            return s
        }()
        
        private lazy var doneButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = UIColor(hexString: "#FFF000")
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
            
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onDoneBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var uploadView: StatsView = {
            let s = StatsView(.add)
            s.titleLabel.text = R.string.localizable.amongChatAddStatsUploadScreenshot()
            s.descLabel.text = R.string.localizable.amongChatAddStatsUploadScreenshotDescription()
            s.addHandler = { [weak self] in
                self?.addScreenshot()
            }
            s.removeHandler = { [weak self] in
                self?.screenshot = nil
            }
            return s
        }()
        
        private lazy var exampleView: StatsView = {
            let s = StatsView(.demo)
            s.titleLabel.text = R.string.localizable.amongChatExample()
            s.descLabel.text = R.string.localizable.amongChatAddStatsExampleDescription()
            return s
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = GradientView()
            let l = v.layer
            l.colors = [UIColor(hex6: 0x191919, alpha: 0).cgColor, UIColor(hex6: 0x1D1D1D, alpha: 0.18).cgColor, UIColor(hex6: 0x232323, alpha: 0.57).cgColor, UIColor(hex6: 0x121212).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0)
            l.endPoint = CGPoint(x: 0.5, y: 1)
            l.locations = [0, 0.25, 0.5, 0.75, 1]
            v.addSubviews(views: doneButton)
            doneButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(40)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            return v
        }()
        
        private var screenshot: UIImage? = nil {
            didSet {
                doneButton.isEnabled = (screenshot != nil)
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
        }
        
    }
    
}

extension Social.AddStatsViewController {
    
    // MARK: - UI action
            
    @objc
    private func onDoneBtn() {
        
    }
}

extension Social.AddStatsViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: backBtn, titleLabel, layoutScrollView, bottomGradientView)
        
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
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
        layoutScrollView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(134)
        }
        
        layoutScrollView.addSubviews(views: uploadView, exampleView)
        
        uploadView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(view)
            maker.top.equalTo(26)
        }
        
        exampleView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(view)
            maker.top.equalTo(uploadView.snp.bottom).offset(44)
            maker.bottom.equalToSuperview().offset(-134)
        }
        
    }
    
    private func addScreenshot() {
        selectImage()
            .subscribe(onSuccess: { [weak self] (image) in
                self?.uploadView.screenshotIV.image = image
                self?.uploadView.style = .added
                self?.screenshot = image
            })
            .disposed(by: bag)
    }
    
    private func selectImage() -> Single<UIImage> {
        
        var config = YPImagePickerConfiguration()
        config.screens = [.library]
        config.wordings.permissionPopup.message = R.string.infoplist.nsPhotoLibraryUsageDescription()
        config.library.itemOverlayType = .none
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
        
        return Request.uploadPng(image: image)
            .map { ($0, image) }
    }
    
}

extension Social.AddStatsViewController: YPImagePickerDelegate {
    
    func noPhotos() {
        view.raft.autoShow(.text(MsgError.default.msg ?? R.string.localizable.amongChatUnknownError()))
    }
    
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return true
    }
}
