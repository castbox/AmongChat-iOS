//
//  Feed.Share+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Feed.Share {
    
    class ShareInputView: UIView, UITextViewDelegate {
        
        private let bag = DisposeBag()
        
        private let maxInputLength = Int(280)
        
        private let sendSignal = PublishSubject<Void>()
        
        var enableAutoResizeHeight = true
        
        var sendObservable: Observable<Void> {
            return sendSignal.asObservable()
        }
        
        private lazy var gradientView: GradientView = {
            let v = GradientView()
            let l = v.layer
            l.colors = [UIColor(hex6: 0x121212, alpha: 0).cgColor, UIColor(hex6: 0x121212, alpha: 0.57).cgColor, UIColor(hex6: 0x121212).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0)
            l.endPoint = CGPoint(x: 0.5, y: 0.6)
            l.locations = [0, 1]
            return v
        }()
        
        private lazy var bodyContainer: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.05)
            v.layer.cornerRadius = 12
            v.layer.masksToBounds = true
            v.addSubviews(views: inputTextView, imageView, placeholderLabel)
            
            inputTextView.snp.makeConstraints { maker in
                maker.top.bottom.equalToSuperview().inset(12)
                maker.leading.equalToSuperview().offset(16)
                maker.trailing.equalTo(imageView.snp.leading).offset(-16)
            }
            
            imageView.snp.makeConstraints { maker in
                maker.width.height.equalTo(72)
                maker.trailing.equalToSuperview().offset(-16)
                maker.centerY.equalToSuperview()
            }
            
            placeholderLabel.snp.makeConstraints { maker in
                maker.leading.top.trailing.equalTo(inputTextView)
            }
            
            return v
        }()

        private(set) lazy var imageView: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            return i
        }()
        
        private(set) lazy var inputTextView: UITextView = {
            let f = UITextView()
            f.backgroundColor = .clear
            f.keyboardAppearance = .dark
            f.returnKeyType = .send
            f.textContainerInset = .zero
            f.textContainer.lineFragmentPadding = 0
            f.delegate = self
            f.font = R.font.nunitoBold(size: 16)
            f.textColor = .white
            f.rx.text
                .map({ ($0 != nil) && $0!.count > 0 })
                .subscribe(onNext: { [weak self] (hasText) in
                    
                    guard let `self` = self else { return }
                    
                    self.placeholderLabel.isHidden = hasText
                    self.sendButton.isEnabled = hasText
                })
                .disposed(by: bag)
            f.showsVerticalScrollIndicator = false
            f.showsHorizontalScrollIndicator = false
            return f
        }()
        
        private(set) lazy var placeholderLabel: UILabel = {
            let l = UILabel()
            l.numberOfLines = 0
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0x757575)
            l.text = R.string.localizable.amongChatRoomMessagePlaceholder()
            return l
        }()
        
        private(set) lazy var sendButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.clipsToBounds = true
            btn.setTitle(R.string.localizable.amongChatSend(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor("#757575".color(), for: .disabled)
            btn.setBackgroundImage("#FFF000".color().image, for: .normal)
            btn.setBackgroundImage("#303030".color().image, for: .disabled)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            return btn
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
                        
            addSubviews(views: gradientView, bodyContainer, sendButton)
            
            gradientView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            
            bodyContainer.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(97)
                maker.top.equalToSuperview().offset(40)
            }
            
            sendButton.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(48)
                maker.top.equalTo(bodyContainer.snp.bottom).offset(24)
                if #available(iOS 11.0, *) {
                    maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
                } else {
                    // Fallback on earlier versions
                    maker.bottom.equalToSuperview().offset(-(20 + Frame.Height.safeAeraBottomHeight))
                }
            }
        }
                
        // MARK: - UITextView Delegate
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let textFieldText = textView.text,
                  let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
            }
            
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + text.count
            return count <= maxInputLength
        }

        
    }
    
}
