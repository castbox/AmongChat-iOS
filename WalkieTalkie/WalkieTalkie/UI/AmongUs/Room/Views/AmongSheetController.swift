//
//  AmongSheetController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 18/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongSheetController: ViewController {
    
    enum ItemType: String {
        case userInfo
        case profile
        case follow
        case block
        case mute
        case unblock
        case unmute
        case report
        case kick
        case cancel
        case drop
        case adminMuteIm
        case adminUnmuteIm
        case adminMuteMic
        case adminUnmuteMic
        case adminKick
        case dmDeleteHistory
        case share
        case notInterested
        case deleteVideo
        
        case pronounNotShare = "0"
        case pronounHe = "1"
        case pronounShe = "2"
        case pronounThey = "3"
        case pronounOther = "4"
        
    }
    
    enum UIStyleType {
        case room
        case profile
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [ItemType] = []
    var user: Entity.RoomUser?
    var actionHandler: ((ItemType) -> Void)?
    private var uiType: UIStyleType = .room
    
    static func show(with user: Entity.RoomUser? = nil, items: [ItemType], in viewController: UIViewController, uiType: UIStyleType? = .room, actionHandler: ((ItemType) -> Void)?) {
        let sheetController = AmongSheetController()
        sheetController.items = items
        sheetController.user = user
        sheetController.uiType = uiType ?? .room
        sheetController.actionHandler = actionHandler
        sheetController.showModal(in: viewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex6: 0x1D1D1D)
        tableView.backgroundColor = UIColor(hex6: 0x1D1D1D)
        
        tableView.register(UINib(nibName: "AmongSheetIconItemCell", bundle: nil),
                           forCellReuseIdentifier: "AmongSheetIconItemCell")
        tableView.register(UINib(nibName: "AmongSheetUserCell", bundle: nil),
                           forCellReuseIdentifier: "AmongSheetUserCell")
        
    }
    
    func onClick(_ item: ItemType) {
        switch item {
        case .cancel:
            self.hideModal()
        default:
            self.hideModal(animated: true) { [weak self] in
                self?.actionHandler?(item)
            }
        }
    }
}

extension AmongSheetController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = items.safe(indexPath.row) else {
            return tableView.dequeueReusableCell(withIdentifier: "AmongSheetUserCell", for: indexPath)
        }
        if item == .userInfo {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AmongSheetUserCell", for: indexPath) as! AmongSheetUserCell
            cell.userIconView.setAvatarImage(with: user?.pictureUrl)
            cell.nameLabel.attributedText = user?.nameWithVerified()
            return cell
        } else {
            let iconCell = tableView.dequeueReusableCell(withIdentifier: "AmongSheetIconItemCell", for: indexPath) as! AmongSheetIconItemCell
            iconCell.item = item
            iconCell.clickHandler = { [weak self] item in
                self?.onClick(item)
            }
            if uiType == .profile {
                iconCell.setProfileUI()
            }
            return iconCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return items.safe(indexPath.row)?.itemHeight ?? 60
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        if offset.y < -64 && scrollView.isTracking {
            self.hideModal()
        }
    }
}

extension AmongSheetController.ItemType {
    var itemHeight: CGFloat {
        switch self {
        case .userInfo:
            return 64
        default:
            return 60
        }
    }
}

extension AmongSheetController: Modalable {
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        let result = items.map { $0.itemHeight }.reduce(0) { (result, new) -> CGFloat in
            return result + new
        }
        return 24 + result + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func containerCornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
}

extension AmongSheetController.ItemType {
    var titleColor: UIColor {
        switch self {
        case .profile, .follow, .drop, .dmDeleteHistory,
             .pronounShe, .pronounHe, .pronounThey, .pronounOther, .pronounNotShare, .share, .notInterested:
            return .white
        case .block, .unblock, .mute, .unmute, .report, .kick, .adminKick, .adminMuteIm, .adminMuteMic, .adminUnmuteMic, .adminUnmuteIm, .deleteVideo:
            return "FB5858".color()
        case .cancel:
            return "898989".color()
        case .userInfo:
            return .white
        }
    }
    
    var backgroundImage: UIImage? {
        switch self {
        case .cancel:
            return nil
        default:
            return "3D3D3D".color().image
        }
    }
    
    var title: String? {
        switch self {
        case .profile:
            return R.string.localizable.profileProfile()
        case .follow:
            return R.string.localizable.profileFollow()
        case .block:
            return R.string.localizable.alertBlock()
        case .unblock:
            return R.string.localizable.alertUnblock()
        case .mute:
            return R.string.localizable.channelUserListMute()
        case .unmute:
            return R.string.localizable.channelUserListUnmute()
        case .report:
            return R.string.localizable.reportTitle()
        case .kick, .adminKick:
            return R.string.localizable.amongChatRoomKick()
        case .cancel:
            return R.string.localizable.toastCancel()
        case .drop:
            return R.string.localizable.alertDrop()
        case .adminMuteIm:
            return R.string.localizable.alertAdminMuteIm()
        case .adminMuteMic:
            return R.string.localizable.alertAdminMuteMic()
        case .adminUnmuteMic:
            return R.string.localizable.alertAdminUnmuteMic()
        case .adminUnmuteIm:
            return R.string.localizable.alertAdminUnmuteIm()
        case .dmDeleteHistory:
            return R.string.localizable.dmConversationDeleteHistory()
        case .pronounShe:
            return R.string.localizable.profilePronounSheHer()
        case .pronounHe:
            return R.string.localizable.profilePronounHeHim()
        case .pronounThey:
            return R.string.localizable.profilePronounTheyThem()
        case .pronounOther:
            return R.string.localizable.profilePronounOther()
        case .pronounNotShare:
            return R.string.localizable.profilePronounNotShare()
        case .share:
            return R.string.localizable.feedShare()
        case .notInterested:
            return R.string.localizable.feedSheetNotInterested()
        case .deleteVideo:
            return R.string.localizable.feedSheetDeleteVideo()
        default:
            return ""
        }
    }
}
