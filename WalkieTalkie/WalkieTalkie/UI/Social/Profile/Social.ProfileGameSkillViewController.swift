//
//  Social.ProfileGameSkillViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/2.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SDCAlertView
import JXPagingView

extension Social {
    
    class ProfileGameSkillViewController: WalkieTalkie.ViewController {
        
        private var listViewDidScrollCallback: ((UIScrollView) -> ())?
        
        private typealias SectionHeader = Social.ProfileViewController.SectionHeader
        private typealias ProfileTableCell = Social.ProfileViewController.ProfileTableCell
        private lazy var table: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            adaptToIPad {
                hInset = 40
            }
            layout.sectionInset = UIEdgeInsets(top: 16, left: 0, bottom: 56, right: 0)
            layout.minimumLineSpacing = 20
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.contentInset = UIEdgeInsets(top: 24, left: hInset, bottom: 0, right: hInset)
            v.register(cellWithClazz: GameCell.self)
            v.register(cellWithClazz: ProfileTableCell.self)
            v.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: SectionHeader.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            if #available(iOS 11.0, *) {
                v.contentInsetAdjustmentBehavior = .never
            } else {
                automaticallyAdjustsScrollViewInsets = false
            }
            return v
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.profileGameStatsEmpty()
            v.isHidden = true
            return v
        }()
        
        private var gameSkills = [Entity.UserGameSkill]() {
            didSet {
                table.reloadData()
                if !uid.isSelfUid {
                    emptyView.isHidden = (gameSkills.count > 0)
                }
            }
        }
        
        private let uid: Int
        
        init(with uid: Int) {
            self.uid = uid
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            loadGameSkills()
        }
        
    }
    
}

extension Social.ProfileGameSkillViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: emptyView, table)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(24)
        }
        
        table.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    private func loadGameSkills() {
        let hudRemoval = view.raft.show(.loading)
        Request.gameSkills(uid: uid)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (skills) in
                self?.gameSkills = skills
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
        
    }
    
    private func toAddAGame() {
        Logger.Action.log(.profile_add_game_clk)
        let chooseGameVC = Social.ChooseGame.ViewController()
        chooseGameVC.gameUpdatedHandler = { [weak self] in
            self?.loadGameSkills()
        }
        navigationController?.pushViewController(chooseGameVC, animated: true)
    }
    
    private func toRemoveGameSkill(_ game: Entity.UserGameSkill, completionHandler: @escaping (() -> Void)) {
        Logger.Action.log(.profile_game_state_item_delete_clk, categoryValue: game.topicId)
        
        let messageAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.amongChatGameStatsDeleteTip(),
                                                                 attributes: [
                                                                    NSAttributedString.Key.font : R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: UIColor.white
                                                                 ])
        
        let cancelAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.toastCancel(),
                                                                attributes: [
                                                                    NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: "#6C6C6C".color()
                                                                ])
        
        let confirmAttr = NSAttributedString(string: R.string.localizable.amongChatDelete(),
                                             attributes: [
                                                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                .foregroundColor: "#FB5858".color()
                                             ])
        
        let alertVC = AlertController(attributedTitle: nil, attributedMessage: messageAttr, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        alertVC.addAction(AlertAction(attributedTitle: cancelAttr, style: .normal))
        
        alertVC.addAction(AlertAction(attributedTitle: confirmAttr, style: .normal, handler: { [weak self] _ in
            guard let `self` = self else { return }
            
            let hudRemoval: (() -> Void)? = self.view.raft.show(.loading, userInteractionEnabled: false)
            
            Request.removeGameSkill(game: game)
                .do(onDispose: {
                    hudRemoval?()
                })
                .subscribe(onSuccess: { (_) in
                    completionHandler()
                }, onError: { (error) in
                    
                })
                .disposed(by: self.bag)
        })
        )
        
        alertVC.view.backgroundColor = UIColor.black.alpha(0.6)
        alertVC.present()
        
    }
    
}

// MARK: - UICollectionViewDataSource
extension Social.ProfileGameSkillViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if uid.isSelfUid {
            return max(1, gameSkills.count)
        } else {
            return gameSkills.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let game = gameSkills.safe(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withClazz: GameCell.self, for: indexPath)
            cell.bind(game)
            cell.deleteButton.isHidden = !uid.isSelfUid
            cell.deleteHandler = { [weak self] in
                self?.toRemoveGameSkill(game, completionHandler: {
                    self?.loadGameSkills()
                })
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClazz: ProfileTableCell.self, for: indexPath)
            cell.leftIconIV.image = R.image.ac_profile_game()
            cell.titleLabel.text = R.string.localizable.amongChatProfileAddAGame()
            return cell
        }
        
    }
    
}

// MARK: - UICollectionViewDelegate

extension Social.ProfileGameSkillViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let game = gameSkills.safe(indexPath.row) {
            WebViewController.pushFrom(self, url: game.h5.url, contentType: .gameSkill(game))
            Logger.Action.log(uid.isSelfUid ? .profile_game_state_item_clk : .profile_other_game_state_item_clk, categoryValue: game.topicId)
            
        } else {
            toAddAGame()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SectionHeader.self, for: indexPath)
            
            if uid.isSelfUid {
                
                header.titleLabel.text = R.string.localizable.amongChatProfileMyGameStats()
                
                header.actionButton.setImage(R.image.ac_profile_add_game_stats(), for: .normal)
                header.actionButton.setTitle(R.string.localizable.amongChatProfileAddAGame(), for: .normal)
                header.actionButton.setTitleColor(UIColor(hex6: 0xFFFFFF), for: .normal)
                header.actionButton.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                header.actionButton.setImageTitleHorizontalSpace(8)
                header.actionHandler = { [weak self] () in
                    self?.toAddAGame()
                }
                
                header.actionButton.isHidden = !(gameSkills.count > 0)
                
            } else {
                
                header.actionButton.isHidden = true
                
                if gameSkills.count > 0 {
                    header.titleLabel.text = R.string.localizable.amongChatProfileGameStats()
                }
                
            }
            
            
            return header
            
        default:
            return UICollectionReusableView()
        }
        
    }
    
}

extension Social.ProfileGameSkillViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = collectionView.contentInset.left + collectionView.contentInset.right
        
        if let _ = gameSkills.safe(indexPath.row) {
            
            let interitemSpacing: CGFloat = 20
            var hwRatio: CGFloat = 180.0 / 335.0
            var columns: Int = 1
            adaptToIPad {
                columns = 2
                hwRatio = 227.0 / 367.0
            }
            let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            
            return CGSize(width: cellWidth, height: cellHeight)
            
        } else {
            return CGSize(width: Frame.Screen.width - padding, height: 68)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if gameSkills.count > 0 || uid.isSelfUid {
            return CGSize(width: Frame.Screen.width, height: 27)
        } else {
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}

extension Social.ProfileGameSkillViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        listViewDidScrollCallback?(scrollView)
    }
    
}

extension Social.ProfileGameSkillViewController: JXPagingViewListViewDelegate {
    
    func listView() -> UIView {
        return view
    }

    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        listViewDidScrollCallback = callback
    }

    func listScrollView() -> UIScrollView {
        return table
    }
    
}
