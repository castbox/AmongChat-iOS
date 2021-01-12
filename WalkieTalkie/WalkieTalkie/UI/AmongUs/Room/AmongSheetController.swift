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
            cell.nameLabel.text = user?.name
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
