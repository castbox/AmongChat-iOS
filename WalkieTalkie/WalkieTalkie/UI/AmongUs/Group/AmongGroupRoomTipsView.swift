//
//  AmongGroupRoomTipsView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 06/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit

class AmongGroupRoomTipsView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 16, y: 11, width: bounds.width, height: 22))
        lb.font = R.font.nunitoExtraBold(size: 16)
        lb.textColor = .black
        lb.text = R.string.localizable.groupRoomHostNotes()
        return lb
    }()
    
    private lazy var introLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: 16, y: 36.5, width: bounds.width, height: 22))
        lb.font = R.font.nunitoExtraBold(size: 12)
        lb.textColor = "#666666".color()
        lb.numberOfLines = 0
        return lb
    }()
    
    private lazy var editButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 0, y: 2, width: 40, height: 40)
        btn.right = 6
        btn.centerY = titleLabel.centerY
        btn.setImage(R.image.ac_group_room_tip_edit(), for: .normal)
        btn.addTarget(self, action: #selector(editButtonAction(_:)), for: .touchUpInside)
        return btn
    }()
    
    var editHandler: CallBack?
    
    var group: Entity.Group? {
        didSet {
            introLabel.text = group?.note ?? "Label Label Label Label Label Label Label Label Label Label Label Label Label Label"
            editButton.isHidden = group?.loginUserIsAdmin == false
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ group: Entity.Group) -> CGSize {
        let introString = group.note ?? "Label Label Label Label Label Label Label Label Label Label Label Label Label Label"
        introLabel.text = introString
        editButton.isHidden = group.loginUserIsAdmin == false
        //size
        let maxWidth: CGFloat = 252.scalValue.int.cgFloat
        let size = introString.boundingRect(with: CGSize(width: maxWidth - 16 * 2, height: 400), font: R.font.nunitoExtraBold(size: 12)!)
        introLabel.size = CGSize(width: size.width, height: size.height)
        let viewSize = CGSize(width: maxWidth, height: size.height + 46 + 16)
        titleLabel.width = viewSize.width - 60
        editButton.left = viewSize.width - 46
        return viewSize
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        addSubviews(views: titleLabel, introLabel, editButton)
    }
    
    @IBAction func editButtonAction(_ sender: Any) {
        editHandler?()
    }
}
