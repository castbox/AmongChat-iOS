//
//  PushSettingController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PushSettingController: ViewController {
    
    
    override var screenName: Logger.Screen.Node.Start {
        return .settings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = R.string.localizable.settingsTitle()
    }
}

class PushSettingContainer: UITableViewController {
    
//    @IBOutlet weak var switchControl: MJMaterialSwitch!
    @IBOutlet weak var switchControl: UISwitch!
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchControl.isOn = Settings.shared.isOpenSubscribeHotTopic.value
        switchControl.rx.isOn
            .asDriver()
            .drive(onNext: { value in
//                guard let `self` = self else { return }
                Settings.shared.isOpenSubscribeHotTopic.value = value
            })
            .disposed(by: bag)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


