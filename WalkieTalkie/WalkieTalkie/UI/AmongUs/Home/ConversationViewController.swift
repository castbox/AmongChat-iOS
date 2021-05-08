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

class ConversationViewModel {
    private var conversation: Entity.DMConversation
    
    private var dataSource: [Entity.DMMessage] = []
    
    let dataSourceReplay = BehaviorRelay<[Entity.DMMessage]>(value: [])
    
    private let bag = DisposeBag()
    
    init(_ conversation: Entity.DMConversation) {
        self.conversation = conversation
        let uid = conversation.fromUid
        
        DMManager.shared.observableMessages(for: uid)
            .startWith(())
            .flatMap { item -> Single<[Entity.DMMessage]> in
                return DMManager.shared.messages(for: uid)
            }
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: dataSourceReplay)
            .disposed(by: bag)
    }
}

class ConversationViewController: ViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    private var conversation: Entity.DMConversation
    private let viewModel: ConversationViewModel
    private var dataSource: [Entity.DMMessage] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    
    init(_ conversation: Entity.DMConversation) {
        self.conversation = conversation
        self.viewModel = ConversationViewModel(conversation)
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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

        guard let notice = dataSource.safe(indexPath.item) else {
            return .zero
        }

        return CGSize(width: Frame.Screen.width, height: 100)
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
        titleLabel.text = conversation.message.fromUser.name
        collectionView.register(nibWithCellClass: ConversationCollectionCell.self)
    }
    
    func bindSubviewEvent() {
        viewModel.dataSourceReplay
            .subscribe(onNext: { [weak self] source in
                self?.dataSource = source
            })
            .disposed(by: bag)
    }
}
