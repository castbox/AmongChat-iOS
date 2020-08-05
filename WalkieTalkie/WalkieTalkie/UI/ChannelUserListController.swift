//
//  ChannelUserListController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/8/3.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ChannelUserListController: ViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var navHeightConstraint: NSLayoutConstraint!

    private var dataSource: [ChannelUser] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let channel: Room
    private let viewModel = ChannelUserListViewModel.shared
    
    init(channel: Room) {
        self.channel = channel
        super.init(nibName: "ChannelUserListController", bundle: nil)
        self.isNavigationBarHiddenWhenAppear = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSubview()
        bindSubviewEvent()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController()
    }
}

extension ChannelUserListController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataSource.count
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ChannelUserCell.self, for: indexPath)
        let user = dataSource[indexPath.row]
        cell.bind(user)
        cell.tapBlockHandler = { [weak self] in
            self?.showMoreSheet(for: user)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let room = dataSource[indexPath.row]
//        selectRoomHandler(room)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

}

extension ChannelUserListController: UITableViewDelegate {
    
}

extension ChannelUserListController {
    func showMoreSheet(for user: ChannelUser) {
        let alertVC = UIAlertController(
            title: nil,
            message: R.string.localizable.userListMoreSheet(),
            preferredStyle: .actionSheet
        )

        let reportAction = UIAlertAction(title: R.string.localizable.reportTitle(), style: .default, handler: { [weak self] _ in
            self?.showReportSheet(for: user)
        })
        let blockAction = UIAlertAction(title:user.status == .blocked ? R.string.localizable.alertUnblock() : R.string.localizable.alertBlock(), style: .default, handler: { [weak self] _ in
            self?.showBlockAlert(with: user)
        })
        alertVC.addAction(reportAction)
        alertVC.addAction(blockAction)
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    func showReportSheet(for user: ChannelUser) {
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportUserId()): \(user.uid)",
            preferredStyle: .actionSheet)

        let items = [
            R.string.localizable.reportIncorrectInformation(),
            R.string.localizable.reportIncorrectSexual(),
            R.string.localizable.reportIncorrectHarassment(),
            R.string.localizable.reportIncorrectUnreasonable(),
            ].enumerated()

        for (index, item) in items {
            let action = UIAlertAction(title: item, style: .default, handler: { [weak self] _ in
                self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
                Logger.Report.logImp(itemIndex: index, channelName: user.uid)
            })
            alertVC.addAction(action)
        }

        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    func showBlockAlert(with user: ChannelUser) {
        guard user.status != .blocked else {
            viewModel.unblockedUser(user)
            ChatRoomManager.shared.adjustUserPlaybackSignalVolume(user, volume: 100)
            return
        }
        let alertVC = UIAlertController(
            title: "Block \(user.name)?",
            message: "After blocking, \(user.name) will no longer be able to talk to you. ",
            preferredStyle: .alert
        )
        let confirmAction = UIAlertAction(title: R.string.localizable.alertBlock(), style: .default, handler: { [weak self] _ in
            
                self?.viewModel.blockedUser(user)
                ChatRoomManager.shared.adjustUserPlaybackSignalVolume(user, volume: 0)
        })
        
        let cancelAction = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel) { _ in
            
        }
        alertVC.addAction(cancelAction)
        alertVC.addAction(confirmAction)
        present(alertVC, animated: true, completion: nil)
    }
    
    func bindSubviewEvent() {
        viewModel.dataSourceReplay
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] users in
                self?.emptyView.isHidden = !users.isEmpty
                self?.dataSource = users
            })
            .disposed(by: bag)
    }
    
    func configureSubview() {
        tableView.register(nibWithCellClass: ChannelUserCell.self)
        navHeightConstraint.constant = Frame.Height.navigation
    }
}

extension ChannelUserListController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 438 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 10
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
}
