//
//  Enums.swift
//  ProgressWebViewController
//
//  Created by Zheng-Xiang Ke on 2017/10/14.
//  Copyright © 2017年 Zheng-Xiang Ke. All rights reserved.
//

import Foundation

public enum BarButtonItemType {
    case back
    case forward
    case reload
    case stop
    case activity
    case done
    case flexibleSpace
}

public enum NavigationBarPosition {
    case none
    case left
    case right
}

@objc public enum NavigationType: Int {
    case linkActivated
    case formSubmitted
    case backForward
    case reload
    case formResubmitted
    case other
}
