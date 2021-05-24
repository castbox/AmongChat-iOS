//
//  Social.ProfileLookViewController+Widgets.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/2/2.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SVGAPlayer
import RxSwift
import RxCocoa

extension Social.ProfileLookViewController {
    
    class ProfileLookView: UIView {
        
        private lazy var profileBgIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_profile_look_bg_defalut())
            i.contentMode = .scaleAspectFill
            i.clipsToBounds = true
            return i
        }()
        
        private lazy var skinShadowIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_profile_look_shadow())
            return i
        }()
        
        private lazy var skinIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_profile_look_skin_default())
            return i
        }()
        
        private lazy var hatIV: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        private lazy var petShadowIV: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        private lazy var svgaView: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        enum Style {
            case header
            case cell
        }
        
        private let style: Style
        
        init(_ style: Style = .header) {
            self.style = style
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            switch style {
            case .header:
                addSubviews(views: profileBgIV, skinShadowIV, skinIV, hatIV, petShadowIV, svgaView)
                
                profileBgIV.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                
                skinShadowIV.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(skinIV)
                }
                
                skinIV.snp.makeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.width.height.equalTo(210.scalValue)
                    maker.centerY.equalToSuperview().multipliedBy(1.2)
                }
                
                adaptToIPad {
                    skinIV.snp.remakeConstraints { (maker) in
                        maker.centerX.equalToSuperview()
                        maker.width.height.equalTo(210)
                        maker.centerY.equalToSuperview().multipliedBy(1.2)
                    }
                }
                
                hatIV.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(skinIV)
                }
                
                petShadowIV.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(svgaView)
                }
                
                svgaView.snp.makeConstraints { (maker) in
                    maker.width.height.equalTo(70)
                    maker.trailing.equalTo(skinIV.snp.trailing).offset(28)
                    maker.bottom.equalTo(skinIV.snp.bottom).offset(-17)
                }
                
            case .cell:
                
                addSubviews(views: profileBgIV, skinIV, hatIV)
                
                profileBgIV.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                
                skinIV.snp.makeConstraints { (maker) in
                    maker.center.equalToSuperview()
                    maker.width.height.equalTo(120)
                }
                
                hatIV.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(skinIV)
                }
                
            }
            
        }
        
        private func playSvga(_ resource: URL?) {
            svgaView.stopAnimation()
            svgaView.clear()
            guard let resource = resource else {
                return
            }
            
            let parser = SVGAGlobalParser.defaut
            parser.parse(with: resource,
                         completionBlock: { [weak self] (item) in
                            self?.svgaView.videoItem = item
                            self?.svgaView.startAnimation()
                         },
                         failureBlock: { error in
                            debugPrint("error: \(error?.localizedDescription ?? "")")
                         })
        }
        
        func updateLook(_ decoration: DecorationViewModel) {
            
            switch decoration.decorationType {
            case .bg:
                
                profileBgIV.setImage(with: decoration.selected ? decoration.lookUrl : nil, placeholder: R.image.ac_profile_look_bg_defalut())
                
            case .skin:
                
                skinIV.setImage(with: decoration.selected ? decoration.lookUrl : nil, placeholder: R.image.ac_profile_look_skin_default())

            case .hat:
                
                hatIV.setImage(with: decoration.selected ? decoration.lookUrl : nil)

            case .pet:
                
                petShadowIV.isHidden = !decoration.selected
                playSvga(decoration.selected ? decoration.lookUrl?.url : nil)
                
            case .suit:
                decoration.suit.forEach({ (deco) in
                    guard deco.decorationType != .suit else { return }
                    updateLook(deco)
                })
            }
            
        }
        
        func saveLookAsAvatar() -> UIImage? {
                        
            let innerContainerSize = CGSize(width: 210, height: 210)
            let containerSize = CGSize(width: 140, height: 140)
            
            let innerContainer = UIView(frame: CGRect(origin: .zero, size: innerContainerSize))
            
            let bgView = UIImageView(image: profileBgIV.image)
            bgView.contentMode = .scaleAspectFill
            
            let skinView = UIImageView(image: skinIV.image)
            
            let hatView = UIImageView(image: hatIV.image)
            
            innerContainer.addSubviews(views: bgView, skinView, hatView)
            bgView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.size.equalTo(innerContainerSize)
            }
            
            skinView.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview().offset(5)
                maker.size.equalTo(innerContainerSize)
                maker.top.equalTo(12)
            }
            
            hatView.snp.makeConstraints { (maker) in
                maker.edges.equalTo(skinView)
            }
            
            let container = UIView(frame: CGRect(origin: .zero, size: containerSize))
            container.addSubview(innerContainer)
            innerContainer.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
            }
            
            container.layoutIfNeeded()
            
            return container.screenshot
        }
        
    }
    
}

extension Social.ProfileLookViewController {
    
    class SegmentedButton: UIView {
        
        private let bag = DisposeBag()
        
        private lazy var scrollView: UIScrollView = {
            let s = UIScrollView()
            s.showsVerticalScrollIndicator = false
            s.showsHorizontalScrollIndicator = false
            s.bounces = false
            return s
        }()
        
        private lazy var scrollContentView: UIView = {
            let v = UIView()
            return v
        }()
        
        private lazy var indicatorContainer: UIView = {
            let v = UIView()
            return v
        }()
        
        private lazy var selectedIndicator: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0xFFF000)
            v.layer.cornerRadius = 2.5
            v.clipsToBounds = true
            return v
        }()
        
        private var buttons = [UIButton]()
        
        private var selectedBtn: UIButton? = nil
        
        private let selectedIndexrRelay = BehaviorRelay<Int>(value: 0)
        
        var selectedIndexObservable: Observable<Int> {
            return selectedIndexrRelay.asObservable().distinctUntilChanged()
        }
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            
            addSubviews(views: scrollView)
            scrollView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            scrollView.addSubview(scrollContentView)
            scrollContentView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
                maker.height.equalTo(self)
            }
            
            indicatorContainer.addSubview(selectedIndicator)
            
            scrollContentView.addSubview(indicatorContainer)
            
            indicatorContainer.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.centerY.equalToSuperview().offset(19)
            }

        }
        
        func setTitles(titles: [String]) {
            
            buttons.forEach({ (btn) in
                btn.removeFromSuperview()
            })
            
            buttons = titles.enumerated().map { (idx, title) -> UIButton in
                let btn = UIButton(type: .custom)
                btn.setTitleColor(UIColor(hex6: 0x595959), for: .normal)
                btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .selected)
                btn.titleLabel?.font = R.font.nunitoBold(size: 20)
                btn.setTitle(title, for: .normal)
                btn.rx.controlEvent(.primaryActionTriggered)
                    .subscribe(onNext: { [weak self] () in
                        self?.updateSelectedIndex(idx)
                    })
                    .disposed(by: bag)
                
                return btn
            }
            
            scrollContentView.addSubviews(buttons)
            
            for (idx, btn) in buttons.enumerated() {
                
                btn.snp.makeConstraints { (maker) in
                    maker.centerY.equalToSuperview().offset(-2)
                    if idx == 0 {
                        maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    } else if idx == buttons.count - 1 {
                        maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    }
                    
                    if idx > 0,
                       let pre = buttons.safe(idx - 1) {
                        maker.leading.equalTo(pre.snp.trailing).offset(36)
                    }
                    
                }
                
            }
            
            updateSelectedIndex(0)
        }
        
        func updateSelectedIndex(_ index: Int) {
            
            guard let button = buttons.safe(index) else {
                return
            }
            switch index {
            case 0:
                Logger.Action.log(.notice_tab_system_clk)
            case 1:
                Logger.Action.log(.notice_tab_social_clk)
            case 2:
                Logger.Action.log(.notice_tab_group_request_clk)
            default:
                ()
            }
            
            guard selectedBtn != button else { return }
                        
            selectedIndicator.snp.remakeConstraints { (maker) in
                maker.centerX.equalTo(button)
                maker.width.equalTo(24)
                maker.height.equalTo(5)
                maker.top.bottom.equalTo(indicatorContainer)
            }
                        
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let `self` = self else { return }
                button.isSelected = true
                let enlargeFractor: CGFloat = 1.2
                button.transform = CGAffineTransform(scaleX: enlargeFractor, y: enlargeFractor)
                if button == self.buttons.last {
                    button.snp.updateConstraints { (maker) in
                        maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth + ceil((enlargeFractor - 1) * button.frame.width) / 2)
                    }
                } else if button == self.buttons.first {
                    button.snp.updateConstraints { (maker) in
                        maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth + ceil((enlargeFractor - 1) * button.frame.width) / 2)
                    }
                }
                
                button.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                self.selectedBtn?.isSelected = false
                self.selectedBtn?.transform = .identity
                if self.selectedBtn == self.buttons.last {
                    self.selectedBtn?.snp.updateConstraints { (maker) in
                        maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    }
                } else if self.selectedBtn == self.buttons.first {
                    self.selectedBtn?.snp.updateConstraints { (maker) in
                        maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    }
                }

                self.selectedBtn?.titleLabel?.font = R.font.nunitoBold(size: 20)
                self.selectedBtn = button

                self.indicatorContainer.layoutIfNeeded()
                
            } completion: { [weak self] (_) in
                guard let `self` = self else { return }
                if button == self.buttons.first {
                    self.scrollView.scrollRectToVisible(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), animated: true)
                } else if button == self.buttons.last {
                    self.scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: self.scrollView.contentSize.width - 1, y: 0), size: CGSize(width: 1, height: 1)), animated: true)
                } else {
                    self.scrollView.scrollRectToVisible(button.frame, animated: true)
                }
            }
            
            selectedIndexrRelay.accept(index)
        }
        
        func buttonOf(_ index: Int) -> UIView? {
            return buttons.safe(index)
        }
    }
    
}

extension Social.ProfileLookViewController {
    
    class DecorationCategoryView: UIView {
        
        private let bag = DisposeBag()
        
        private lazy var decorationCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            let interSpace: CGFloat = 20
            let hwRatio: CGFloat = viewModel.decorationType == .pet ? (196.0 / 157.5) : 1
            var columns: Int = 2
            adaptToIPad {
                hInset = 40
                columns = 4
            }
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interSpace * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = (cellWidth * hwRatio).rounded()
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interSpace
            layout.minimumLineSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 12, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(DecorationCell.self, forCellWithReuseIdentifier: NSStringFromClass(DecorationCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private let viewModel: DecorationCategoryViewModel
        
        var onSelectDecoration: ((DecorationViewModel) -> Single<Bool>)? = nil
        
        init(viewModel: DecorationCategoryViewModel) {
            self.viewModel = viewModel
            super.init(frame: .zero)
            setupLayout()
            setupEvents()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubview(decorationCollectionView)
            decorationCollectionView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        private func setupEvents() {
            
            if viewModel.decorationType == .pet {
                IAP.consumableProductsObservable
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { [weak self] (productMap) in
                        
                        guard productMap.count > 0 else { return }
                        
                        self?.decorationCollectionView.reloadData()
                        
                    })
                    .disposed(by: bag)
            }
        }
    }
    
}

extension Social.ProfileLookViewController.DecorationCategoryView: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.decorations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(Social.ProfileLookViewController.DecorationCell.self), for: indexPath)
        if let cell = cell as? Social.ProfileLookViewController.DecorationCell,
           let decoration = viewModel.decorations.safe(indexPath.item) {
            cell.bindViewModel(decoration)
        }
        return cell
    }
}

extension Social.ProfileLookViewController.DecorationCategoryView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let decoration = viewModel.decorations.safe(indexPath.item) else {
            return
        }
        
        onSelectDecoration?(decoration)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] (needUpdateUI) in
                guard let `self` = self,
                      needUpdateUI else { return }
                
                for (idx, decoration) in self.viewModel.decorations.enumerated() {
                    
                    guard idx != indexPath.item else {
                        continue
                    }
                    
                    decoration.selected = false
                }
                
                self.decorationCollectionView.reloadData()
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
}

extension Social.ProfileLookViewController {
    
    class DecorationCell: UICollectionViewCell {
        
        private lazy var decorationIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            return iv
        }()
        
        private lazy var suitView: ProfileLookView = {
            let s = ProfileLookView(.cell)
            s.isHidden = true
            return s
        }()
        
        private lazy var selectedIcon: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.isHidden = true
            return iv
        }()
        
        private lazy var adBadge: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.isHidden = true
            return iv
        }()
        
        private lazy var svgaView: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        private lazy var svgaDisposable: Disposable? = nil
        
        private lazy var statusLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textAlignment = .center
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.backgroundColor = UIColor(hex6: 0x222222)
            contentView.layer.cornerRadius = 12
            contentView.clipsToBounds = true
            
            contentView.addSubviews(views: decorationIV, suitView, svgaView, selectedIcon, adBadge, statusLabel)
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview().inset(-0.5)
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
            
            adBadge.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview().inset(-0.5)
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
            
            suitView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        private func configSubviews(_ decoration: DecorationViewModel) {
            switch decoration.decorationType {
            case .skin, .hat, .bg:
                decorationIV.setImage(with: decoration.thumbUrl)
                
            case .pet:
                playSvga(decoration.thumbUrl?.url)
                
                if decoration.locked {
                    statusLabel.text = decoration.iapProduct?.skProduct.localizedPrice
                    statusLabel.textColor = .black
                    statusLabel.backgroundColor = UIColor(hex6: 0xFFF000)
                } else {
                    
                    if decoration.selected {
                        statusLabel.text = R.string.localizable.amongChatProfileRemove()
                        statusLabel.textColor = .white
                        statusLabel.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.2)
                    } else {
                        statusLabel.text = R.string.localizable.amongChatProfileEquip()
                        statusLabel.textColor = .black
                        statusLabel.backgroundColor = UIColor(hex6: 0xFFF000)
                    }
                    
                }
                
            case .suit:
                suitView.updateLook(decoration)
            }
            
            selectedIcon.isHidden = decoration.locked
            selectedIcon.image = decoration.selected ? R.image.ac_avatar_selected() : R.image.ac_avatar_unselected()
            adBadge.isHidden = !decoration.locked
            
            switch decoration.decoration.unlockType {
            case .rewarded:
                adBadge.image = R.image.ac_avatar_ad()
            case .premium:
                adBadge.image = R.image.ac_avatar_pro()
                adBadge.isHidden = decoration.selected
            default:
                adBadge.image = nil
            }
            
        }
        
        private func setupSubviewsLayout(_ decoration: DecorationViewModel) {
            
            switch decoration.decorationType {
            case .skin, .hat:
                decorationIV.snp.remakeConstraints { (maker) in
                    maker.center.equalToSuperview()
                    maker.width.equalTo(decorationIV.snp.height)
                    maker.leading.equalToSuperview().inset(19.scalValue.rounded())
                }
                
                adaptToIPad {
                    decorationIV.snp.remakeConstraints { (maker) in
                        maker.center.equalToSuperview()
                        maker.width.height.equalTo(120)
                    }
                }
                
            case .bg:
                decorationIV.snp.remakeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                
            case .pet:
                
                svgaView.snp.remakeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.width.equalTo(svgaView.snp.height)
                    maker.leading.equalToSuperview().inset(39.scalValue.rounded())
                    maker.centerY.equalToSuperview().multipliedBy(0.8)
                }
                
                statusLabel.snp.makeConstraints { (maker) in
                    maker.leading.trailing.equalToSuperview().inset(20.scalValue.rounded())
                    maker.height.equalTo(40)
                    maker.bottom.equalToSuperview().inset(20.scalValue.rounded())
                }
                
                adaptToIPad {
                    svgaView.snp.remakeConstraints { (maker) in
                        maker.centerX.equalToSuperview()
                        maker.width.equalTo(svgaView.snp.height)
                        maker.leading.equalToSuperview().inset(39)
                        maker.centerY.equalToSuperview().multipliedBy(0.8)
                    }
                    
                    statusLabel.snp.remakeConstraints { (maker) in
                        maker.leading.trailing.equalToSuperview().inset(20)
                        maker.height.equalTo(40)
                        maker.bottom.equalToSuperview().inset(20)
                    }
                }
                
                statusLabel.layer.cornerRadius = 20
                statusLabel.layer.masksToBounds = true
                
            case .suit:
                suitView.isHidden = false
            }
            
        }
        
        private func playSvga(_ resource: URL?) {
            
            svgaDisposable?.dispose()
            svgaDisposable = nil
            
            svgaView.stopAnimation()
            svgaView.clear()
            
            guard let resource = resource else {
                return
            }
            
            svgaDisposable = Single<SVGAVideoEntity>.create(subscribe: { (subscriber) -> Disposable in
                
                let parser = SVGAGlobalParser.defaut
                parser.parse(with: resource,
                             completionBlock: { (item) in
                                guard let item = item else {
                                    subscriber(.error(MsgError.default))
                                    return
                                }
                                subscriber(.success(item))
                             },
                             failureBlock: { error in
                                debugPrint("error: \(error?.localizedDescription ?? "")")
                                subscriber(.error(error ?? MsgError.default))
                             })
                
                return Disposables.create()
            })
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] (item) in
                self?.svgaView.videoItem = item
                self?.svgaView.startAnimation()
            }, onError: { (error) in
                debugPrint("error: \(error.localizedDescription)")
            })
        }
        
        func bindViewModel(_ viewModel: DecorationViewModel) {
            
            setupSubviewsLayout(viewModel)
            configSubviews(viewModel)
            
        }
    }
}
