//
//  AmongChat.Login.RegionModal.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/19.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import UIKit

extension AmongChat.Login {
    
    class RegionModal: WalkieTalkie.ViewController {
        
        private lazy var regionPicker: UIPickerView = {
            let p = UIPickerView(frame: CGRect(x: 40, y: 305, width: Frame.Screen.width - 70, height: 290))
            p.backgroundColor = UIColor(hex6: 0x121212)
            p.dataSource = self
            p.delegate = self
            return p
        }()
        
        private typealias Region = Entity.Region
        private let dataSource: [Region]
        private let initialRegion: Entity.Region
        
        private var viewHeight: CGFloat {
            return 291 + Frame.Height.safeAeraBottomHeight
        }
        
        var selectRegion: ((Entity.Region) -> Void)? = nil
        
        init(dataSource: [Entity.Region], initialRegion: Entity.Region) {
            self.dataSource = dataSource
            self.initialRegion = initialRegion
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
    }
    
}

extension AmongChat.Login.RegionModal {
    
    private func setupLayout() {
        
        let layoutGuide = UILayoutGuide()
        view.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(viewHeight)
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        view.addSubviews(views: regionPicker)
        
        regionPicker.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.centerY.equalTo(layoutGuide)
        }
        
        if let idx = dataSource.firstIndex(where: { $0.regionCode == initialRegion.regionCode }) {
            regionPicker.selectRow(idx, inComponent: 0, animated: false)
        }
    }
    
    private func setupEvent() {
        regionPicker.rx.itemSelected
            .subscribe(onNext: { [weak self] (row, _) in
                guard let region = self?.dataSource.safe(row) else {
                    return
                }
                self?.selectRegion?(region)
            })
            .disposed(by: bag)
    }
    
}

extension AmongChat.Login.RegionModal: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
}

extension AmongChat.Login.RegionModal: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
        
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        guard let region = dataSource.safe(row) else {
            return UIView()
        }
        
        let cell: RegionCell
        
        if let v = view as? RegionCell {
            cell = v
        } else {
            cell = RegionCell(frame: .zero)
        }
        
        cell.configCell(with: region)
                
        return cell
    }
}



extension AmongChat.Login.RegionModal: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return viewHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func containerCornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}

private extension AmongChat.Login.RegionModal {
    
    class RegionCell: UIView {
        
        private lazy var flagLabel: UILabel = {
            let l = UILabel()
            l.font = UIFont.systemFont(ofSize: 25)
            return l
        }()
        
        private lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = .white
            l.adjustsFontSizeToFitWidth = true
            return l
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: flagLabel, titleLabel)
            
            flagLabel.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(16)
                maker.top.bottom.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(flagLabel.snp.trailing).offset(13)
                maker.trailing.equalToSuperview().inset(16)
                maker.top.bottom.equalToSuperview()
            }
            
            flagLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            titleLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
        }
        
        func configCell(with region: Entity.Region) {
            flagLabel.text = region.regionCode.emojiFlag
            titleLabel.text = region.region + " (\(region.telCode))"
        }
    }
    
}
