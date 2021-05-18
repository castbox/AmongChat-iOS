//
//  AddStatsPendingController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 18/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AddStatsPendingController: ViewController {
    private lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = R.font.nunitoExtraBold(size: 24)
        lb.textColor = UIColor.white
        lb.text = R.string.localizable.amongChatAddStats()
        return lb
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(R.image.ac_back(), for: .normal)
        btn.rx.controlEvent(.primaryActionTriggered)
            .subscribe(onNext: { [weak self] (_) in
                self?.navigationController?.popViewController()
            })
            .disposed(by: bag)
        return btn
    }()
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    let skill: Entity.GameSkill
    
    init(with skill: Entity.GameSkill) {
        self.skill = skill
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        removeUnusedControllers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureSubview()
        //remove
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        navigationController?.popViewController()
    }
    
    func removeUnusedControllers() {
        guard let controllers = navigationController?.viewControllers else {
            return
        }
        var newStack: [UIViewController] = []
        for vc in controllers {
            newStack.append(vc)
            if vc is Social.ProfileViewController {
                break
            }
        }
        newStack.append(self)
        navigationController?.viewControllers = newStack
    }
    
    func configureSubview() {
        subtitleLabel.text = R.string.localizable.statsReviewGameState(skill.topicName)
        view.addSubviews(views: backBtn, titleLabel)
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(navLayoutGuide)
        }

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
