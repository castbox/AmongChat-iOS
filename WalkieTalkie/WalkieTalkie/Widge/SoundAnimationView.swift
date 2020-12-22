//
//  SoundAnimationView.swift
//  Runner
//
//  Created by 0929-2 on 2019/12/24.
//  Copyright © 2019 Guru. All rights reserved.
//

import UIKit

class SoundAnimationView: UIView {
    
    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(soundAnimation))
        link.add(to: .main, forMode: .common)
        link.frameInterval = 60
        link.isPaused = true
        return link
    }()
    
    lazy var inView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = R.image.ac_animation_background()
        view.tintColor = .white
        return view
    }()
    
    lazy var outView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = R.image.ac_animation_background()
        view.tintColor = .white
        return view
    }()
    
    var timer: SwiftTimer?
    var countDown = 1
    var isReverse = false
    var soundWidth: CGFloat = Frame.Screen.width / 5.0 {
        didSet {
            inView.snp.updateConstraints { make in
                make.width.height.equalTo(width)
            }
            outView.snp.updateConstraints { make in
                make.width.height.equalTo(width - 20)
            }
        }
    }
    
    deinit {
//        timer?.cancel()
//        timer = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isHidden = true
        
        addSubview(inView)
        inView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(width)
        }
        
        addSubview(outView)
        outView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(width - 20)
        }
        
        timer = SwiftTimer(interval: .seconds(1), repeats: true, queue: .main, handler: { [weak self] (timer) in
            guard let `self` = self else { return }
            if self.countDown <= 0 {
                self.stopLoading()
                timer.suspend()
            }
            self.countDown -= 1
        })
    }
    
    func startLoading() {
//        DispatchQueue.main.async { [weak self] in
//            guard let `self` = self else { return }
            self.isHidden = false
            self.displayLink.isPaused = false
            self.countDown = 2
            self.timer?.start()
//        }
    }
    
    @objc func stopLoading() {
//        DispatchQueue.main.async { [weak self] in
//            guard let `self` = self else { return }
            self.isHidden = true
            self.displayLink.isPaused = true
//        }
    }
    
    @objc func soundAnimation() {
        UIView.animate(withDuration: 1) { [weak self] in
            guard let `self` = self else { return }
            self.inView.snp.updateConstraints({ (make) in
                make.width.height.equalTo(self.isReverse ? self.soundWidth - 20: self.soundWidth)
            })
            
            self.outView.snp.updateConstraints({ (make) in
                make.width.height.equalTo(self.isReverse ? self.soundWidth: self.soundWidth - 20)
            })
            
            self.layoutIfNeeded()
        }
        self.isReverse = !self.isReverse
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
