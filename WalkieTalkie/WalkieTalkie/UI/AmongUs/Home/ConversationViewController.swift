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
    func configureSubview() {
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
