//
//  SearchViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/2.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchViewController: UITableViewController {
    var viewModel: SearchViewModel!
    
    var selectRoomHandler: (Room) -> Void = { _ in }
    var dataSource: [Room] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    private let bag = DisposeBag()
    private var currentType: ChannelType = .public
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = true
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        
        viewModel.querySourceSubject
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] rooms in
                self?.dataSource = rooms
            })
            .disposed(by: bag)
    }
    
    func setChannel(type: ChannelType?) {
        self.currentType = type ?? .public
//        tableView.backgroundColor = currentType.screenColor
    }
    
    func set(query: String) {
        cdPrint("query: \(query)")
        viewModel.query(query)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataSource.count
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchCell
        cell.set(dataSource[indexPath.row])
//        cell.backgroundColor = currentType.screenColor
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let room = dataSource[indexPath.row]
        selectRoomHandler(room)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}

class SearchCell: UITableViewCell {
    @IBOutlet weak var tagLabel: UITextField!
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var tagView: UILabel!
    @IBOutlet weak var lockIconView: UIImageView!
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let point = convert(point, to: self)
        return bounds.contains(point)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return self
    }
    
    func set(_ room: Room?) {
        guard let room = room else {
            return
        }
        nameLabel.text = {
            if room.user_count > 0 {
                return "\(room.showName)  \(room.userCountForShow)"
            }
            return room.showName
        }()
        let isPrivate = room.name.isPrivate
        lockIconView.isHidden = !isPrivate
        tagView.isHidden = isPrivate
//        countLabelWidthConstraint.constant = countLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: 200, height: 30), limitedToNumberOfLines: 1).size.width
    }
}
