//
//  UIViewController+Helpers.swift
//  ProgressWebViewController
//
//  Created by Lei on 2025/1/13.
//  Copyright © 2025 Zheng-Xiang Ke. All rights reserved.
//

import UIKit

extension UIViewController {
    static var currentNavigationController: UINavigationController? {
        guard var currentViewController = UIWindow.key?.rootViewController else{
            return nil
        }
        
        while let presentedViewController = currentViewController.presentedViewController {
            currentViewController = presentedViewController
        }
        
        if let tabBarController = currentViewController as? UITabBarController, let selectedViewController = tabBarController.selectedViewController {
            currentViewController = selectedViewController
        }
        return currentViewController as? UINavigationController
    }
}
