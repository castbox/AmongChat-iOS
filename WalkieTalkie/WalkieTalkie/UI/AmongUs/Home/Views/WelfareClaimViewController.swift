//
//  WelfareClaimViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 27/01/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SVGAPlayer

class WelfareClaimViewController: ViewController {
    
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var subtitleLabel: UILabel!
    @IBOutlet private(set) weak var welfareContainer: UIView!
    @IBOutlet private(set) weak var goButton: UIButton!

    var goHandler: CallBack?

    private lazy var svgaView: SVGAPlayer = {
        let player = SVGAPlayer(frame: .zero)
        player.clearsAfterStop = true
        player.contentMode = .scaleAspectFill
        player.isUserInteractionEnabled = false
        return player
    }()
    
    private lazy var decorationIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let welfare: Entity.DecorationEntity
    
    init(_ welfare: Entity.DecorationEntity) {
        self.welfare = welfare
        super.init(nibName: "WelfareClaimViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        // Do any additional setup after loading the view.
        
        
        if let decoType = Entity.DecorationCategory.DecorationType.init(rawValue: welfare.decoType) {
            switch decoType  {
            case .pet:
                
                welfareContainer.addSubview(svgaView)
                svgaView.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                playSvga(welfare.url?.url)
                titleLabel.text = R.string.localizable.amongChatExclusivePet()
                subtitleLabel.text = R.string.localizable.amongChatCongratesExclusivePet()
                
            default:
                welfareContainer.addSubview(decorationIV)
                decorationIV.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                decorationIV.layer.cornerRadius = 50
                decorationIV.setImage(with: welfare.url)
                titleLabel.text = R.string.localizable.amongChatExclusiveAvatar()
                subtitleLabel.text = R.string.localizable.amongChatCongratesExclusiveAvatar()
            }
        }
        
        goButton.setTitle(R.string.localizable.amongChatCreateRoomCardClaim(), for: .normal)
        goButton.setTitle(R.string.localizable.amongChatClaimed(), for: .disabled)        
        goButton.setBackgroundImage(UIColor(hex6: 0xFFF000).image, for: .normal)
        goButton.setBackgroundImage(UIColor(hex6: 0x393939).image, for: .disabled)
        goButton.isEnabled = !(welfare.isClaimed ?? false)
        
        Logger.Action.log(.search_exclusive_alert_imp, categoryValue: welfare.decoType, welfare.id.string)
    }

    @IBAction func closeButtonAction(_ sender: Any) {
        dismissModal()
        Logger.Action.log(.search_exclusive_alert_clk, "close")
    }
    
    @IBAction func goButtonAction(_ sender: Any) {
        goHandler?()
    }
}

extension WelfareClaimViewController {
    
    private func playSvga(_ resource: URL?) {
        svgaView.stopAnimation()
        svgaView.clear()
        guard let resource = resource else {
            return
        }
        
        let parser = SVGAGlobalParser.defaut
        parser.parse(with: resource,
                     completionBlock: { [weak self] (item) in
                        self?.svgaView.videoItem = item
                        self?.svgaView.startAnimation()
                     },
                     failureBlock: { error in
                        debugPrint("error: \(error?.localizedDescription ?? "")")
                     })
    }
    
}

extension WelfareClaimViewController: Modalable {
    func style() -> Modal.Style {
        return .alpha
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func containerCornerRadius() -> CGFloat {
        return 15
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
}
