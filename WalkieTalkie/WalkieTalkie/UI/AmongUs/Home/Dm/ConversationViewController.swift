//
//  ConversationViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ConversationViewController: ViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var followButton: UIButton!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    private lazy var bottomBar = ConversationBottomBar()
    
    private var conversation: Entity.DMConversation
    private let viewModel: Conversation.ViewModel
    
    private var dataSource: [Conversation.MessageCellViewModel] = [] {
        didSet {
            collectionView.reloadData()
            //calculate height
        }
    }

    init(_ conversation: Entity.DMConversation) {
        self.conversation = conversation
        self.viewModel = Conversation.ViewModel(conversation)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
    }


    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController()
    }
    
    @IBAction func moreButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func followButtonAction(_ sender: Any) {
        
    }
}


extension ConversationViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = dataSource.safe(indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let cell = collectionView.dequeueReusableCell(withClass: ConversationCollectionCell.self, for: indexPath)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        cell.bind(item)
//        cell.bind(item)
//        switch notice.notice.message.messageType {
//        case .TxtMsg, .ImgMsg, .ImgTxtMsg, .TxtImgMsg:
//            cell = collectionView.dequeueReusableCell(withClass: ConversationListCell.self, for: indexPath)
//            if let cell = cell as? ConversationListCell {
////                cell.bindNoticeData(notice)
//            }

//        case .SocialMsg:
//            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SocialMessageCell.self), for: indexPath)
//
//            if let cell = cell as? SocialMessageCell {
//                cell.bindNoticeData(notice)
//            }
//
//        }
        
        return cell
    }
}

extension ConversationViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let viewModel = dataSource.safe(indexPath.item) else {
            return .zero
        }

        return CGSize(width: Frame.Screen.width, height: viewModel.height)
    }
    
}

extension ConversationViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.safe(indexPath.item) else {
            return
        }
//        let vc = ConversationViewController(item)
//        navigationController?.pushViewController(vc)
    }
    
}


extension ConversationViewController {
    func reloadCollectionView() {
        let contentHeight = self.collectionView.contentSize.height
        let height = self.collectionView.bounds.size.height
        let contentOffsetY = self.collectionView.contentOffset.y
        let bottomOffset = contentHeight - contentOffsetY
        //            self.newMessageButton.isHidden = true
        // 消息不足一屏
        if contentHeight < height {
            self.collectionView.reloadData()
            //获取高度，更新 collectionview height
        } else {// 超过一屏
            if floor(bottomOffset) - floor(height) < 40 {// 已经在底部
                let rows = self.collectionView.numberOfItems(inSection: 0)
                let newRow = self.dataSource.count
                guard newRow > rows else { return }
                let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                collectionView.performBatchUpdates {
                    collectionView.insertItems(at: indexPaths)
                } completion: { result in
                    
                }

//                self.collectionView.beginUpdates()
//                self.collectionView.insertRows(at: indexPaths, with: .none)
//                self.collectionView.endUpdates()
                if let endPath = indexPaths.last {
                    collectionView.scrollToItem(at: endPath, at: .bottom, animated: true)
                }
            } else {
                //                    if self.collectionView.numberOfRows(inSection: 0) <= 2 {
                //                        self.newMessageButton.isHidden = true
                //                    } else {
                //                        self.newMessageButton.isHidden = false
                //                    }
                self.collectionView.reloadData()
            }
        }
    }
    
    func configureSubview() {
        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)

        view.addSubviews(views: bottomBar)
        
        bottomBar.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(Frame.Height.safeAeraBottomHeight + 60)
        }
        
        titleLabel.text = conversation.message.fromUser.name
        collectionView.register(nibWithCellClass: ConversationCollectionCell.self)
    }
    
    func bindSubviewEvent() {
        viewModel.dataSourceReplay
            .subscribe(onNext: { [weak self] source in
                self?.dataSource = source
            })
            .disposed(by: bag)
        
        bottomBar.actionHandler = { [weak self] action in
            switch action {
            case .gif:
                ()
            case .send(let text):
                ()
            }
        }
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                self.bottomBar.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                }
                self.collectionViewBottomConstraint.constant = 60 + keyboardVisibleHeight
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: bag)

    }
}
