//
//  XibLoadableView.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/2/5.
//  Copyright © 2020 Guru. All rights reserved.
//

import UIKit

protocol XibLoadable: class {
    var xibView: UIView! { get set }
    
    func loadViewFromNib(_ xibName: String) -> UIView? 
}

extension XibLoadable where Self: UIView {
    
    func loadViewFromNib(_ xibName: String) -> UIView? {
        let nib = UINib(nibName: xibName, bundle: Bundle(for: type(of: self)))
        let nibViews = nib.instantiate(withOwner: self, options: nil)
        let view = nibViews.first as? UIView
        return view
    }
}

class XibLoadableView: UIView, XibLoadable {
    
    var xibView: UIView!
    
    var xibName: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initXib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initXib()
    }
    
    func initXib() {
        xibView = loadViewFromNib(xibName ?? self.className)
        xibView.frame = bounds
        addSubview(xibView)
    }
}
