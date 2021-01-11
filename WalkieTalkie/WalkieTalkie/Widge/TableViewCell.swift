//
//  TableViewCell.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2021/1/4.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        changeSelectionColorForSelectedOrHiglightedState(selected)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        changeSelectionColorForSelectedOrHiglightedState(highlighted)
    }
    
    func changeSelectionColorForSelectedOrHiglightedState(_ state: Bool) {
        if state {
            backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.04)
        } else {
            backgroundColor = .clear
        }
    }

}
