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
        var rightIndicatorView: UIActivityIndicatorView!
        private let fontSize: CGFloat
        
        init(fontSize: CGFloat = 18) {
            self.fontSize = fontSize
            super.init(frame: .zero)
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize {
            return bounds.size
        }
        
        private func bindSubviewEvent() {
            backgroundColor = "#222222".color()
            cornerRadius = 18
            clipsToBounds = true
            leftView = UIImageView(image: R.image.ac_image_search())
            leftViewMode = .always
            
            rightIndicatorView = UIActivityIndicatorView(style: .white)
            rightIndicatorView.hidesWhenStopped = true
            rightView = rightIndicatorView
            rightViewMode = .always
            
            keyboardAppearance = .dark
            font = R.font.nunitoExtraBold(size: fontSize)
            
            textColor = .white
            //let font size
            attributedPlaceholder = NSAttributedString(string: R.string.localizable.searchPlaceholder(), attributes: [
                NSAttributedString.Key.foregroundColor : UIColor("#646464"),
                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: fontSize)
             ])
        }
        
        private func configureSubview() {
            
        }
        
        override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
            return CGRect(x: 12, y: 6, width: 24, height: 24)
        }
        
        override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
            return CGRect(x: bounds.width - 12 - 24, y: 6, width: 24, height: 24)
        }
        
        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            return CGRect(x: 44, y: 0, width: bounds.width - 44 * 2, height: bounds.height)
        }
        
        override func textRect(forBounds bounds: CGRect) -> CGRect {
            return editingRect(forBounds: bounds)
        }
        
        override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
            return editingRect(forBounds: bounds)
        }
    }
    
    class ViewModel {
        private let bag = DisposeBag()

        var userInfoList = BehaviorRelay<[Entity.UserProfile]?>(value: nil)
        var isLoadingReplay = BehaviorRelay<Bool>(value: false)
        var keywords: String = ""
        var hasMore = false

        func fetchUserSearch(_ keywords: String) {
            self.keywords = keywords
            isLoadingReplay.accept(true)
            Request.search(keywords, skip: 0)
                .catchErrorJustReturn(nil)
                .asObservable()
                .flatMap { [weak self] data -> Observable<[Entity.UserProfile]> in
                    let userList = data?.list ?? []
                    self?.hasMore = userList.count >= 20
                    self?.isLoadingReplay.accept(false)
                    return Observable.just(userList)
                }
                .bind(to: userInfoList)
                .disposed(by: bag)

        }

        func fetchUserSearchMore() {
            guard let list = userInfoList.value else {
                return
            }
            isLoadingReplay.accept(true)
            Request.search(keywords, skip: list.count)
                .asObservable()
                .flatMap { [weak self] data -> Observable<[Entity.UserProfile]> in
                    guard let `self` = self else { return .empty() }
                    let userList = data?.list ?? []
                    self.hasMore = userList.count >= 20
                    self.isLoadingReplay.accept(false)
                    let total = list + userList
                    return Observable.just(total)
                }
                .bind(to: userInfoList)
                .disposed(by: bag)
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
            btn.setContentCompressionResistancePriority(.required, for: .horizontal)
            return btn
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Search.UserCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var viewModel = ViewModel()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        override var screenName: Logger.Screen.Node.Start {
            return .search
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            bindSubviewEvent()
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
            viewModel.fetchUserSearch(key)
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
                self?.viewModel.fetchUserSearchMore()
            }
        }
        
        private func bindSubviewEvent() {
            viewModel.userInfoList
                .filterNil()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self](data) in
                    guard let `self` = self else { return }
                    self.userList = data
                    if self.userList.isEmpty {
                        self.addNoDataView(R.string.localizable.errorNoSearch(), image: R.image.ac_among_no_search_result())
                    } else {
                        //remove
                        self.removeNoDataView()
                    }
                    self.tableView.endLoadMore(self.viewModel.hasMore)
                })
                .disposed(by: bag)
            
            viewModel.isLoadingReplay
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.searchTextfield.rightIndicatorView.startAnimating()
                    } else {
                        self?.searchTextfield.rightIndicatorView.stopAnimating()
                    }
                })
                .disposed(by: bag)


        }
    }
}

extension Search.ViewController: UITextFieldDelegate {
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        guard let text = textField.text?.trimmed,
              text.count > 0 else {
            textField.text = nil
            return true
        }
        Logger.Action.log(.search_done)
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
        
        let cell = tableView.dequeueReusableCell(withClass: Search.UserCell.self)
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
            Logger.Action.log(.search_result_clk, category: .profile, user.uid.string)
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
}

extension Search {
    
    class UserCell: TableViewCell {
        
        var updateFollowData: ((Bool) -> Void)?
        var updateInviteData: ((Bool) -> Void)?
        
        let bag = DisposeBag()
        
        private lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
//            iv.layer.cornerRadius = 20
//            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var uidLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 14)
            lb.textColor = "#898989".color()
            return lb
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.backgroundColor = UIColor.theme(.backgroundBlack)
            btn.titleLabel?.lineBreakMode = .byTruncatingMiddle
            return btn
        }()
        
        private var userInfo: Entity.UserProfile!
        private var roomId = ""
        private var isInvite = false
        private var isStranger = false
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
        }
        
        private func setupLayout() {
            selectionStyle = .none
            
            backgroundColor = .clear
            
            contentView.addSubviews(views: avatarIV, usernameLabel, uidLabel, followBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(12)
                maker.right.equalTo(-115)
                maker.top.equalTo(avatarIV)
            }
            
            uidLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(12)
                maker.right.equalTo(-115)
                maker.top.equalTo(usernameLabel.snp.bottom)
                maker.bottom.equalTo(avatarIV)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.width.equalTo(90)
                maker.height.equalTo(32)
                maker.right.equalTo(-20)
                maker.centerY.equalTo(avatarIV.snp.centerY)
            }
            
            followBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    self.followUser()
                }).disposed(by: bag)
        }
        
        func configView(with model: Entity.UserProfile, isFollowing: Bool, isSelf: Bool) {
            self.isStranger = false
            self.userInfo = model
            if isSelf {
                if isFollowing {
                    followBtn.isHidden = true
                } else {
                    followBtn.isHidden = false
                }
            } else {
                followBtn.isHidden = false
                if !isFollowing {
                    let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
                    if selfUid == model.uid {
                        followBtn.isHidden = true
                    }
                }
            }
            
            avatarIV.setAvatarImage(with: model.pictureUrl)
            avatarIV.isVerify = model.isVerified
            usernameLabel.attributedText = model.nameWithVerified(isShowVerify: false)
            uidLabel.text = "ID: \(model.uid)"
            let isfollow = model.isFollowed ?? false
            setFollow(isfollow)
        }
        
        func setFollow(_ isFolllow: Bool) {
            if isFolllow {
                grayFollowStyle()
            } else {
                yellowFollowStyle()
            }
        }
        
        private func grayFollowStyle() {
            followBtn.setTitle(R.string.localizable.profileFollowing(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            followBtn.layer.borderColor = UIColor(hex6: 0x898989).cgColor
            followBtn.isEnabled = false
        }
        
        private func yellowFollowStyle() {
            followBtn.setTitle(R.string.localizable.profileFollow(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            followBtn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            followBtn.isEnabled = true
        }
        
        private func grayInviteStyle() {
            followBtn.setTitle(R.string.localizable.socialInvited(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            followBtn.backgroundColor = UIColor(hex6: 0x222222)
            followBtn.layer.borderColor = UIColor(hex6: 0x898989).cgColor
        }
        
        private func followUser() {
            let isFollowed = userInfo?.isFollowed ?? false
            if isFollowed {
//                Request.unFollow(uid: userInfo?.uid ?? 0, type: "follow")
//                    .subscribe(onSuccess: { [weak self](success) in
//                        guard let `self` = self else { return }
//                        removeBlock?()
//                        if success {
//                            self.setFollow(false)
//                            self.updateFollowData?(false)
//                        }
//                    }, onError: { (error) in
//                        removeBlock?()
//                        cdPrint("unfollow error:\(error.localizedDescription)")
//                    }).disposed(by: bag)
            } else {
                Logger.Action.log(.search_result_clk, category: .follow, userInfo.uid.string)
                let removeBlock = self.superview?.raft.show(.loading)
                Request.follow(uid: userInfo?.uid ?? 0, type: "follow")
                    .subscribe(onSuccess: { [weak self](success) in
                        guard let `self` = self else { return }
                        removeBlock?()
                        if success {
                            self.setFollow(true)
                            self.updateFollowData?(true)
                        }
                    }, onError: { (error) in
                        removeBlock?()
                        cdPrint("follow error:\(error.localizedDescription)")
                    }).disposed(by: bag)
            }
        }
    }
}
