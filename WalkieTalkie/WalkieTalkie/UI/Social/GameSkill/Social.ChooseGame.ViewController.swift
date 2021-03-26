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
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = UIColor.white
            lb.text = R.string.localizable.amongChatChooseGame()
            return lb
        }()
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var gameCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let vInset: CGFloat = 24
            let hwRatio: CGFloat = 128.0 / 128.0
            let interSpace: CGFloat = 20
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - interSpace ) / 2
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
        
        typealias GameViewModel = Social.ChooseGame.GameViewModel
        private lazy var gameDataSource: [GameViewModel] = [Entity.GameSkill]()
            .map { GameViewModel(with: $0) } {
            didSet {
                gameCollectionView.reloadData()
            }
        }
        
        private var selectedGame: GameViewModel? = nil {
            didSet {
                nextButton.isEnabled = (selectedGame != nil)
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
        view.addSubviews(views: backBtn, titleLabel, gameCollectionView, bottomGradientView)
        
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
        
        gameCollectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
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
