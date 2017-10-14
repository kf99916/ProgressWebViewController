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
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "Present":
            guard let navigationController = segue.destination as? UINavigationController, let progressWebViewController = navigationController.topViewController as? ProgressWebViewController else {
                return
            }

            progressWebViewController.url = URL(string: "https://www.apple.com")
            progressWebViewController.websiteTitleInNavigationBar = false
            progressWebViewController.navigationItem.title = "Apple Website"
            progressWebViewController.rightNavigaionBarItemTypes = [.reload]
            progressWebViewController.toolbarItemTypes = [.back, .forward, .activity]
        case "Show":
            guard let progressWebViewController = segue.destination as? ProgressWebViewController else {
                return
            }
            progressWebViewController.url = URL(string: "https://www.apple.com")
            progressWebViewController.tintColor = .red
        default:
            print("Unknown segue \(identifier)")
        }
    }
}

