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
    
    func set(_ query: String) {
        viewModel.query(query)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchCell
        cell.set(dataSource[indexPath.row])
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
    @IBOutlet weak var countLabel: UILabel!
    
    func set(_ room: Room?) {
        nameLabel.text = room?.channel_name
        if room?.user_count == 0 {
            countLabel.text = nil
        } else {
            countLabel.text = room?.user_count.string
        }
    }
}
