//
//  Search.ViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 12/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MBProgressHUD
import Alamofire
import SwiftyUserDefaults
import Adjust

struct Search {}

extension Search {
    
    class ViewController: WalkieTalkie.ViewController {
        
        lazy var searchBar: UISearchBar = {
            let searchBar = UISearchBar(frame: CGRect(x: -10, y: 0, width: UIScreen.main.bounds.width - 85, height: 36))
            searchBar.delegate = self
//            searchBar.placeholder = R.string.localizable.searchPlaceholder()
            searchBar.returnKeyType = .search
            
            let defaultTextAttribs: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = defaultTextAttribs
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.theme(.main)
            
            if #available(iOS 11.0, *) {
                let textField = searchBar.subviews.first?.subviews.last
                textField?.backgroundColor = UIColor.theme(.backgroundGray)
                textField?.layer.cornerRadius = 36 / 2.0
                textField?.clipsToBounds = true
            }
            return searchBar
        }()
                
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.FollowerCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
//        private var uid = 0
//        private var isFollowing = true
//        private var isSelf = false
        
        override var screenName: Logger.Screen.Node.Start {
            return .search
        }
        
        
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
            searchBar.resignFirstResponder()
            view.endEditing(true)
        }
        
        // MARK: - action
        @objc func searchEntrance() {
            self.navigationController?.popViewController(animated: true)
        }
        
        func search(key: String?) {
            guard let key = key, !key.isEmpty else {
                return
            }
//            tableView.ly_hideEmpty()
//            setupRx()
//            viewModel.fetchUserSearch(searchKey: key)
        }
        
        func setupNavi() {
            var barItem: UIBarButtonItem?
            if #available(iOS 11.0, *) {
                let searchBarBgView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 105, height: 36))
                searchBarBgView.addSubview(self.searchBar)
                barItem = UIBarButtonItem(customView: searchBarBgView)
            } else {
                barItem = UIBarButtonItem(customView: self.searchBar)
            }
            self.navigationItem.leftBarButtonItems = [barItem] as? [UIBarButtonItem]
            
            let cancelButtton: UIButton = UIButton(type: .custom)
            cancelButtton.frame = CGRect(x: 10, y: 0, width: 60, height: 20)
            cancelButtton.setTitleColor(.black, for: .normal)
            cancelButtton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            cancelButtton.setTitle(R.string.localizable.toastCancel(), for: .normal)
            cancelButtton.addTarget(self, action: #selector(searchEntrance), for: .touchUpInside)
            cancelButtton.sizeToFit()
            let cancelBtnItem = UIBarButtonItem(customView: cancelButtton)
            self.navigationItem.rightBarButtonItem = cancelBtnItem
            
            // search first response
            searchBar.becomeFirstResponder()
        }

        private func setupLayout() {
//            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            setupNavi()
            
//            view.addSubviews(views: backBtn, titleLabel)
//
//            let navLayoutGuide = UILayoutGuide()
//            view.addLayoutGuide(navLayoutGuide)
//            navLayoutGuide.snp.makeConstraints { (maker) in
//                maker.left.right.equalToSuperview()
//                maker.height.equalTo(49)
//                maker.top.equalTo(topLayoutGuide.snp.bottom)
//            }
//
//            backBtn.snp.makeConstraints { (maker) in
//                maker.centerY.equalTo(navLayoutGuide)
//                maker.left.equalToSuperview().offset(20)
//                maker.width.height.equalTo(25)
//            }
//
//            titleLabel.snp.makeConstraints { (maker) in
//                maker.center.equalTo(navLayoutGuide)
//            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
//                maker.top.equalTo(navLayoutGuide.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            tableView.pullToRefresh { [weak self] in
                self?.loadData()
            }
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        private func loadData() {
//            let removeBlock = view.raft.show(.loading)
//            if isFollowing {
//                Request.followingList(uid: uid, skipMs: 0)
//                    .subscribe(onSuccess: { [weak self](data) in
//                        removeBlock()
//                        guard let `self` = self, let data = data else { return }
//                        self.userList = data.list ?? []
//                        if self.userList.isEmpty {
//                            self.addNoDataView(R.string.localizable.errorNoFollowing())
//                        }
//                        self.tableView.endLoadMore(data.more ?? false)
//                    }, onError: { [weak self](error) in
//                        removeBlock()
//                        self?.addErrorView({ [weak self] in
//                            self?.loadData()
//                        })
//                        cdPrint("followingList error: \(error.localizedDescription)")
//                    }).disposed(by: bag)
//            } else {
//                Request.followerList(uid: uid, skipMs: 0)
//                    .subscribe(onSuccess: { [weak self](data) in
//                        removeBlock()
//                        guard let `self` = self, let data = data else { return }
//                        self.userList = data.list ?? []
//                        if self.userList.isEmpty {
//                            self.addNoDataView(R.string.localizable.errorNoFollowers())
//                        }
//                        self.tableView.endLoadMore(data.more ?? false)
//                    }, onError: { [weak self](error) in
//                        removeBlock()
//                        self?.addErrorView({ [weak self] in
//                            self?.loadData()
//                        })
//                        cdPrint("followerList error: \(error.localizedDescription)")
//                    }).disposed(by: bag)
//            }
        }
        
        private func loadMore() {
//            let skipMS = userList.last?.opTime ?? 0
//            if isFollowing {
//                Request.followingList(uid: uid, skipMs: skipMS)
//                    .subscribe(onSuccess: { [weak self](data) in
//                        guard let data = data else { return }
//                        let list =  data.list ?? []
//                        var origenList = self?.userList
//                        list.forEach({ origenList?.append($0)})
//                        self?.userList = origenList ?? []
//                        self?.tableView.endLoadMore(data.more ?? false)
//                    }, onError: { (error) in
//                        cdPrint("followingList error: \(error.localizedDescription)")
//                    }).disposed(by: bag)
//            } else {
//                Request.followerList(uid: uid, skipMs: skipMS)
//                    .subscribe(onSuccess: { [weak self](data) in
//                        guard let data = data else { return }
//                        let list =  data.list ?? []
//                        var origenList = self?.userList
//                        list.forEach({ origenList?.append($0)})
//                        self?.userList = origenList ?? []
//                        self?.tableView.endLoadMore(data.more ?? false)
//                    }, onError: { (error) in
//                        cdPrint("followerList error: \(error.localizedDescription)")
//                    }).disposed(by: bag)
//            }
        }
    }
}

extension Search.ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //        Analytics.log(event: "search", category: nil, name: searchBar.text, value: nil)
        Logger.PageShow.logger("search", "", searchBar.text ?? "", 0)
        searchBar.resignFirstResponder()
        search(key: searchBar.text)
    }
}

// MARK: - UITableView
extension Search.ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: Social.FollowerCell.self)
        if let user = userList.safe(indexPath.row) {
            cell.configView(with: user, isFollowing: false, isSelf: false)
            cell.updateFollowData = { [weak self] (follow) in
                guard let `self` = self else { return }
                self.userList[indexPath.row].isFollowed = follow
//                self.addLogForFollow(with: self.userList[indexPath.row].uid)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let user = userList.safe(indexPath.row) {
//            addLogForProfile(with: user.uid)
            let vc = Social.ProfileViewController(with: user.uid)
            vc.followedHandle = { [weak self](followed) in
                guard let `self` = self else { return }
//                if self.isSelf && self.isFollowing {
//                    if followed {
//                        self.userList.insert(user, at: indexPath.row)
//                    } else {
//                        self.userList.remove(at: indexPath.row)
//                    }
//                }
            }
            self.navigationController?.pushViewController(vc)
        }
    }
    
//    private func addLogForFollow(with uid: Int) {
//        if isSelf {
//            if isFollowing {
//                Logger.Action.log(.profile_following_clk, category: .follow, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_followers_clk, category: .follow, "\(uid)")
//            }
//        } else {
//            if isFollowing {
//                Logger.Action.log(.profile_other_followers_clk, category: .follow, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_other_following_clk, category: .follow, "\(uid)")
//            }
//        }
//    }
//    private func addLogForProfile(with uid: Int) {
//        if isSelf {
//            if isFollowing {
//                Logger.Action.log(.profile_following_clk, category: .profile, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_followers_clk, category: .profile, "\(uid)")
//            }
//        } else {
//            if isFollowing {
//                Logger.Action.log(.profile_other_following_clk, category: .profile, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_other_followers_clk, category: .profile, "\(uid)")
//            }
//        }
//    }
}
