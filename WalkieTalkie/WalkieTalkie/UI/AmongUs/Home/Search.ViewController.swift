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
    class TextField: UITextField, UITextFieldDelegate {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func bindSubviewEvent() {
            backgroundColor = "#FFFFFF".color().alpha(0.1)
            cornerRadius = 18
            clipsToBounds = true
            leftView = UIImageView(image: R.image.ac_image_search())
            leftViewMode = .always
            attributedPlaceholder = NSAttributedString(string: R.string.localizable.searchPlaceholder(), attributes: [
                NSAttributedString.Key.foregroundColor : UIColor("#646464"),
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 20)
             ])
        }
        
        private func configureSubview() {
            
        }
        
        override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
            return CGRect(x: 12, y: 6, width: 24, height: 24)
        }
        
        override func textRect(forBounds bounds: CGRect) -> CGRect {
            return CGRect(x: 49.5, y: 0, width: bounds.width - 49.5 - 10, height: bounds.height)
        }
        
        override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
            return CGRect(x: 49.5, y: 0, width: bounds.width - 49.5 - 10, height: bounds.height)
        }
    }
    
    class ViewController: WalkieTalkie.ViewController {
        
        private lazy var searchTextfield: TextField = {
            let textfield = TextField()
            textfield.delegate = self
            return textfield
        }()
                
        private lazy var cancelBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setTitle(R.string.localizable.toastCancel(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.addTarget(self, action: #selector(onCancelBtn), for: .primaryActionTriggered)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            return btn
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
            searchTextfield.becomeFirstResponder()
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            searchTextfield.resignFirstResponder()
            view.endEditing(true)
        }
        
        // MARK: - action
        @objc func searchEntrance() {
            self.navigationController?.popViewController(animated: true)
        }
        
        @objc func onCancelBtn() {
            navigationController?.popViewController()
        }
        
        func search(key: String?) {
            guard let key = key, !key.isEmpty else {
                return
            }
//            tableView.ly_hideEmpty()
//            setupRx()
//            viewModel.fetchUserSearch(searchKey: key)
        }

        private func setupLayout() {
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            let navigationBar = UIView()
            navigationBar.backgroundColor = "#121212".color()
            
            view.addSubviews(views: tableView, navigationBar)
            
            navigationBar.addSubviews(views: searchTextfield, cancelBtn)
            
            navigationBar.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.height.equalTo(49 + Frame.Height.safeAeraTopHeight)
            }
            
            searchTextfield.snp.makeConstraints { maker in
                maker.leading.equalTo(20)
                maker.height.equalTo(36)
                maker.bottom.equalTo(-6.5)
                maker.trailing.equalTo(cancelBtn.snp.leading)
            }
            cancelBtn.snp.makeConstraints { maker in
                maker.trailing.equalTo(-10)
                maker.centerY.equalTo(searchTextfield)
            }
            
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navigationBar.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            Request.followingList(uid: Settings.shared.loginResult.value?.uid ?? 0, skipMs: 0)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self, let data = data else { return }
                    self.userList = data.list ?? []
                    if self.userList.isEmpty {
                        self.addNoDataView(R.string.localizable.errorNoFollowing())
                    }
                    self.tableView.endLoadMore(data.more ?? false)
                }, onError: { [weak self](error) in
                    removeBlock()
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                    cdPrint("followingList error: \(error.localizedDescription)")
                }).disposed(by: bag)
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

extension Search.ViewController: UITextFieldDelegate {
    
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
        
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        guard let textFieldText = textField.text,
//              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
//            return false
//        }
//        let substringToReplace = textFieldText[rangeOfTextToReplace]
//        let count = textFieldText.count - substringToReplace.count + string.count
//        return count <= 10
//    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        guard let text = textField.text,
              text.count > 0 else {
            return true
        }
        Logger.PageShow.logger("search", "", text ?? "", 0)
        search(key: text)
        return true
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
