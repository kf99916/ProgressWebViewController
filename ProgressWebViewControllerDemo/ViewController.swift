//
//  ViewController.swift
//  ProgressWebViewControllerDemo
//
//  Created by Zheng-Xiang Ke on 2017/10/14.
//  Copyright © 2017年 Zheng-Xiang Ke. All rights reserved.
//

import UIKit
import ProgressWebViewController

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let identifier = segue.identifier, let url = URL(string: "https://www.apple.com") else {
            return
        }

        switch identifier {
        case "Present":
            guard let navigationController = segue.destination as? UINavigationController, let progressWebViewController = navigationController.topViewController as? ProgressWebViewController else {
                return
            }

            progressWebViewController.url = url
            progressWebViewController.bypassedSSLHosts = [url.host!]
            progressWebViewController.userAgent = "ProgressWebViewController/1.0.0"
            progressWebViewController.websiteTitleInNavigationBar = false
            progressWebViewController.navigationItem.title = "Apple Website"
            progressWebViewController.leftNavigaionBarItemTypes = [.reload]
            progressWebViewController.toolbarItemTypes = [.back, .forward, .activity]
        case "Show":
            guard let progressWebViewController = segue.destination as? ProgressWebViewController else {
                return
            }
            progressWebViewController.disableZoom = true
            progressWebViewController.navigationWay = .push
            progressWebViewController.toolbarItemTypes = [.reload, .activity]
            progressWebViewController.url = url
            progressWebViewController.headers = ["browser": "in-app browser"]
            progressWebViewController.tintColor = .red
            progressWebViewController.cookies = [
                HTTPCookie(properties:
                [HTTPCookiePropertyKey.originURL: url.absoluteString,
                 HTTPCookiePropertyKey.path: "/",
                 HTTPCookiePropertyKey.name: "author",
                 HTTPCookiePropertyKey.value: "Zheng-Xiang Ke"])!,
                HTTPCookie(properties:
                [HTTPCookiePropertyKey.originURL: url.absoluteString,
                 HTTPCookiePropertyKey.path: "/",
                 HTTPCookiePropertyKey.name: "GitHub",
                 HTTPCookiePropertyKey.value: "kf99916"])!]
        default:
            print("Unknown segue \(identifier)")
        }
    }
}

