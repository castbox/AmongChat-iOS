//
//  Feed.Share.SelectFriendsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import MYTableViewIndex

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
        
        private lazy var tableViewIndex: TableViewIndex = {
            let i = TableViewIndex()
            i.indexInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            i.font = R.font.nunitoExtraBold(size: 14)!
            i.dataSource = self
            i.delegate = self
            return i
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
        
        var didSharedCallback: ((Result<Void, MsgError>) -> Void)? = nil
        
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
        
        view.addSubviews(views: navView, searchTextfield, friendsTable, tableViewIndex, shareInputView)
        
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
        
        tableViewIndex.snp.makeConstraints { maker in
            maker.trailing.bottom.equalToSuperview()
            maker.top.equalTo(friendsTable)
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
                self?.tableViewIndex.reloadData()
                self?.updateHighlightedItems()
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
        
        let removeHandler = view.raft.show(.loading)
        Request.feedShareToUser(feed, uids: viewModel.selectedUsers.map { $0.user.uid }, text: shareInputView.inputTextView.text ?? "")
            .do(onDispose: {
                removeHandler()
            })
            .subscribe(onSuccess: { [weak self] result in
                let anonymousUsers = result?.uidsAnonymous ?? []
                self?.dismiss(animated: true, completion: { [weak self] in
                    self?.didSharedCallback?(anonymousUsers.isEmpty ? .success(()) : .failure(MsgError(code: -1, msg: R.string.localizable.feedShareToAnonymousUserTips())))
                })
                
            }, onError: { [weak self] error in
                self?.view.raft.autoShow(.text(MsgError.default.msg ?? ""))
            })
            .disposed(by: bag)
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHighlightedItems()
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

extension Feed.Share.SelectFriendsViewController: TableViewIndexDataSource {
    //MARK: - TableViewIndexDataSource
    func indexItems(for tableViewIndex: TableViewIndex) -> [UIView] {
        return viewModel.sectionModels.compactMap({
            $0.indexView
        })
    }
    
}

extension Feed.Share.SelectFriendsViewController: TableViewIndexDelegate {
    //MARK: - TableViewIndexDelegate
    
    func tableViewIndex(_ tableViewIndex: TableViewIndex, didSelect item: UIView, at index: Int) -> Bool {
        let originalOffset = friendsTable.contentOffset
        
        let sectionIndex = viewModel.mapIndexTitleToSection(index: index)
        if sectionIndex != NSNotFound {
            let rowCount = friendsTable.numberOfRows(inSection: sectionIndex)
            let indexPath = IndexPath(row: rowCount > 0 ? 0 : NSNotFound, section: sectionIndex)
            friendsTable.scrollToRow(at: indexPath, at: .top, animated: false)
        } else {
            friendsTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        return friendsTable.contentOffset != originalOffset
    }
}

extension Feed.Share.SelectFriendsViewController {
    //MARK: - index bar helper
    private func uncoveredTableViewFrame() -> CGRect {
        return CGRect(x: friendsTable.bounds.origin.x, y: friendsTable.bounds.origin.y + topLayoutGuide.length,
                      width: friendsTable.bounds.width, height: friendsTable.bounds.height - topLayoutGuide.length)
    }
    
    private func updateHighlightedItems() {
        let frame = uncoveredTableViewFrame()
        var visibleSections = Set<Int>()
        
        for section in 0..<friendsTable.numberOfSections {
            if (frame.intersects(friendsTable.rect(forSection: section)) ||
                frame.intersects(friendsTable.rectForHeader(inSection: section))) {
                visibleSections.insert(section)
            }
        }
        trackSelectedSections(visibleSections)
    }
    
    private func trackSelectedSections(_ sections: Set<Int>) {
        let sortedSections = sections.sorted()
        
        UIView.animate(withDuration: 0.25, animations: {
            for (index, item) in self.tableViewIndex.items.enumerated() {
                let section = self.viewModel.mapIndexTitleToSection(index: index)
                let shouldHighlight = sortedSections.count > 0 && section >= sortedSections.first! && section <= sortedSections.last!
                item.tintColor = shouldHighlight ? UIColor(hex6: 0xFFF000) : UIColor(hex6: 0x595959)
            }
        })
    }
}
