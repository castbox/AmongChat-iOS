//
//  SeatLoadingView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

// MARK: - 麦位loading
/// 麦位loading view
class SeatLoadingView: UIView {
    
    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(pointAnimation))
        link.add(to: .main, forMode: .common)
        link.preferredFramesPerSecond = 2
        link.isPaused = true
        return link
    }()
    
    var index = 0
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.theme(.backgroundWhite)
        layer.cornerRadius = 8
//                clipsToBounds = true
        isHidden = true
        
        for i in 0..<3 {
            let point = UIView(frame: .zero)
            point.backgroundColor = UIColor.white
            point.tag = 10 + i
            point.layer.cornerRadius = 2
            point.isHidden = true
            addSubview(point)
            let left: CGFloat = 7 + 7 * CGFloat(i)
            point.snp.makeConstraints { make in
                make.left.equalTo(left)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(4)
            }
        }
    }
    
    func startLoading() {
        isHidden = false
        displayLink.isPaused = false
    }
    
    func stopLoading() {
        isHidden = true
        displayLink.isPaused = true
    }
    
    @objc func pointAnimation() {
        viewWithTag(10 + index)?.isHidden = false
        // 重头开始
        if index == 3 {
            index = 0
            subviews.forEach { view in
                if view.tag >= 10 {
                    view.isHidden = true
                }
            }
            return
        }
        index += 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
