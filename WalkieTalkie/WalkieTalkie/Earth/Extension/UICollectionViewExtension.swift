//
//  UICollectionViewExtension.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/25.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func register<T: UICollectionViewCell>(cellWithClazz clazz : T.Type) {
        register(T.self, forCellWithReuseIdentifier: NSStringFromClass(clazz))
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(withClazz clazz: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: NSStringFromClass(clazz), for: indexPath) as? T else {
            fatalError("Couldn't find UICollectionViewCell for \(NSStringFromClass(clazz)), make sure the cell is registered with collection view")
        }
        return cell
    }

}

extension UITableView {
    
    func register<T: UITableViewCell>(cellWithClazz clazz : T.Type) {
        register(T.self, forCellReuseIdentifier: NSStringFromClass(clazz))
    }
    
    func dequeueReusableCell<T: UITableViewCell>(withClazz clazz: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: NSStringFromClass(clazz), for: indexPath) as? T else {
            fatalError("Couldn't find UITableViewCell for \(NSStringFromClass(clazz)), make sure the cell is registered with collection view")
        }
        return cell
    }

}

extension UICollectionViewFlowLayout {
    
    open override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
    
}
