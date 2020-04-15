//
//  UIView+Theme.swift
//  Castbox
//
//  Created by ChenDong on 2018/2/28.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - 根据 Theme.Suite 设置文字，不好用，准备弃用
extension ThemeHelper where Base: UILabel {
    func set(_ theme: Theme.Suite) {
        self.base.font = theme.value.0
        self.base.textColor = theme.value.1
    }
}

extension ThemeHelper where Base: UITextField {
    func set(_ theme: Theme.Suite) {
        self.base.font = theme.value.0
        self.base.textColor = theme.value.1
    }
}

extension ThemeHelper where Base: UITextView {
    func set(_ theme: Theme.Suite) {
        self.base.font = theme.value.0
        self.base.textColor = theme.value.1
    }
}

extension ThemeHelper where Base: UIButton {
    func set(_ theme: Theme.Suite) {
        self.base.titleLabel?.font = theme.value.0
        self.base.setTitleColor(theme.value.1, for: .normal)
    }
}

// MARK: - 根据设置生成的 UIColor 序列
extension UIView: ThemeCompatible {}

extension Binder where Value == UIColor? {
    
    func setTheme(by color: Theme.Color) -> Disposable {
        return Settings.shared
            .theme.replay()
            .map({ color.counterpart(in: $0).value })
            .bind(to: self)
    }
}

// MARK: - 根据 Theme.Color 序列构造一些常用的 UIView 子类，子类自动实现了监听设置，变化颜色
// 分割线条
class SeparatorLine: UIView {
    let bag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.rx.backgroundColor.setTheme(by: .separatorLight).disposed(by: bag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.rx.backgroundColor.setTheme(by: .separatorLight).disposed(by: bag)
    }
    
    static var lineHeight: CGFloat {
        return 1/UIScreen.main.scale
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 0, height: SeparatorLine.lineHeight)
    }
}

// MARK: - UIButton
//extension Reactive where Base: UIButton {
//    func backgroundImageColor(for controlState: UIControl.State = []) -> Binder<UIColor?> {
//        return Binder<UIColor?>(self.base) { (button, color) -> () in
//            let image = color.flatMap {
//                UIImage.image(with: $0, size: CGSize(width: 1, height: 1))?
//                    .resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), resizingMode: .stretch) }
//            button.setBackgroundImage(image, for: controlState)
//        }
//    }
//}
//// MARK: - UISearchBar
//extension Reactive where Base: UISearchBar {
//    var searchFieldBackgroundColor: Binder<UIColor?> {
//        return Binder(self.base) { view, color in
//            view.setSearchFieldBackgroundColor(color!)
//        }
//    }
//    var backgroundImageColor: Binder<UIColor?> {
//        return Binder<UIColor?>(self.base) { (view, color) -> () in
//            let image = color.flatMap { UIImage.image(with: $0, size: CGSize(width: 1, height: 1)) }
//            view.backgroundImage = image
//        }
//    }
//}

