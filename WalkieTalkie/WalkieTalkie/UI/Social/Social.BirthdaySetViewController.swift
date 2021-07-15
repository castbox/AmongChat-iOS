//
//  BirthdaySetViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SVGAPlayer

extension Social {
    
    class BirthdaySetViewController: ViewController {
        
        private lazy var birthdayIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_set_birthday_birthday())
            return i
        }()
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            n.leftBtn.isHidden = true
            n.titleLabel.isHidden = true
            return n
        }()
        
        private lazy var mainTitle: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hex6: 0xFFFFFF)
            label.font = R.font.nunitoExtraBold(size: 28)
            label.text = R.string.localizable.amongChatSetBirthDayTitle()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        private lazy var subTitle: UILabel = {
            let label = UILabel()
            label.textColor = UIColor(hex6: 0x898989)
            label.font = R.font.nunitoExtraBold(size: 16)
            label.text = R.string.localizable.profileBirthdaySubtitle()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            return label
        }()
        
        private lazy var birthdayPicker: UIPickerView = {
            let p = UIPickerView(frame: CGRect(x: 40, y: 305, width: Frame.Screen.width - 70, height: 290))
            p.backgroundColor = UIColor(hex6: 0x121212)
            p.dataSource = self
            p.delegate = self
            return p
        }()
        
        private lazy var confirmBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoBlack(size: 20)
            btn.addTarget(self, action: #selector(onConfirmBtn), for: .primaryActionTriggered)
            btn.setTitle(R.string.localizable.profileDone(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x757575), for: .disabled)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.backgroundColor = UIColor(hex6: 0x2B2B2B)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 25
            btn.isEnabled = false
            return btn
        }()
        
        private lazy var policyLabel: PolicyLabel = {
            let terms = R.string.localizable.amongChatTermsService()
            let privacy = R.string.localizable.amongChatPrivacyPolicy()
            let text = R.string.localizable.amongChatPrivacyLabel(terms, privacy)

            let lb = PolicyLabel(with: text, privacy: privacy, terms: terms)
            lb.onInteration = { [weak self] targetPath in
                self?.open(urlSting: targetPath)
            }
            return lb
        }()
        
        private lazy var dataSource: [Date] = {
            var years = (12...100).compactMap {
                currentCalendar.date(byAdding: .year, value: -$0, to: todayNow)
            }
            years.insert(todayNow, at: 0)
            return years
        }()
        
        private lazy var guideView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.6)
            v.addSubview(svgaView)
            svgaView.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.size.equalTo(CGSize(width: 110, height: 171.5))
            }
            playSvga()
            let label = UILabel()
            label.font = R.font.nunitoExtraBold(size: 18)
            label.textColor = .white
            label.text = R.string.localizable.amongChatLoginBirthdayGuideTip()
            v.addSubview(label)
            label.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(svgaView.snp.bottom).offset(4)
                maker.leading.greaterThanOrEqualTo(Frame.horizontalBleedWidth)
            }
            v.isUserInteractionEnabled = false
            return v
        }()
        
        private lazy var svgaView: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            player.loops = 3
            player.delegate = self
            return player
        }()
        
        private let todayNow = Date()
        
        private let currentCalendar = Calendar.current
        
        var onCompletion: ((String) -> Void)? = nil
        var loggerSource: String? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.addSubviews(views: navView, birthdayIcon, mainTitle, subTitle, birthdayPicker, confirmBtn, policyLabel, guideView)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            birthdayIcon.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(navView.snp.bottom).offset(24)
            }
            
            mainTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(birthdayIcon.snp.bottom).offset(8)
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
            }
            
            subTitle.snp.makeConstraints { (maker) in
                maker.top.equalTo(mainTitle.snp.bottom).offset(7)
                maker.leading.trailing.equalToSuperview().inset(40)
            }

            birthdayPicker.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(215.scalHValue)
                maker.top.equalTo(subTitle.snp.bottom).offset(64.scalHValue)
            }
            
            confirmBtn.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(50)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-97)
            }
            
            policyLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-24)
            }
            
            guideView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            
            rx.viewDidAppear.take(1)
                .subscribe(onNext: { [weak self] (_) in
                    Logger.Action.log(.age_imp, category: nil, self?.loggerSource)
                })
                .disposed(by: bag)
            
            birthdayPicker.rx.itemSelected.subscribe(onNext: { [weak self] (row, _) in
                
                if row == 0 {
                    self?.confirmBtn.isEnabled = false
                    self?.confirmBtn.backgroundColor = UIColor(hex6: 0x2B2B2B)
                } else {
                    self?.confirmBtn.isEnabled = true
                    self?.confirmBtn.backgroundColor = UIColor(hex6: 0xFFF000)
                }
                self?.guideView.isHidden = true
            })
            .disposed(by: bag)
        }
        
        @objc
        private func onConfirmBtn() {
            
            let df = DateFormatter()
            df.dateFormat = "yyyyMMdd"
            let birthdayStr: String
            if let date = dataSource.safe(birthdayPicker.selectedRow(inComponent: 0)) {
                birthdayStr = df.string(from: date)
            } else {
                birthdayStr = "20050101"
            }
            
            let years: Int
            if let birthdayDate = df.date(from: birthdayStr) {
                years = currentCalendar.dateComponents([.year], from: birthdayDate, to: todayNow).year ?? 15
            } else {
                years = 15
            }
            
            let yearString = years < 13 ? "< 13" : years.string
            Logger.Action.log(.age_done, loggerSource, extra: ["age": yearString])
            
            let profile = Entity.ProfileProto(birthday: birthdayStr, name: nil, pictureUrl: nil)
            
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            let _ = Request.updateProfile(profile)
                .do(onDispose: {
                    hudRemoval()
                })
                .subscribe(onSuccess: { [weak self] (profile) in
                    defer {
                        Logger.Action.log(.age_done_result, category: nil, self?.loggerSource, (profile != nil ? 0 : 1), extra: ["age": yearString])
                        self?.onCompletion?(birthdayStr)
                    }
                    guard let p = profile else { return }
                    Settings.shared.amongChatUserProfile.value = p
                }, onError: { [weak self] (error) in
                    self?.view.raft.autoShow(.text("\(error.localizedDescription)"))
                    Logger.Action.log(.age_done_result_fail, category: nil, error.msgOfError)
                })
        }
        
        private func playSvga() {
            svgaView.stopAnimation()
            svgaView.clear()
            
            let parser = SVGAGlobalParser.defaut
            parser.parse(withNamed: R.file.birthdayGuideSvga.name, in: nil,
                         completionBlock: { [weak self] (item) in
                            self?.svgaView.videoItem = item
                            self?.svgaView.startAnimation()
                         },
                         failureBlock: { error in
                            debugPrint("error: \(error.localizedDescription)")
                         })
        }
        
    }
}

extension Social.BirthdaySetViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
}

extension Social.BirthdaySetViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 48
    }
        
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        guard let date = dataSource.safe(row) else {
            return UIView()
        }
        
        guard date != todayNow  else {
            let view: UIView = {
                let v = UIView()
                
                let dash = { () -> UIView in
                    let v = UIView()
                    v.backgroundColor = .white
                    v.layer.cornerRadius = 2
                    return v
                }
                
                let dash1 = dash()
                let dash2 = dash()
                v.addSubviews(views: dash1, dash2)
                let layoutGuide = UILayoutGuide()
                v.addLayoutGuide(layoutGuide)
                layoutGuide.snp.makeConstraints { (maker) in
                    maker.center.equalToSuperview()
                }
                
                dash1.snp.makeConstraints { (maker) in
                    maker.leading.top.bottom.equalTo(layoutGuide)
                    maker.width.equalTo(20)
                    maker.height.equalTo(4)
                }
                
                dash2.snp.makeConstraints { (maker) in
                    maker.trailing.top.bottom.equalTo(layoutGuide)
                    maker.width.equalTo(20)
                    maker.height.equalTo(4)
                    maker.leading.equalTo(dash1.snp.trailing).offset(4)
                }
                
                return v
            }()
            return view
        }
        
        let label: UILabel
        
        if let lb = view as? UILabel {
            label = lb
        } else {
            label = {
                let l = UILabel()
                l.font = R.font.nunitoExtraBold(size: 32)
                l.textColor = .white
                l.textAlignment = .center
                return l
            }()
        }
        
        if let years = currentCalendar.dateComponents([.year], from: date, to: todayNow).year {
            label.text = years < 13 ? "< 13" : years.string
        } else {
            label.text = nil
        }
        
        return label
    }
}

extension Social.BirthdaySetViewController: SVGAPlayerDelegate {
    
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer!) {
        
        guideView.isHidden = true
        
    }
    
}
