//
//  NoDataView.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class NoDataView: UIView {
    
    lazy var icon: UIImageView = {
        let i = UIImageView()
        i.contentMode = .scaleAspectFit
        return i
    }()
    
    lazy var messageLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 16)
        lb.text = ""
        lb.textAlignment = .center
        lb.textColor = UIColor(hex6: 0xABABAB)
        return lb
    }()
    
    init(with message: String, image: UIImage? = nil, topEdge: CGFloat? = nil) {
        super.init(frame: CGRect.zero)
        icon.image = image ?? R.image.ac_among_no_data()
        addSubviews(views: icon, messageLabel)
        
        icon.snp.makeConstraints { (maker) in
            maker.width.height.greaterThanOrEqualTo(120)
            maker.top.equalTo(topEdge ?? 165.scalValue)
            maker.centerX.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(icon.snp.bottom).offset(16.5)
            maker.centerX.equalToSuperview()
        }
        messageLabel.text = message
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NoDatacell: UITableViewCell {
    
    private var noDataView = NoDataView(with: "")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(noDataView)
        
        noDataView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(500)
        }
    }
    
    func setCellMeessage(_ message: String) {
        noDataView.messageLabel.text = message
    }
    
    func updateCellUI() {
        noDataView.icon.snp.updateConstraints { (maker) in
            maker.top.equalTo(75.scalValue)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
