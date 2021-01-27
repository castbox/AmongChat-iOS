//
//  Social.ContactListViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults

extension Social {
    class ContactListViewController: WalkieTalkie.ViewController {
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.navigationController?.popViewController()
                }).disposed(by: bag)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.text = R.string.localizable.contactSearchTitle()
            lb.textColor = .white
            lb.appendKern()
            return lb
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.ContactCell.self)
            tb.register(cellWithClass: Social.EnableContactsCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var headerView = SearchHeaderView()
        private lazy var viewModel = ContactsViewModel()
        
        private var items: [InviteFirendsViewModel.Item] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        private var hiddened = false
        private let linkUrl = R.string.localizable.shareAppContent()
        
//        init() {
//            super.init(nibName: nil, bundle: nil)
//        }
        
//        required init?(coder aDecoder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
//            ShareRoomViewModel.roomShareItems = items
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            view.addSubviews(views: backBtn, titleLabel)
            
            let navLayoutGuide = UILayoutGuide()
            view.addLayoutGuide(navLayoutGuide)
            navLayoutGuide.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(48)
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            backBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(navLayoutGuide)
                maker.leading.equalToSuperview().offset(20)
                maker.width.height.equalTo(25)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(navLayoutGuide)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.top.equalTo(navLayoutGuide.snp.bottom)
                maker.left.right.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            headerView.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 86)
            tableView.tableHeaderView = headerView
            headerView.inputResultHandler = { [weak self] key in
                guard let `self` = self else { return }
                self.viewModel.search(name: key)
//                self.shareApp()
//                self.updateEventForContactAuthorizationStatus()
            }
        }
    }
}
private extension Social.ContactListViewController {
    
    func loadData() {
        let offset = (Frame.Screen.height - view.height) / 2
        let removeBlock = view.raft.show(.loading, userInteractionEnabled: false, offset: CGPoint(x: 0, y: -offset))
        viewModel.dataSourceReplay
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self](data) in
                removeBlock()
                self?.items = data
            }, onError: { (error) in
                removeBlock()
                cdPrint("inviteFriends error: \(error.localizedDescription)")
            })
            .disposed(by: bag)
        
        viewModel.fetchContacts()
    }
    
    func copyLink() {
//        Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "copy")
        linkUrl.copyToPasteboardWithHaptic()
        view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false, backColor: UIColor(hex6: 0x181818))
    }
    
    func shareApp() {
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }

        self.view.isUserInteractionEnabled = false
        ShareManager.default.showActivity(viewController: self) { () in
            removeBlock()
        }
    }
}

// MARK: - UITableView
extension Social.ContactListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let item = items.safe(section) else {
            return 0
        }
        if item.group == .find {
            return 1
        }
        return item.userLsit.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: Social.ContactCell.self)
        if let item = items.safe(indexPath.section), let user = item.userLsit.safe(indexPath.row) {
                cell.bind(viewModel: user) { [weak self] in
                    guard let `self` = self else { return }
                    self.sendSMS(to: user.phone, body: self.linkUrl)
                }
            }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 69
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let user = items.safe(indexPath.section)?.userLsit.safe(indexPath.row) {
//            Logger.Action.log(.room_share_item_clk, category: Logger.Action.Category(rawValue: topicId), "profile")
//            let vc = Social.ProfileViewController(with: user.uid)
//            self.navigationController?.pushViewController(vc)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
}

extension Social.ContactListViewController {
    
    class SearchHeaderView: UIView {
        private lazy var textField: UITextField = {
            let f = PaddingTextField(frame: CGRect.zero)
            f.backgroundColor = UIColor("#222222")
            f.borderStyle = .none
            f.paddingLeft = 44
            f.paddingRight = 12
            let leftMargin = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
            let imageView = UIImageView(image: R.image.ac_image_search())
            imageView.left = 12
            leftMargin.addSubview(imageView)
//            leftMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
//            let rightMargin = UIView()
//            rightMargin.frame = CGRect(x: 0, y: 0, width: 17.5, height: 0)
            f.keyboardAppearance = .dark
            f.leftView = leftMargin
//            f.rightView = rightMargin
            f.leftViewMode = .always
//            f.rightViewMode = .always
            f.returnKeyType = .search
            f.attributedPlaceholder = NSAttributedString(string: R.string.localizable.amongChatRoomMessagePlaceholder(),
                                                         attributes: [
                                                            NSAttributedString.Key.foregroundColor : UIColor("#646464")
                                                         ])
            f.textColor = .white
            f.delegate = self
            f.font = R.font.nunitoExtraBold(size: 20)
            f.cornerRadius = 18
            f.clipsToBounds = true
            return f
        }()
        
        private let bag = DisposeBag()
    
        var inputResultHandler: ((String?) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            textField.rx.text
                .subscribe { [weak self] text in
                    self?.inputResultHandler?(text)
                }
                .disposed(by: bag)
        }
        
        private func configureSubview() {
    //        locationService = .northAmercia
            addSubview(textField)
            textField.snp.makeConstraints { maker in
                maker.leading.equalTo(20)
                maker.top.equalTo(24)
                maker.trailing.equalTo(-20)
                maker.height.equalTo(36)
            }
        }
        
        override func becomeFirstResponder() -> Bool {
            return textField.becomeFirstResponder()
        }
        
        override func resignFirstResponder() -> Bool {
            return textField.resignFirstResponder()
        }
    }
    
}

extension Social.ContactListViewController.SearchHeaderView: UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = true
//        isHidden = true
//        fadeOut(duration: 0.25, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
//        inputContainerView.isHidden = false
//        isHidden = false
//        alpha = 1
//        fadeIn(duration: 0.25, completion: nil)
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 100
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        guard let text = textField.text,
              text.count > 0 else {
            return true
        }
        textField.clear()
//        imViewModel.sendMessage(text)
        return true
    }
}
