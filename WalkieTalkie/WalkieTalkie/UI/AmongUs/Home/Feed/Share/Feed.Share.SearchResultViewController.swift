//
//  Feed.Share.SearchResultViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/23.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Feed.Share {
    
    class SearchResultViewController: WalkieTalkie.ViewController {
        
        private typealias UserCell = Feed.Share.SelectFriendsViewController.UserCell
        private lazy var resultTable: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(cellWithClazz: UserCell.self)
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 72
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        typealias UserViewModel = Feed.Share.SelectFriendsViewController.UserViewModel
        var result: [UserViewModel] = [] {
            didSet {
                resultTable.reloadData()
            }
        }
        
        var didSelectUser: ((UserViewModel) -> Void)? = nil
        var userIsSelected: ((UserViewModel) -> Bool)? = nil
        
        init() {
            super.init(nibName: nil, bundle: nil)
            setUpLayout()
            setUpEvents()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}

extension Feed.Share.SearchResultViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: resultTable)
        
        resultTable.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
    }
    
    private func setUpEvents() {
        
        RxKeyboard.instance.visibleHeight.asObservable()
            .subscribe(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                self.resultTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardVisibleHeight, right: 0)
            })
            .disposed(by: bag)
        
    }
    
}

extension Feed.Share.SearchResultViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClazz: UserCell.self, for: indexPath)
        
        if let user = result.safe(indexPath.row) {
            cell.bindData(user, selected: userIsSelected?(user) ?? false)
        }
        
        return cell
    }
        
}

extension Feed.Share.SearchResultViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let user = result.safe(indexPath.row) {
            didSelectUser?(user)
        }
    }
    
}
