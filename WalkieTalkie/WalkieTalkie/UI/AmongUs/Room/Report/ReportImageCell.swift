//
//  ReportImageCell.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/4/16.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit

class ReportImageCell: UICollectionViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var removeHandler: () -> Void = { }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func set(_ item: Report.ImageItem?) {
        if let image = item?.image {
            iconView.image = image
            iconView.contentMode = .scaleAspectFill
            deleteButton.isHidden = false
        } else {
            iconView.image = R.image.ac_icon_seat_add()
            iconView.contentMode = .center
            deleteButton.isHidden = true
        }
    }

    @IBAction func deleteAction(_ sender: Any) {
        removeHandler()
    }
}
