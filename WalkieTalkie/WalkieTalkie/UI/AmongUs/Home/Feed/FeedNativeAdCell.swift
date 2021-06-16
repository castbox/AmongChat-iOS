//
//  FeedNativeAdCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 15/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FeedNativeAdCell: UITableViewCell {
    
    weak var adView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = adView {
                if let nativeView = view.subviews.first(where: { $0 is NativeFeedsAdView }) as? NativeFeedsAdView,
                   nativeView.sponsoredByLabel.text?.isEmpty == true {
                    nativeView.sponsoredByLabel.isHidden = false
                    nativeView.sponsoredByLabel.text = "Sponsored"
                }
                contentView.addSubview(view)
                view.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(adViewLayoutGuide)
                }
            }
        }
    }
    
    @IBOutlet private weak var removeAdContainer: UIStackView!
    var removeAdHandler: CallBack?
    
    private lazy var adViewLayoutGuide = UILayoutGuide()
    
    private let bag = DisposeBag()
    
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
        removeAdContainer.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.removeAdHandler?()
            })
            .disposed(by: bag)
    }

    @IBAction func removeAdAction(_ sender: Any) {
        removeAdHandler?()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureSubview() {
        contentView.addLayoutGuide(adViewLayoutGuide)
        
        adViewLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(-76)
//            maker.edges.equalToSuperview()
        }
    }
    
}
