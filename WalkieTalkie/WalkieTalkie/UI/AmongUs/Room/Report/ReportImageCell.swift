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
    
    enum Style {
        case video, image
    }
    
    var style = Style.image
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func set(_ item: ReportUploadMediaItem?) {
        if let image = item?.image {
            iconView.image = image
            iconView.contentMode = .scaleAspectFill
            deleteButton.isHidden = false
        } else {
            iconView.image = style == .image ? R.image.iconReportImageAdd() : R.image.iconReportVideoAdd()
            iconView.contentMode = .center
            deleteButton.isHidden = true
        }
    }

    @IBAction func deleteAction(_ sender: Any) {
        removeHandler()
    }
}
