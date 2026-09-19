//
//  SceneDelegate.swift
//  ProgressWebViewControllerDemo
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard scene is UIWindowScene else {
            return
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Release resources associated with this scene here.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart tasks paused while the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Pause ongoing tasks when the scene becomes inactive.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Undo changes made when the scene entered the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save data and release shared resources for this scene.
    }
}
