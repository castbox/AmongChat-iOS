//
//  AmongSheetController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 18/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongSheetController: ViewController {
    
    enum ItemType {
        case userInfo
        case block
        case mute
        case unblock
        case unmute
        case report
        case kick
        case cancel
    }

    @IBOutlet weak var tableView: UITableView!
    
    var items: [ItemType] = []
    var user: Entity.RoomUser?
    var actionHandler: ((ItemType) -> Void)?
    
    static func show(with user: Entity.RoomUser? = nil, items: [ItemType], in viewController: UIViewController, actionHandler: ((ItemType) -> Void)?) {
        let sheetController = AmongSheetController()
        sheetController.items = items
        sheetController.user = user
        sheetController.actionHandler = actionHandler
        sheetController.showModal(in: viewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = items.safe(indexPath.row) else {
            return tableView.dequeueReusableCell(withIdentifier: "AmongSheetUserCell", for: indexPath)
        }
        if item == .userInfo {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AmongSheetUserCell", for: indexPath) as! AmongSheetUserCell
            cell.userIconView.setImage(with: user?.pictureUrl)
            cell.nameLabel.text = user?.name
            return cell
        } else {
            let iconCell = tableView.dequeueReusableCell(withIdentifier: "AmongSheetIconItemCell", for: indexPath) as! AmongSheetIconItemCell
            iconCell.item = item
            iconCell.clickHandler = { [weak self] item in
                self?.onClick(item)
            }
            return iconCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let room = dataSource[indexPath.row]
//        selectRoomHandler(room)
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
    
    func cornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
//    func canAutoDismiss() -> Bool {
//        return shouldDismiss()
//    }

}
