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
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()

        private lazy var nextButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = UIColor(hexString: "#FFF000")
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
            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = GradientView()
            let l = v.layer
            l.colors = [UIColor(hex6: 0x191919, alpha: 0).cgColor, UIColor(hex6: 0x1D1D1D, alpha: 0.18).cgColor, UIColor(hex6: 0x232323, alpha: 0.57).cgColor, UIColor(hex6: 0x121212).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0)
            l.endPoint = CGPoint(x: 0.5, y: 1)
            l.locations = [0, 0.25, 0.5, 0.75, 1]
            v.addSubviews(views: nextButton)
            nextButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(40)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            return v
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
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
        let addStatsVC = Social.AddStatsViewController()
        navigationController?.pushViewController(addStatsVC, animated: true)
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
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(134)
        }

    }
    
}

extension Social.ChooseGame.ViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(GameCell.self), for: indexPath) as! GameCell
        return cell
    }
    
}
