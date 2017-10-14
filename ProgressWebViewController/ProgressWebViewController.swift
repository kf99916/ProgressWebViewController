//
//  ProgressWebViewController.swift
//  ProgressWebViewController
//
//  Created by Zheng-Xiang Ke on 2017/10/14.
//  Copyright © 2017年 Zheng-Xiang Ke. All rights reserved.
//

import UIKit
import WebKit

let estimatedProgressKeyPath = "estimatedProgress"

open class ProgressWebViewController: UIViewController {

    open var url: URL?
    open var doneBarButtonItemEnabled = true
    open var progressTintColor: UIColor?
    
    var webView: WKWebView!
    var progressView: UIProgressView!
    
    override open func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        webView.allowsBackForwardNavigationGestures = true
        webView.isMultipleTouchEnabled = true
        
        webView.addObserver(self, forKeyPath: estimatedProgressKeyPath, options: .new, context: nil)
        
        view = webView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    
        setUpProgressView()
        
        if doneBarButtonItemEnabled && presentingViewController != nil {
            addDoneBarButtonItem()
        }

        // Do any additional setup after loading the view.
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        else {
            print("[ProgressWebViewController][Error] Invalid url:", url as Any)
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let navigationController = navigationController else {
            return
        }
        navigationController.navigationBar.addSubview(progressView)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        progressView.removeFromSuperview()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == estimatedProgressKeyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        progressView.alpha = 1
        progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        
        if(webView.estimatedProgress >= 1.0) {
            UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                self.progressView.alpha = 0
            }, completion: {
                finished in
                self.progressView.setProgress(0, animated: false)
            })
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Internal Methods
extension ProgressWebViewController {
    func setUpProgressView() {
        guard let navigationController = navigationController else {
            return
        }
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 0, y: navigationController.navigationBar.frame.size.height - progressView.frame.size.height, width: navigationController.navigationBar.frame.size.width, height: progressView.frame.size.height)
        progressView.trackTintColor = UIColor(white: 1, alpha: 0)
        if let progressTintColor = progressTintColor {
            progressView.progressTintColor = progressTintColor
        }
    }
    
    func addDoneBarButtonItem () {
        if navigationItem.leftBarButtonItems == nil {
            navigationItem.leftBarButtonItems = []
        }
        
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDidClick(sender:)))
        navigationItem.leftBarButtonItems?.append(doneBarButtonItem)
    }
    
    @objc func doneDidClick(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - WKUIDelegate
extension ProgressWebViewController: WKUIDelegate {
    
}

// MARK: - WKNavigationDelegate
extension ProgressWebViewController: WKNavigationDelegate {
    
}
