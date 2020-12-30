//
//  Social.ReportViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social {
    
    class ReportViewController: WalkieTalkie.ViewController {
        
        var selectedReason: ((String) -> Void)?
                
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: LabelCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private let items = [
            R.string.localizable.reportIncorrectInformation(),
            R.string.localizable.reportIncorrectSexual(),
            R.string.localizable.reportIncorrectHarassment(),
            R.string.localizable.reportIncorrectUnreasonable(),
            ]
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
    
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
        }
        
        private func setupLayout() {

            view.backgroundColor = UIColor(hex6: 0x222222)
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
    }
}
// MARK: - UITableView
extension Social.ReportViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: LabelCell.self)
        cell.setCellData(items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 59.5
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedReason?(items[indexPath.row])
        hideModal()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 23.5
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let button = UIButton()
        button.setTitle(R.string.localizable.toastCancel(), for: .normal)
        button.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
        button.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
        button.rx.tap.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]() in
                self?.hideModal()
            }).disposed(by: bag)
        
        return button
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 72
    }
}

extension Social.ReportViewController {
    class LabelCell: UITableViewCell {
        
        private lazy var centerLabel: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.textColor = .white
            lb.font = R.font.nunitoExtraBold(size: 16)
            return lb
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            backgroundColor = .clear
            selectionStyle = .none
            
            contentView.addSubview(centerLabel)
            centerLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
            
            let line = UIView()
            line.backgroundColor = UIColor(hex6: 0xFFFFFF,alpha: 0.04)
            contentView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
        
        func setCellData(_ text: String) {
            centerLabel.text = text
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
extension Social.ReportViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 360
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
