//
//  PremiumViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class PremiumViewController: ViewController {

    @IBOutlet weak var lifeTimeButton: UIButton!
    @IBOutlet weak var monthButton: UIButton!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var freetrielButton: UIButton!
    var gradientLayer: CAGradientLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureSubview()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = container.bounds
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func policyButtonAction(_ sender: Any) {
        
    }
}

extension PremiumViewController {
    func configureSubview() {
        let startColor = UIColor(hex: 0x3023AE)!.alpha(0.57)
        let middenColor = UIColor(hex: 0x462EB4)!
        let endColor = UIColor(hex: 0xC86DD7)!
        let gradientColors: [CGColor] = [startColor.cgColor, middenColor.cgColor, endColor.cgColor]
        gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = [NSNumber(value: 0), NSNumber(value: 0.3), NSNumber(value: 1),]
        //(这里的起始和终止位置就是按照坐标系,四个角分别是左上(0,0),左下(0,1),右上(1,0),右下(1,1))
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.1, y: 1)
        //设置frame和插入view的layer
        gradientLayer.frame = view.bounds
        container.layer.insertSublayer(gradientLayer, at: 0)
    }
}
