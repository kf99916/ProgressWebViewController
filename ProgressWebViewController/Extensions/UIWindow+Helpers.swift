//
//  UIWindow+Helpers.swift
//  ProgressWebViewController
//
//  Created by Lei on 2025/1/13.
//  Copyright © 2025 Zheng-Xiang Ke. All rights reserved.
//

extension UIWindow {
    static var key: UIWindow? {
        let allScenes = UIApplication.shared.connectedScenes
        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where window.isKeyWindow {
                return window
            }
        }
        return nil
    }
}
