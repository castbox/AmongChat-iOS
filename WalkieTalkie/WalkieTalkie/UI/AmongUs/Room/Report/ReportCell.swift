//
//  ReportCell.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/15.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReportCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        contentView.rx.backgroundColor
//            .setTheme(by: .backgroundWhite)
//            .disposed(by: bag)
        contentView.backgroundColor = Theme.mainBgColor
        
    }
    
    func set(_ item: Entity.Report.Reason?, isSelected: Bool) {
        nameLabel.text = item?.reasonText
        iconView.image = isSelected ? R.image.iconReportSelected() : R.image.iconReportNormal()
    }
    
}
