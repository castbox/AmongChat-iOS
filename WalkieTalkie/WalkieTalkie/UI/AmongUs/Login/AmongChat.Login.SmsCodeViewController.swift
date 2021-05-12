//
//  AmongChat.Login.SmsCodeViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/19.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import UIKit
import YYText
import RxSwift
import RxCocoa

extension AmongChat.Login {
    
    class SmsCodeViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private lazy var codeIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_login_sms())
            return i
        }()
        
        private lazy var codeTitle: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 28)
            lb.textColor = .white
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatLoginCodeInputTitle()
            return lb
        }()
        
        private lazy var smsTip: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.adjustsFontSizeToFitWidth = true
            lb.text = R.string.localizable.amongChatLoginCodeInputTip(dataModel.telRegion, dataModel.phone)
            return lb
        }()
        
        private lazy var digitCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 30
            let vInset: CGFloat = 0
            let hwRatio: CGFloat = 52.0 / 45.0
            let interSpace: CGFloat = 9
            var cellWidth = (UIScreen.main.bounds.width - hInset * 2 - interSpace * 5 ) / 6
            var cellHeight = cellWidth * hwRatio
            adaptToIPad {
                cellWidth = 45
                cellHeight = 52
                hInset = (UIScreen.main.bounds.width - cellWidth * 6 - interSpace * 5 ) / 2
            }
            digitCollectionViewHeight = cellHeight
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = interSpace
            layout.sectionInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(DigitCell.self, forCellWithReuseIdentifier: NSStringFromClass(DigitCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.backgroundColor = .clear
            v.allowsSelection = false
            return v
        }()
        
        private var digitCollectionViewHeight: CGFloat = 0
        
        private lazy var codeInputField: UITextField = {
            let f = UITextField(frame: CGRect.zero)
            f.keyboardType = .numberPad
            f.delegate = self
            if #available(iOS 12.0, *) {
                f.textContentType = .oneTimeCode
            } else {
                // Fallback on earlier versions
            }
            f.keyboardAppearance = .dark
            return f
        }()
        
        private lazy var timingTip: YYLabel = {
            let l = YYLabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = .white
            l.textAlignment = .center
            return l
        }()
        
        private lazy var wrongCodeView: UIView = {
            let v = UIView()
            let bg = UIImageView(image: R.image.ac_login_wrong_code_bubble())
            let emoji = UIImageView(image: R.image.ac_login_wrong_emoji())
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = .white
            v.addSubviews(views: bg, emoji, l)
            bg.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            emoji.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(12)
                maker.centerY.equalTo(l)
            }
            
            l.snp.makeConstraints { (maker) in
                maker.leading.equalTo(emoji.snp.trailing).offset(4)
                maker.trailing.equalToSuperview().inset(12)
                maker.top.equalTo(13)
            }
            l.text = R.string.localizable.amongChatLoginCodeWrong()
            return v
        }()
        
        private let codeLength: Int = 6
        
        private let dataModel: DataModel
        
        private var digits: [String] = [] {
            didSet {
                digitCollectionView.reloadData()
            }
        }
        
        var loginHandler: ((Entity.LoginResult?, Error?) -> Void)? = nil
        var loggerSource: String? = nil
        
        init(with data: DataModel) {
            dataModel = data
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            digitCollectionView.snp.remakeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(smsTip.snp.bottom).offset(Frame.Scale.height(76))
                maker.height.equalTo(digitCollectionView.contentSize.height)
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
    }
    
}

extension AmongChat.Login.SmsCodeViewController {
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
}

extension AmongChat.Login.SmsCodeViewController {
    
    private func setupLayout() {
        
        view.addSubviews(views: codeInputField, backBtn, codeIcon, codeTitle, smsTip, digitCollectionView, timingTip)
        
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
            maker.width.height.equalTo(24)
        }
        
        codeIcon.snp.makeConstraints { (maker) in
            maker.top.equalTo(navLayoutGuide.snp.bottom).offset(24)
            maker.centerX.equalToSuperview()
        }
        
        codeTitle.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.top.equalTo(codeIcon.snp.bottom).offset(12)
        }
        
        smsTip.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.top.equalTo(codeTitle.snp.bottom).offset(8)
        }
        
        timingTip.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(30)
            maker.top.equalTo(digitCollectionView.snp.bottom).offset(12)
        }
        
    }
    
    private func setupEvent() {
        
        startCountingDown(countDown: dataModel.secondsRemain)
                
        codeInputField.becomeFirstResponder()
        codeInputField.rx.text
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (string) in
                
                self?.wrongCodeView.removeFromSuperview()
                
                guard let `self` = self,
                    let code = string else { return }
                self.digits = code.charactersArray.map({ String($0) })
                if code.count == self.codeLength {
                    self.veirfyCode()
                }
            })
            .disposed(by: bag)
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { [weak self] (_) in
                Logger.Action.log(.signin_phone_verify_imp, category: nil, self?.loggerSource)
            })
            .disposed(by: bag)

    }
    
    private func startCountingDown(countDown: Int) {
        
        Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.asyncInstance)
            .take(countDown + 1)
            .subscribe(onNext: { [weak self] (count) in
                self?.timingTip.text = R.string.localizable.amongChatLoginCodeInputTiming((countDown - count).secondsAsHHMMSS)
                self?.timingTip.textColor = .white
            }, onCompleted: { [weak self] in
                self?.buildResendLabel()
            })
            .disposed(by: bag)
        
    }
    
    private func buildResendLabel() {
        let resend = R.string.localizable.amongChatLoginCodeResend()
        let text = R.string.localizable.amongChatLoginCodeNotRecieve(resend)
        let resendRange = (text as NSString).range(of: resend)
        
        let attTxt = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let font: UIFont = R.font.nunitoExtraBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight(rawValue: UIFont.Weight.bold.rawValue))
        
        attTxt.addAttributes([NSAttributedString.Key.foregroundColor : UIColor(hex6: 0x898989),
                              NSAttributedString.Key.font : font,
                              NSAttributedString.Key.paragraphStyle : paragraphStyle],
                             range: NSRange(location: 0, length: text.count)
        )
        
        attTxt.addAttributes([NSAttributedString.Key.foregroundColor : UIColor(hex6: 0xFFF000)],
                             range: resendRange
        )
                
        timingTip.attributedText = attTxt
        
        timingTip.textTapAction = { [weak self] (containerView: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) -> Void in
            if NSIntersectionRange(range, resendRange).length > 0 {
                self?.requestSmsCode()
                Logger.Action.log(.signin_phone_verify_resend, category: nil, self?.loggerSource)
            }
        }
    }
    
    private func requestSmsCode() {
        let hudRemoval = view.raft.show(.loading)
        
        let completion = { [weak self] in
            hudRemoval()
            self?.timingTip.isUserInteractionEnabled = true
        }
        timingTip.isUserInteractionEnabled = false
        Request.requestSmsCode(telRegion: dataModel.telRegion, phoneNumber: dataModel.phone)
            .subscribe(onSuccess: { [weak self] (response) in
                completion()
                self?.codeInputField.clearText()
                self?.startCountingDown(countDown: response.data?.expire ?? 60)
            }, onError: { [weak self] (_) in
                completion()
                self?.view.raft.autoShow(.text(R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
    }
    
    private func veirfyCode() {
        let hudRemoval = view.raft.show(.loading)
        let completion = { [weak self] in
            hudRemoval()
            self?.view.isUserInteractionEnabled = true
        }
        view.isUserInteractionEnabled = false
        view.endEditing(true)
        Request.verifySmsCode(code: digits.joined(), telRegion: dataModel.telRegion, phoneNumber: dataModel.phone)
            .flatMap({ (response) -> Single<Entity.LoginResult?> in
                guard let token = response.data?.token else {
                    return Single.just(nil)
                }
                
                return AmongChat.Login.Manager().login(via: .phone, token: token)
            })
            .subscribe(onSuccess: { [weak self] (loginResult) in
                completion()
                
                guard let result = loginResult else {
                    Logger.Action.log(.signin_result, category: .phone, self?.loggerSource, 1)
                    self?.wrongCode()
                    return
                }
                
                self?.loginHandler?(result, nil)
                Logger.Action.log(.signin_result, category: .phone, self?.loggerSource, 0)
                
            }, onError: { [weak self] (error) in
                completion()
                self?.codeInputField.becomeFirstResponder()
                self?.wrongCode()
                self?.loginHandler?(nil, error)
                Logger.Action.log(.signin_result_fail, category: .phone, error.msgOfError)
            })
            .disposed(by: bag)
    }
    
    private func wrongCode() {
        HapticFeedback.Impact.error()
        digitCollectionView.shake()
        view.addSubview(wrongCodeView)
        wrongCodeView.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(digitCollectionView.snp.top).offset(-15)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(55)
        }
    }
}

extension AmongChat.Login.SmsCodeViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
            return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= codeLength
    }
    
}

extension AmongChat.Login.SmsCodeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return codeLength
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(DigitCell.self), for: indexPath) as! DigitCell
        let digit = digits.safe(indexPath.item)
        cell.configCell(digit: digit, showCursor: indexPath.item == digits.count)
        return cell
    }
}

extension AmongChat.Login.SmsCodeViewController {
    
    class DigitCell: UICollectionViewCell {
        
        private lazy var digitLabel: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 32)
            lb.textColor = .black
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var cursor: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x4DA2FF)
            v.layer.cornerRadius = 1
            v.isHidden = true
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        private func setupLayout() {
            contentView.backgroundColor = .white
            contentView.layer.cornerRadius = 8
            contentView.clipsToBounds = true
            
            contentView.addSubviews(views: digitLabel, cursor)
            
            digitLabel.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            cursor.snp.makeConstraints { (maker) in
                maker.width.equalTo(2)
                maker.height.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.centerX.equalToSuperview()
            }
            
        }
        
        func configCell(digit: String?, showCursor: Bool) {
            
            digitLabel.text = digit
            
            if showCursor {
                cursor.isHidden = false
                cursor.alpha = 1
                UIView.animate(withDuration: 1, delay: 0, options: [.repeat]) { [weak self] in
                    self?.cursor.alpha = 0
                }
            } else {
                cursor.isHidden = true
                contentView.layer.removeAllAnimations()
            }
            
        }
    }
    
}

extension AmongChat.Login.SmsCodeViewController {
    
    struct DataModel {
        var telRegion: String
        var phone: String
        var secondsRemain: Int
    }
    
}
