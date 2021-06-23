//
//  Feed.Share.SelectFriendsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

extension Feed.Share {
    
    class SelectFriendsViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_profile_close(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.dismiss(animated: true)
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.feedShareWith()
            return n
        }()
        
        private lazy var searchTextfield: Search.TextField = {
            let textfield = Search.TextField(fontSize: 20)
            textfield.delegate = self
            textfield.textAlignment = .left
            textfield.setContentHuggingPriority(.required, for: .horizontal)
            textfield.layer.cornerRadius = 20
            textfield.returnKeyType = .search
            textfield.attributedPlaceholder = NSAttributedString(string: R.string.localizable.contactSearchInputPlaceholder(), attributes: [
                NSAttributedString.Key.foregroundColor : UIColor("#646464"),
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .black)
            ])
            
            return textfield
        }()
        
        private lazy var friendsTable: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(cellWithClazz: UserCell.self)
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 72
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var shareInputView: Feed.Share.ShareInputView = {
            let v = Feed.Share.ShareInputView()
            v.imageView.setImage(with: feed.img)
            v.isHidden = true
            v.sendObservable
                .subscribe(onNext: { [weak self] _ in
                    self?.send()
                })
                .disposed(by: bag)
            return v
        }()
        
        private let viewModel = ViewModel()
        private let feed: Entity.Feed
        
        private weak var searchResultView: Feed.Share.SearchResultViewController?
        
        init(with feed: Entity.Feed) {
            self.feed = feed
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
    }
    
}

extension Feed.Share.SelectFriendsViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: navView, searchTextfield, friendsTable, shareInputView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        searchTextfield.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(20)
            maker.top.equalTo(navView.snp.bottom).offset(24)
            maker.height.equalTo(40)
        }
        
        friendsTable.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(searchTextfield.snp.bottom).offset(12)
        }
        
        shareInputView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().offset(0)
        }
        
        friendsTable.pullToLoadMore { [weak self] in
            let _ = self?.viewModel.loadData()
                .subscribe(onSuccess: { more in
                    self?.friendsTable.endLoadMore(more)
                }, onError: { error in
                    self?.friendsTable.endLoadMore(true)
                })
        }
        
    }
    
    private func setUpEvents() {
        
        viewModel.dataUpdatedSignal
            .subscribe(onNext: { [weak self] _ in
                self?.friendsTable.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.hasSelectedUser
            .subscribe(onNext: { [weak self] selected in
                
                guard let `self` = self else { return }
                
                self.shareInputView.isHidden = !selected
                self.friendsTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: selected ? self.shareInputView.height : 0, right: 0)
            })
            .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight.asObservable()
            .subscribe(onNext: { [weak self] keyboardVisibleHeight in
                
                guard let `self` = self else { return }
                
                self.shareInputView.snp.updateConstraints { maker in
                    maker.bottom.equalToSuperview().offset(-(keyboardVisibleHeight - Frame.Height.safeAeraBottomHeight - 8))
                }
                
            })
            .disposed(by: bag)
        
    }
    
    private func send() {
        //TODO: - send
        
        //        let removeHandler = view.raft.show(.loading)
        //        Request.feedShareToUser(feed.pid, uids: viewModel.selectedUsers.map { $0.user.uid }, text: shareInputView.inputTextView.text ?? "")
        //            .subscribe(onSuccess: { [weak self] result in
        //                removeHandler()
        //                let anonymousUsers = result?.uidsAnonymous ?? []
        //                self?.dismissModal(animated: true, completion: { [weak self] in
        //                    self?.dismissHandler?(anonymousUsers.isEmpty ? "": R.string.localizable.feedShareToAnonymousUserTips())
        //                })
        //            }, onError: { error in
        //                removeHandler()
        //            })
        //            .disposed(by: bag)
    }
    
    private func selectUser(_ user: UserViewModel) {
        let (actionValid, message) = viewModel.selectUser(user)
        if actionValid {
            friendsTable.reloadData()
        } else {
            view.raft.autoShow(.text(message ?? ""))
        }
    }
    
    private func showSearchResult() {
        IQKeyboardManager.shared.shouldResignOnTouchOutside = false
        let resultVC = Feed.Share.SearchResultViewController()
        addChild(resultVC)
        view.addSubview(resultVC.view)
        resultVC.view.snp.makeConstraints { (maker) in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.top.equalTo(friendsTable)
        }
        resultVC.didMove(toParent: self)
        
        resultVC.didSelectUser = { [weak self] user in
            self?.selectUser(user)
            self?.hideSearchResult()
            self?.searchTextfield.resignFirstResponder()
            self?.searchTextfield.clear()
        }
        
        resultVC.userIsSelected = { [weak self] user in
            return self?.viewModel.isUserSelected(user) ?? false
        }
        
        searchResultView = resultVC
    }
    
    private func hideSearchResult() {
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        searchResultView?.willMove(toParent: nil)
        searchResultView?.view.removeFromSuperview()
        searchResultView?.removeFromParent()
    }
}

extension Feed.Share.SelectFriendsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sectionModels.safe(section)?.users.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClazz: UserCell.self, for: indexPath)
        
        if let user = viewModel.sectionModels.safe(indexPath.section)?.users.safe(indexPath.row) {
            cell.bindData(user, selected: viewModel.isUserSelected(user))
        }
        
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.indexTitles
    }
    
}

extension Feed.Share.SelectFriendsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let user = viewModel.sectionModels.safe(indexPath.section)?.users.safe(indexPath.row) else {
            return
        }
        
        selectUser(user)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let section = viewModel.sectionModels.safe(section) else {
            return nil
        }
        
        switch section.sectionType {
        case .followingUsers:
            
            let view = IndexHeader()
            view.titleLabel.text = section.title
            return view
            
        default:
            let view = IconHeader()
            view.titleLabel.text = section.title
            view.icon.image = section.icon
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard let section = viewModel.sectionModels.safe(section) else {
            return .leastNormalMagnitude
        }
        
        switch section.sectionType {
        case .followingUsers:
            return 22
        default:
            return 75
        }
    }
    
}

extension Feed.Share.SelectFriendsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text,
           text.count > 0 {
            viewModel.searchUser(name: text)
                .subscribe(onSuccess: { [weak self] users in
                    self?.searchResultView?.result = users
                })
                .disposed(by: bag)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        hideSearchResult()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showSearchResult()
    }
    
}
