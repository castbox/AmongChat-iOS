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
import ImageViewer

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
            s.viewImageHandler = { [weak self] (image) in
                self?.showImageViewer(image)
            }
            return s
        }()
        
        private lazy var exampleView: StatsView = {
            let s = StatsView(.demo)
            s.titleLabel.text = R.string.localizable.amongChatExample()
            s.descLabel.text = R.string.localizable.amongChatAddStatsExampleDescription()
            s.screenshotIV.setImage(with: game.skill.example)
            s.viewImageHandler = { [weak self] (image) in
                self?.showImageViewer(image)
            }
            return s
        }()
        
        private lazy var bottomGradientView: FansGroup.Views.BottomGradientButton = {
            let v = FansGroup.Views.BottomGradientButton()
            v.button.setTitle(R.string.localizable.profileDone(), for: .normal)
            v.button.isEnabled = false
            v.button.addTarget(self, action: #selector(onDoneBtn), for: .primaryActionTriggered)
            return v
        }()
        
        private var screenshot: UIImage? = nil {
            didSet {
                bottomGradientView.button.isEnabled = (screenshot != nil)
            }
        }
        
        var gameUpdatedHandler: (() -> Void)? = nil
        
        private var imageGalleryItems = [GalleryItem]()
        
        private let game: Social.ChooseGame.GameViewModel
        
        init(_ game: Social.ChooseGame.GameViewModel) {
            self.game = game
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
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
        guard let image = screenshot else {
            return
        }
        
        let hudRemoval: (() -> Void)? = view.raft.show(.loading, userInteractionEnabled: false)
        
        uploadImage(image: image)
            .flatMap({ Request.setGameSkill(game: self.game.skill, screenshotUrl: $0.0) })
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe( onSuccess: { [weak self] (_) in
                self?.navigationController?.popToRootViewController(animated: true)
                self?.gameUpdatedHandler?()
                Logger.Action.log(.gameskill_add_state_done, categoryValue: self?.game.skill.topicId, nil, 0)
            }, onError: { [weak self] (error) in
                Logger.Action.log(.gameskill_add_state_done, categoryValue: self?.game.skill.topicId, nil, 1)
                self?.view.raft.autoShow(.text(error.localizedDescription))
            })
            .disposed(by: bag)
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
        
        var hEdgePadding: CGFloat = 0
        
        adaptToIPad {
            hEdgePadding = 20
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }
        
        layoutScrollView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(hEdgePadding)
            maker.bottom.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
        layoutScrollView.addSubviews(views: uploadView, exampleView)
        
        uploadView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(view).inset(hEdgePadding)
            maker.top.equalTo(26)
        }
        
        exampleView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(view).inset(hEdgePadding)
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
        
        return compressImage(image: image)
            .flatMap ({
                Request.uploadPng(image: $0)
            })
            .map { ($0, image) }
    }
    
    private func compressImage(image: UIImage) -> Single<UIImage> {
        
        return Single.create { (subscriber) -> Disposable in
            
            DispatchQueue.global().async {
                
                var croppedImg: UIImage = image
                
                while (croppedImg.pngData()?.count ?? 0)  > 256 * 1024 {
                    
                    guard let newImage = croppedImg.scaled(toWidth: croppedImg.size.width * 0.9) else {
                        break
                    }
                    
                    croppedImg = newImage
                    
                }
                
                subscriber(.success(croppedImg))
            }
            
            return Disposables.create()
        }
        
    }
    
    private func showImageViewer(_ image: UIImage?) {
        
        guard let image = image else { return }
        
        imageGalleryItems = [GalleryItem.image(fetchImageBlock: { (callback) in
            callback(image)
        })]
        
        let closeBtn = UIButton(type: .custom)
        closeBtn.setImage(R.image.ac_profile_close(), for: .normal)
        closeBtn.frame = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        
        let galleryViewController = GalleryViewController(startIndex: 0,
                                                          itemsDataSource: self,
                                                          configuration: [.deleteButtonMode(.none),
                                                                          .thumbnailsButtonMode(.none),
                                                                          .closeButtonMode(.custom(closeBtn)),
                                                                          .closeLayout(.pinRight(20 + Frame.Height.safeAeraTopHeight, 20))])
        
        self.presentImageGallery(galleryViewController)

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

extension Social.AddStatsViewController: GalleryItemsDataSource {
    
    func itemCount() -> Int {
        return imageGalleryItems.count
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        return imageGalleryItems[index]
    }
}
