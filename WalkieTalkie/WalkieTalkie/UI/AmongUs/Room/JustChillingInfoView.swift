//
//  JustChillingInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class JustChillingInfoView: XibLoadableView {
    
    @IBOutlet weak var notesDetailButton: UIButton!
    
    
    var notes: String? {
        didSet {
            guard let string = notes else {
                notesDetailButton.setTitle("host could setup notes so everyone could see it when they join the room", for: .normal)
                return
            }
            notesDetailButton.setTitle(string, for: .normal)
        }
    }
    
    var hostNotesClick: CallBack?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        notesDetailButton.titleLabel?.numberOfLines = 0
    }
    
    private func configureSubview() {
        
    }
    
    @IBAction func hostNotesAction(_ sender: Any) {
        hostNotesClick?()
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
