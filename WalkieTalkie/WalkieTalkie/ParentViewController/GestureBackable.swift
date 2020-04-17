//
//  GestureBackable.swift
//  xWallet_ios
//
//  Created by Wilson on 2019/5/24.
//  Copyright © 2019 Anmobi.inc. All rights reserved.
//

import UIKit

protocol GestureBackable: UIViewController {
    var isEnableScreenEdgeGesture: Bool { get set }
}
