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
            let i = UIImageView()
            return i
        }()
        
        private lazy var skinIV: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        private lazy var hatIV: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        private lazy var petIV: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: profileBgIV, skinIV, hatIV, petIV)
            
            profileBgIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            skinIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            hatIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            petIV.snp.makeConstraints { (maker) in
                maker.trailing.bottom.equalToSuperview()
            }
            
        }
        
        func updateLook(_ decoration: DecorationViewModel) {
            
            switch decoration.decorationType {
            case .bg:
                
                profileBgIV.setImage(with: decoration.selected ? decoration.lookUrl : nil)
                
            case .skin:
                
                skinIV.setImage(with: decoration.selected ? decoration.lookUrl : nil)

            case .hat:
                
                hatIV.setImage(with: decoration.selected ? decoration.lookUrl : nil)

            case .pet:
                ()
            }
            
        }
        
    }
    
}

extension Social.ProfileLookViewController {
    
    class SegmentedButton: UIView {
        
    }
    
}

extension Social.ProfileLookViewController {
    
    class DecorationCategoryView: UIView {
        
        private let bag = DisposeBag()
        
        private lazy var decorationCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let interSpace: CGFloat = 20
            let hwRatio: CGFloat = viewModel.decorationType == .pet ? (196.0 / 157.5) : 1
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - interSpace) / 2
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
            
            contentView.addSubviews(views: decorationIV, svgaView, selectedIcon, adBadge, statusLabel)
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview()
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
            
            adBadge.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview()
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
        }
        
        private func configSubviews(_ decoration: DecorationViewModel) {
            switch decoration.decorationType {
            case .skin, .hat, .bg:
                decorationIV.setImage(with: decoration.thumbUrl)
                selectedIcon.isHidden = decoration.locked
                adBadge.isHidden = !decoration.locked
                
            case .pet:
                selectedIcon.isHidden = decoration.locked
                playSvga(decoration.thumbUrl?.url)
                
                if decoration.locked {
                    statusLabel.text = ""
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
                
            }
            
            switch decoration.decoration.unlockType {
            case .rewarded:
                adBadge.image = R.image.ac_avatar_ad()
            case .premium:
                adBadge.image = R.image.ac_avatar_pro()
            default:
                adBadge.image = nil
            }
            
            selectedIcon.image = decoration.selected ? R.image.ac_avatar_selected() : R.image.ac_avatar_unselected()
            
        }
        
        private func setupSubviewsLayout(_ decoration: DecorationViewModel) {
            
            switch decoration.decorationType {
            case .skin, .hat:
                decorationIV.snp.remakeConstraints { (maker) in
                    maker.center.equalToSuperview()
                    maker.width.equalTo(decorationIV.snp.height)
                    maker.leading.equalToSuperview().inset(19.scalValue.rounded())
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
                
                statusLabel.layer.cornerRadius = 20
                statusLabel.layer.masksToBounds = true
            }
            
        }
        
        private func playSvga(_ resource: URL?) {
            svgaView.stopAnimation()
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
        
        func bindViewModel(_ viewModel: DecorationViewModel) {
            
            setupSubviewsLayout(viewModel)
            configSubviews(viewModel)
            
        }
    }
}
