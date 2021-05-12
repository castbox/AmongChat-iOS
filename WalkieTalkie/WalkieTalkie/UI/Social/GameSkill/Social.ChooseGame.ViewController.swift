//
//  Social.ChooseGame.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/23.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social {
    struct ChooseGame {
        
    }
}

extension Social.ChooseGame {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private typealias GameCell = Social.ChooseGame.GameCell
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let lb = n.titleLabel
            lb.text = R.string.localizable.amongChatChooseGame()
            let btn = n.leftBtn
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            return n
        }()
        
        private lazy var gameCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            let vInset: CGFloat = 24
            let hwRatio: CGFloat = 128.0 / 128.0
            let interSpace: CGFloat = 20
            var columns: Int = 2
            adaptToIPad {
                hInset = 40
                columns = 4
            }
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interSpace * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = cellWidth * hwRatio
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = interSpace
            layout.sectionInset = UIEdgeInsets(top: vInset, left: hInset, bottom: 134 + vInset, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(GameCell.self, forCellWithReuseIdentifier: NSStringFromClass(GameCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private lazy var bottomGradientView: FansGroup.Views.BottomGradientButton = {
            let v = FansGroup.Views.BottomGradientButton()
            v.button.setTitle(R.string.localizable.amongChatLoginNext(), for: .normal)
            v.button.addTarget(self, action: #selector(onNextBtn), for: .primaryActionTriggered)
            v.button.isEnabled = false
            return v
        }()
        
        typealias GameViewModel = Social.ChooseGame.GameViewModel
        private lazy var gameDataSource: [GameViewModel] = [Entity.GameSkill]()
            .map { GameViewModel(with: $0) } {
            didSet {
                gameCollectionView.reloadData()
            }
        }
        
        private var selectedGame: GameViewModel? = nil {
            didSet {
                bottomGradientView.button.isEnabled = (selectedGame != nil)
            }
        }
        
        var gameUpdatedHandler: (() -> Void)? = nil

        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            fetchData()
        }
        
    }
    
}

extension Social.ChooseGame.ViewController {
    
    // MARK: - UI action
    
    @objc
    private func onBackBtn() {
        navigationController?.popViewController()
    }
        
    @objc
    private func onNextBtn() {
        
        guard let game = selectedGame else {
            return
        }
        Logger.Action.log(.gameskill_choose_game_next_clk, categoryValue: game.skill.topicId)
        
        let addStatsVC = Social.AddStatsViewController(game)
        navigationController?.pushViewController(addStatsVC, animated: true)
        addStatsVC.gameUpdatedHandler = { [weak self] in
            self?.gameUpdatedHandler?()
            self?.fetchData()
        }
    }
}

extension Social.ChooseGame.ViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: navView, gameCollectionView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        gameCollectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(navView.snp.bottom)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
        }
        
    }
    
    private func fetchData() {
        
        let hudRemoval: (() -> Void)? = view.raft.show(.loading, userInteractionEnabled: false)
        
        Request.presetGameSkills()
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (skills) in
                self?.gameDataSource = skills.map({ GameViewModel(with: $0) })
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.localizedDescription))
            })
            .disposed(by: bag)
    }
    
}

extension Social.ChooseGame.ViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView Data Source

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(GameCell.self), for: indexPath) as! GameCell
        if let game = gameDataSource.safe(indexPath.item) {
            cell.bindViewModel(game)
        }
        return cell
    }
    
}

extension Social.ChooseGame.ViewController: UICollectionViewDelegate {
    
    // MARK: - UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let game = gameDataSource.safe(indexPath.item) else {
            return false
        }
        
        return !game.skill.isAdd
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedGame = gameDataSource.safe(indexPath.item)
    }
}
