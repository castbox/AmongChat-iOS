//
//  GuideViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import RxSwift
import RxCocoa

class GuideViewController: ViewController {
    
    @IBOutlet weak var continueButton: WalkieButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var continueButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var continueButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var iapTipsLabel: UILabel!
    
    private var isStartTimer: Bool = false
    private let fourthPage = R.storyboard.main.premiumViewController()!
    private var isFirstShowPage2 = false
    private var isFirstShowPage3 = false
    private var isFirstShowPage4 = false
    private var iapTipsLabelText = R.string.localizable.premiumTryTitleDes("$19.99")
    private var selectedProductId: String? {
        didSet {
            updateContinueButtonTitle()
        }
    }
    var dismissHandler: (()->Void)? = nil
    
    var maxPage: Int {
        Int(scrollView.contentSize.width / scrollView.width) - 1
    }
    var pageIndex: Int {
        Int(scrollView.contentOffset.x / scrollView.width)
    }
    
    override var screenName: Logger.Screen.Node.Start {
        return .tutorial
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Defaults[\.firstInstall] = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureSubview()
        bindSubviewEvent()
        Logger.PageShow.log(.tutorial_imp_1)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fourthPage.view.frame = CGRect(x: Frame.Screen.width * 3, y: 0, width: Frame.Screen.width, height: Frame.Screen.height)
    }
    
    @IBAction func skipAction(_ sender: Any) {
        //        dismiss(animated: true, completion: nil)
        self.dismissHandler?()
    }
    
    @IBAction func continueAction(_ sender: Any) {
        let index = pageIndex + 1
        if index > maxPage { //last page
            fourthPage.buySelectedProducts()
        } else {
            scrollView.setContentOffset(CGPoint(x: scrollView.width * index.cgFloat, y: 0), animated: true)
        }
    }
    @IBAction func privacyAction(_ sender: Any) {
        open(urlSting: "https://walkietalkie.live/policy.html")
    }
}

extension GuideViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var pageIndex = Int(scrollView.contentOffset.x / scrollView.width)
        if pageIndex < 0 {
            pageIndex = 0
        } else if pageIndex > maxPage {
            pageIndex = maxPage
        }
        updateSubviewStatus(pageIndex)
        updateContinueButtonTitle()
        privacyButton.isHidden = pageIndex > 0
        if pageIndex == 1, !isFirstShowPage2 {
            isFirstShowPage2 = true
            Logger.PageShow.log(.tutorial_imp_2)
        } else if pageIndex == 2, !isFirstShowPage3 {
            isFirstShowPage3 = true
            Logger.PageShow.log(.tutorial_imp_3)
        }
    }
}

extension GuideViewController {
    func updateContinueButtonTitle() {
        guard pageIndex == 3 else {
            iapTipsLabel.isHidden = true
//            iapTipsLabel.fadeOut()
            return
        }
        iapTipsLabel.fadeIn()
//        iapTipsLabel.isHidden = false
        let tryAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: R.font.nunitoBold(size: 18) ?? Font.bigBody.value,
            .kern: 0.5
        ]
        
        let mutableNormalString = NSMutableAttributedString()
        if selectedProductId == IAP.productYear {
            //
            if FireStore.shared.isInReviewSubject.value {
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideSubscribeTitle(), attributes: tryAttr))
            } else {
//                let tryDesAttr: [NSAttributedString.Key: Any] = [
//                    .foregroundColor: UIColor.black.alpha(0.7),
//                    .font: UIFont.systemFont(ofSize: 12)
//                ]
                mutableNormalString.append(NSAttributedString(string: R.string.localizable.premiumTryTitle(), attributes: tryAttr))
//                mutableNormalString.append(NSAttributedString(string: "\n\(R.string.localizable.premiumTryTitleDes())", attributes: tryDesAttr))
            }
//            iapTipsLabel.text = iapTipsLabelText
            iapTipsLabel.isHidden = false
        } else {
            iapTipsLabel.isHidden = true
            mutableNormalString.append(NSAttributedString(string: R.string.localizable.guideContinue(), attributes: tryAttr))
            
        }
        UIView.setAnimationsEnabled(false)
        continueButton.setAttributedTitle(mutableNormalString, for: .normal)
        continueButton.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        
        if !isFirstShowPage4 {
            isFirstShowPage4 = true
            Logger.IAP.logImp(.first_open)
        }
        
    }
    
    func updateSubviewStatus(_ pageIndex: Int) {
        if pageIndex == 3 {
            //            continueButton.isHidden = true
            scrollView.isScrollEnabled = false
        }
    }
    
    func bindSubviewEvent() {
        IAP.productsValue
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] maps in
                guard let price = maps[IAP.productYear]?.skProduct.localizedPrice else {
                    return
                }
                //                self?.iapTipsLabelText = R.string.localizable.premiumTryTitleDes(price)
                //                if let text = self?.iapTipsLabel.text,
                //                    !text.isEmpty {
                self?.iapTipsLabel.text = R.string.localizable.premiumTryTitleDes(price)
                //                }
            })
            .disposed(by: bag)

        FireStore.shared.onlineChannelList()
//            .debug()
            .map { items -> Room? in
                let sortedItems = items.sorted {
                    $0.user_count > $1.user_count
                }
                return sortedItems.first(where: { $0.user_count <= 4 })
            }
//            .debug()
            .filterNil()
            .subscribe(onNext: { room in
                Defaults.set(channel: room, mode: .public)
            })
            .disposed(by: bag)
    }
    
    func configureSubview() {
        if Frame.Height.deviceDiagonalIsMinThan4_7 {
            continueButtonHeightConstraint.constant = 44
            continueButtonBottomConstraint.constant = 25
            continueButton.cornerRadius = 22
        } else if Frame.Height.deviceDiagonalIsMinThan5_5 {
            continueButtonBottomConstraint.constant = Frame.Scale.height(50)
        }
        
        continueButton.appendKern()
        
        let firstPage = GuideFirstView(frame: Frame.Screen.bounds)
        scrollView.addSubview(firstPage)
        
        let secondPage = GuideSecondView(frame: Frame.Screen.bounds)
        secondPage.x = Frame.Screen.width
        scrollView.addSubview(secondPage)
        
        let thirdPage = GuideThirdView(frame: Frame.Screen.bounds)
        thirdPage.x = Frame.Screen.width * 2
        scrollView.addSubview(thirdPage)
        
        fourthPage.style = .guide
        fourthPage.source = .first_open
        fourthPage.dismissHandler = { [weak self] in
            //            self?.dismiss(animated: true, completion: nil)
            self?.dismissHandler?()
        }
        fourthPage.didSelectProducts = { [weak self] pid in
            self?.selectedProductId = pid
        }
        fourthPage.view.frame = CGRect(x: Frame.Screen.width * 3, y: 0, width: Frame.Screen.width, height: Frame.Screen.height)
        //        fourthPage.willMove(toParent: self)
        addChild(fourthPage)
        scrollView.addSubview(fourthPage.view)
        
        scrollView.contentSize = CGSize(width: Frame.Screen.width * 4, height: Frame.Screen.height)
        
        continueButton.titleLabel?.lineBreakMode = .byWordWrapping
        continueButton.titleLabel?.textAlignment = .center
    }
}

