//
//  UITableView+Theme.swift
//  Castbox
//
//  Created by ChenDong on 2018/2/28.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit

extension ThemeHelper where Base: UITableView {

    // section header，透明色
    func sectionHeader() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    // section footer，灰色
    func footer(for section: Int) -> UIView {
        let isLastSection = self.base.dataSource?.numberOfSections?(in: self.base) == (section + 1)
        return isLastSection ? sectionHeader(): SeparatorLine()
    }
}


