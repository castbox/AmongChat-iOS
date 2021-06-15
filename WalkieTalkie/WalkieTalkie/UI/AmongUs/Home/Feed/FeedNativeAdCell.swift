//
//  FeedNativeAdCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 15/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FeedNativeAdCell: UITableViewCell {
    
    weak var adView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = adView {
                contentView.addSubview(view)
                view.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(adViewLayoutGuide)
                }
            }
        }
    }
    
    private lazy var adViewLayoutGuide = UILayoutGuide()
    
//    weak var delegate: QuoteNativeAdCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubview()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSubview()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureSubview() {
        contentView.addLayoutGuide(adViewLayoutGuide)
        
        adViewLayoutGuide.snp.makeConstraints { (maker) in
//            maker.left.right.centerY.equalToSuperview()
            maker.edges.equalToSuperview()
        }
    }
    
}
