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
    open var doneBarButtonItemPosition: NavigationBarPosition = .left
    open var leftNavigaionBarItemTypes: [BarButtonItemType] = []
    open var rightNavigaionBarItemTypes: [BarButtonItemType] = []
    open var toolbarItemTypes: [BarButtonItemType] = [.back, .forward, .reload, .activity]
    open var tintColor: UIColor?
    
    fileprivate var webView: WKWebView!
    fileprivate var progressView: UIProgressView!
    fileprivate var previousNavigationBarHidden = false
    fileprivate var previousToolbarHidden = false
    
    lazy fileprivate var barButtonItemMapping: [BarButtonItemType: UIBarButtonItem] = {
        let bundle = Bundle(for: ProgressWebViewController.self)
        
        return [
            .back: UIBarButtonItem(image: UIImage(named: "Back", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(backDidClick(sender:))),
            .forward: UIBarButtonItem(image: UIImage(named: "Forward", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(forwardDidClick(sender:))),
            .reload: UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadDidClick(sender:))),
            .activity: UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(activityDidClick(sender:))),
            .done: UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDidClick(sender:))),
            .flexibleSpace: UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            ]
    }()
    
    deinit {
        webView.removeObserver(self, forKeyPath: estimatedProgressKeyPath)
    }
    
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
        
        // Do any additional setup after loading the view.
        navigationItem.title = navigationItem.title ?? url?.absoluteString
        
        if let navigationController = navigationController {
            previousNavigationBarHidden = navigationController.navigationBar.isHidden
            previousToolbarHidden = navigationController.toolbar.isHidden
        }
        
        setUpProgressView()
        addBarButtonItems()
        
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
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.toolbar.isHidden = false
        navigationController?.navigationBar.addSubview(progressView)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        progressView.removeFromSuperview()
        
        navigationController?.setToolbarHidden(previousToolbarHidden, animated: true)
        navigationController?.setNavigationBarHidden(previousNavigationBarHidden, animated: true)
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
}

// MARK: - Fileprivate Methods
fileprivate extension ProgressWebViewController {
    func setUpProgressView() {
        guard let navigationController = navigationController else {
            return
        }
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 0, y: navigationController.navigationBar.frame.size.height - progressView.frame.size.height, width: navigationController.navigationBar.frame.size.width, height: progressView.frame.size.height)
        progressView.trackTintColor = UIColor(white: 1, alpha: 0)
        
        if let tintColor = tintColor {
            progressView.progressTintColor = tintColor
        }
    }
    
    func addBarButtonItems() {
        if presentingViewController != nil {
            switch doneBarButtonItemPosition {
            case .left:
                if !leftNavigaionBarItemTypes.contains(.done) {
                    leftNavigaionBarItemTypes.insert(.done, at: 0)
                }
            case .right:
                if !rightNavigaionBarItemTypes.contains(.done) {
                    rightNavigaionBarItemTypes.insert(.done, at: 0)
                }
            case .none:
                break
            }
        }

        navigationItem.leftBarButtonItems = leftNavigaionBarItemTypes.map {
            barButtonItemType in
            if let barButtonItem = barButtonItemMapping[barButtonItemType] {
                return barButtonItem
            }
            return UIBarButtonItem()
        }
        
        navigationItem.rightBarButtonItems = rightNavigaionBarItemTypes.map {
            barButtonItemType in
            if let barButtonItem = barButtonItemMapping[barButtonItemType] {
                return barButtonItem
            }
            return UIBarButtonItem()
        }
        
        if let tintColor = tintColor {
            navigationController?.navigationBar.tintColor = tintColor
        }
        
        var itemTypes = toolbarItemTypes
        for index in 0..<itemTypes.count - 1 {
            itemTypes.insert(.flexibleSpace, at: 2 * index + 1)
        }
        
        setToolbarItems(itemTypes.map {
            barButtonItemType -> UIBarButtonItem in
            if let barButtonItem = barButtonItemMapping[barButtonItemType] {
                return barButtonItem
            }
            return UIBarButtonItem()
        }, animated: true)
        
        if let tintColor = tintColor {
            navigationController?.toolbar.tintColor = tintColor
        }
    }
    
    @objc func backDidClick(sender: AnyObject) {
        webView.goBack()
    }
    
    @objc func forwardDidClick(sender: AnyObject) {
        webView.goForward()
    }
    
    @objc func reloadDidClick(sender: AnyObject) {
        webView.stopLoading()
        webView.reload()
    }
    
    @objc func activityDidClick(sender: AnyObject) {
        guard let url = url else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
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
