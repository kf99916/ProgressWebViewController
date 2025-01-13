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
let titleKeyPath = "title"
let cookieKey = "Cookie"

@objc public protocol ProgressWebViewControllerDelegate {
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, canDismiss url: URL) -> Bool
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, didStart url: URL)
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, didFinish url: URL)
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, didFail url: URL, withError error: Error)
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, decidePolicy url: URL, navigationType: NavigationType) -> Bool
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, decidePolicy url: URL, response: URLResponse) -> Bool
    @objc optional func progressWebViewController(_ controller: ProgressWebViewController, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView?
    @objc optional func initPushedProgressWebViewController(defaultURL: URL) -> ProgressWebViewController
}

@objc public protocol ProgressWebViewControllerScrollViewDelegate {
    @objc optional func scrollViewDidScroll(_ scrollView: UIScrollView)
}

open class ProgressWebViewController: UIViewController {
    
    static let processPool = WKProcessPool()
    
    @available(*, unavailable, renamed: "defaultURL")
    open var url: URL? { return defaultURL }
    
    open var defaultURL: URL?
    open var bypassedSSLHosts: [String]?
    open var userAgent: String?
    open var disableZoom = false
    open var navigationWay = NavigationWay.browser
    open var pullToRefresh = false
    open var urlsHandledByApp = [
        "hosts": ["itunes.apple.com"],
        "schemes": ["tel", "mailto", "sms"],
        "_blank": true
        ] as [String : Any]
    
    open var websiteDataStore: WKWebsiteDataStore = WKWebsiteDataStore.default()
    
    @available(iOS, obsoleted: 1.12.0, renamed: "defaultHeaders")
    open var headers: [String: String]? { return defaultHeaders }
    
    open var defaultHeaders: [String: String]? {
        didSet {
            var shouldReload = (defaultHeaders != nil && oldValue == nil) || (defaultHeaders == nil && oldValue != nil)
            if let defaultHeaders = defaultHeaders, let oldValue = oldValue, defaultHeaders != oldValue {
                shouldReload = true
            }
            if shouldReload {
                reload()
            }
        }
    }
    
    open var isScrollEnabled = true {
        didSet {
            webView?.scrollView.isScrollEnabled = isScrollEnabled
        }
    }
    
    open var currentURL: URL? {
        return webView?.url
    }
    
    weak open var delegate: ProgressWebViewControllerDelegate?
    weak open var scrollViewDelegate: ProgressWebViewControllerScrollViewDelegate?
    
    open var tintColor: UIColor?
    open var websiteTitleInNavigationBar = true
    open var doneBarButtonItemPosition: NavigationBarPosition = .right
    open var leftNavigaionBarItemTypes: [BarButtonItemType] = []
    open var rightNavigaionBarItemTypes: [BarButtonItemType] = []
    open var toolbarItemTypes: [BarButtonItemType] = [.back, .forward, .reload, .activity]
    
    fileprivate var webView: WKWebView?
    
    fileprivate var previousNavigationBarState: (tintColor: UIColor, hidden: Bool)? = nil
    fileprivate var previousToolbarState: (tintColor: UIColor, hidden: Bool)? = nil
    
    fileprivate var scrollToRefresh = false
    fileprivate var lastTapPosition = CGPoint(x: 0, y: 0)
    fileprivate var isReloadWhenAppear = false
    fileprivate var actionPolicy: WKNavigationActionPolicy = .allow
    fileprivate var estimatedProgress = 0.0 {
        didSet {
            if currentNavigationController?.isNavigationBarHidden ?? true, activityIndicatorView.isDescendant(of: view) {
                if estimatedProgress >= 1.0 {
                    activityIndicatorView.stopAnimating()
                } else {
                    activityIndicatorView.startAnimating()
                }
            }
            else if let navigationItem = currentNavigationController?.navigationBar, progressView.isDescendant(of: navigationItem) {
                progressView.alpha = 1
                progressView.setProgress(Float(estimatedProgress), animated: true)
                
                if estimatedProgress >= 1.0 {
                    UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: {
                        self.progressView.alpha = 0
                    }, completion: {
                        finished in
                        self.progressView.setProgress(0, animated: false)
                    })
                }
            }
        }
    }
    
    lazy fileprivate var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.alpha = 1
        progressView.trackTintColor = UIColor(white: 1, alpha: 0)
        return progressView
    }()
    
    lazy fileprivate var activityIndicatorView: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let activityIndicatorView = UIActivityIndicatorView(style: .medium)
            activityIndicatorView.color = tintColor ?? .label
            return activityIndicatorView
        } else {
            let activityIndicatorView = UIActivityIndicatorView(style: .gray)
            activityIndicatorView.color = tintColor ?? .darkText
            return activityIndicatorView
        }
    }()
    
    lazy fileprivate var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(sender:)), for: UIControl.Event.valueChanged)
        webView?.scrollView.addSubview(refreshControl)
        webView?.scrollView.bounces = true
        return refreshControl
    }()

    lazy fileprivate var backBarButtonItem: UIBarButtonItem = {
        let bundle = Bundle(for: ProgressWebViewController.self)
        return UIBarButtonItem(image: UIImage(named: "Back", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(backDidClick(sender:)))
    }()
    
    lazy fileprivate var forwardBarButtonItem: UIBarButtonItem = {
        let bundle = Bundle(for: ProgressWebViewController.self)
        return UIBarButtonItem(image: UIImage(named: "Forward", in: bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(forwardDidClick(sender:)))
    }()
    
    lazy fileprivate var reloadBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadDidClick(sender:)))
    }()
    
    lazy fileprivate var stopBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(stopDidClick(sender:)))
    }()
    
    lazy fileprivate var activityBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(activityDidClick(sender:)))
    }()
    
    lazy fileprivate var doneBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDidClick(sender:)))
    }()
    
    lazy fileprivate var flexibleSpaceBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()
    
    public convenience init(_ progressWebViewController: ProgressWebViewController) {
        self.init()
        self.websiteDataStore = progressWebViewController.websiteDataStore
        self.bypassedSSLHosts = progressWebViewController.bypassedSSLHosts
        self.userAgent = progressWebViewController.userAgent
        self.disableZoom = progressWebViewController.disableZoom
        self.navigationWay = progressWebViewController.navigationWay
        self.pullToRefresh = progressWebViewController.pullToRefresh
        self.urlsHandledByApp = progressWebViewController.urlsHandledByApp
        self.defaultHeaders = progressWebViewController.defaultHeaders
        self.tintColor = progressWebViewController.tintColor
        self.websiteTitleInNavigationBar = progressWebViewController.websiteTitleInNavigationBar
        self.doneBarButtonItemPosition = progressWebViewController.doneBarButtonItemPosition
        self.leftNavigaionBarItemTypes = progressWebViewController.leftNavigaionBarItemTypes
        self.rightNavigaionBarItemTypes = progressWebViewController.rightNavigaionBarItemTypes
        self.toolbarItemTypes = progressWebViewController.toolbarItemTypes
        self.delegate = progressWebViewController.delegate
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: estimatedProgressKeyPath)
        webView?.removeObserver(self, forKeyPath: titleKeyPath)

        webView?.uiDelegate = nil
        webView?.navigationDelegate = nil
        webView?.scrollView.delegate = nil
    }
    
    override open func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.websiteDataStore = websiteDataStore
        webConfiguration.processPool = ProgressWebViewController.processPool
        let webView = createWebView(webConfiguration: webConfiguration)

        view = webView
        self.webView = webView
#if DEBUG
        if #available(iOS 16.4, *) {
            self.webView?.isInspectable = true
        }
#endif
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = navigationItem.title ?? defaultURL?.absoluteString
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(webViewDidTap(sender:)))
        tapGesture.delegate = self
        webView?.addGestureRecognizer(tapGesture)

        updateProgressViewFrame()
        addBarButtonItems()
        
        if let userAgent = userAgent {
            webView?.evaluateJavaScript("navigator.userAgent") { [weak self] result, error in
                guard let weakSelf = self else {
                    return
                }
                
                defer {
                    if let url = weakSelf.defaultURL {
                        weakSelf.load(url)
                    }
                }
                
                guard error == nil, let originalUserAgent = result as? String else {
                    weakSelf.webView?.customUserAgent = userAgent
                    return
                }
                
                weakSelf.webView?.customUserAgent = String(format: "%@ %@", originalUserAgent, userAgent)
            }
        }
        else if let url = defaultURL {
            load(url)
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setUpState()
        if isReloadWhenAppear {
            reload()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if estimatedProgress < 1 {
            isReloadWhenAppear = actionPolicy == .allow
            if isReloadWhenAppear {
                webView?.stopLoading()
            }
        }
        rollbackState(animated)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case estimatedProgressKeyPath?:
            guard let estimatedProgress = webView?.estimatedProgress else {
                return
            }
            self.estimatedProgress = estimatedProgress
        case titleKeyPath?:
            if websiteTitleInNavigationBar || URL(string: navigationItem.title ?? "")?.appendingPathComponent("") == currentURL?.appendingPathComponent("") {
                navigationItem.title = webView?.title
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // Reference: https://medium.com/swlh/popover-menu-over-cards-containing-webkit-views-on-ios-13-a16705aff8af
    // https://stackoverflow.com/questions/58164583/wkwebview-with-the-new-ios13-modal-crash-when-a-file-picker-is-invoked
    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
      setUIDocumentMenuViewControllerSoureViewsIfNeeded(viewControllerToPresent)
      super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    override open func targetViewController(forAction action: Selector, sender: Any?) -> UIViewController? {
        switch navigationWay {
        case .browser:
            return currentNavigationController
        case .push(let targetViewController):
            return targetViewController ?? currentNavigationController
        }
    }
}

// MARK: - Public Methods
public extension ProgressWebViewController {
    func load(_ url: URL) {
        isReloadWhenAppear = false
        if isViewLoaded {
            let request = createRequest(url: url)
            DispatchQueue.main.async {
                self.webView?.stopLoading()
                self.webView?.load(request)
            }
        }
        else {
            defaultURL = url
        }
    }
    
    func load(htmlString: String, baseURL: URL?) {
        isReloadWhenAppear = false
        DispatchQueue.main.async {
            self.webView?.stopLoading()
            self.webView?.loadHTMLString(htmlString, baseURL: baseURL)
        }
    }
    
    func goBackToFirstPage() {
        if let firstPageItem = webView?.backForwardList.backList.first {
            webView?.go(to: firstPageItem)
        }
    }
    
    func scrollToTop(animated: Bool, refresh: Bool = false) {
        guard isScrollEnabled else {
            if refresh {
                refreshWebView(sender: refreshControl)
            }
            return
        }
        
        var offsetY: CGFloat = 0
        if let currentNavigationController = currentNavigationController {
            offsetY -= currentNavigationController.navigationBar.frame.size.height + (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)
        }
        if refresh, pullToRefresh {
            offsetY -= refreshControl.frame.size.height
        }

        scrollToRefresh = refresh
        webView?.scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: animated)
    }
    
    func isScrollToTop() -> Bool {
        guard isScrollEnabled else {
            return true
        }
        guard let scrollView = webView?.scrollView else {
            return false
        }
        return scrollView.contentOffset.y <= CGFloat(0)
    }
    
    func clearCache(completionHandler: @escaping () -> Void) {
        var websiteDataTypes = Set<String>([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeOfflineWebApplicationCache])
        if #available(iOS 11.3, *) {
            websiteDataTypes.insert(WKWebsiteDataTypeFetchCache)
        }
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: completionHandler)
    }
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        webView?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    func loadBlankPage() {
        guard let url = URL(string:"about:blank") else {
            return
        }
        load(url)
    }
    
    func setUIDocumentMenuViewControllerSoureViewsIfNeeded(_ viewControllerToPresent: UIViewController) {
        viewControllerToPresent.popoverPresentationController?.sourceView = view
        if lastTapPosition == .zero {
            lastTapPosition = view.center
        }
        viewControllerToPresent.popoverPresentationController?.sourceRect = CGRect(origin: lastTapPosition, size: CGSize(width: 0, height: 0))
    }
    
    func reload() {
        webView?.stopLoading()
        isReloadWhenAppear = false
        if let url = currentURL, !isBlank(url:url) {
            webView?.reload()
        }
        else if let url = defaultURL {
            load(url)
        }
    }
    
    func updateHttpCookies(cookies: [HTTPCookie]) async {
        let currentCookies = await webView?.configuration.websiteDataStore.httpCookieStore.allCookies()
        var shouldReload = false
        for cookie in cookies {
            if !(currentCookies?.contains(cookie) ?? false) {
                shouldReload = true
                await webView?.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        if shouldReload {
            reload()
        }
    }
    
    func pushWebViewController(defaultURL: URL) {
        let progressWebViewController = delegate?.initPushedProgressWebViewController?(defaultURL: defaultURL) ?? ProgressWebViewController(self)
        progressWebViewController.defaultURL = defaultURL
        currentNavigationController?.show(progressWebViewController, sender: self)
        setUpState()
    }
    
    @available(*, unavailable, renamed: "pushWebViewController(defaultURL:)")
    func pushWebViewController(url: URL) {  }
}

// MARK: - Fileprivate Methods
fileprivate extension ProgressWebViewController {
    var currentNavigationController: UINavigationController? {
        return navigationController ?? parent?.navigationController ?? parent?.presentingViewController?.navigationController ?? UIViewController.currentNavigationController
    }
    
    func createWebView(webConfiguration: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        if #available(iOS 13.0, *) {
            webView.backgroundColor = .systemBackground
        }
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        
        webView.allowsBackForwardNavigationGestures = true
        webView.isMultipleTouchEnabled = true
        
        webView.addObserver(self, forKeyPath: estimatedProgressKeyPath, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: titleKeyPath, options: .new, context: nil)
        
        webView.scrollView.isScrollEnabled = isScrollEnabled
        return webView
    }
    
    func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        // Set up Headers
        if let defaultHeaders = defaultHeaders {
            for (field, value) in defaultHeaders {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }
        return request
    }
    
    func updateProgressViewFrame() {
        guard let navigationBar = currentNavigationController?.navigationBar, progressView.isDescendant(of: navigationBar) else {
            return
        }
        progressView.frame = CGRect(x: 0, y: navigationBar.frame.size.height - progressView.frame.size.height, width: navigationBar.frame.size.width, height: progressView.frame.size.height)
    }
    
    func addBarButtonItems() {
        let barButtonItems: [BarButtonItemType: UIBarButtonItem] = [
            .back: backBarButtonItem,
            .forward: forwardBarButtonItem,
            .reload: reloadBarButtonItem,
            .stop: stopBarButtonItem,
            .activity: activityBarButtonItem,
            .done: doneBarButtonItem,
            .flexibleSpace: flexibleSpaceBarButtonItem
        ]
        
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
        
        navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems ?? [] + leftNavigaionBarItemTypes.map {
            barButtonItemType in
            if let barButtonItem = barButtonItems[barButtonItemType] {
                return barButtonItem
            }
            return UIBarButtonItem()
        }
        
        navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems ?? [] + rightNavigaionBarItemTypes.map {
            barButtonItemType in
            if let barButtonItem = barButtonItems[barButtonItemType] {
                return barButtonItem
            }
            return UIBarButtonItem()
        }
        
        if toolbarItemTypes.count > 0 {
            for index in 0..<toolbarItemTypes.count - 1 {
                toolbarItemTypes.insert(.flexibleSpace, at: 2 * index + 1)
            }
        }
        
        setToolbarItems(toolbarItemTypes.map {
            barButtonItemType -> UIBarButtonItem in
            if let barButtonItem = barButtonItems[barButtonItemType] {
                return barButtonItem
            }
            return UIBarButtonItem()
        }, animated: true)
    }
    
    func updateBarButtonItems() {
        backBarButtonItem.isEnabled = webView?.canGoBack ?? false
        forwardBarButtonItem.isEnabled = webView?.canGoForward ?? false
        
        let updateReloadBarButtonItem: (UIBarButtonItem, Bool) -> UIBarButtonItem = {
            [weak self] barButtonItem, isLoading in
            guard let weakSelf = self else {
                return barButtonItem
            }
            switch barButtonItem {
            case weakSelf.reloadBarButtonItem:
                fallthrough
            case weakSelf.stopBarButtonItem:
                    return isLoading ? weakSelf.stopBarButtonItem : weakSelf.reloadBarButtonItem
            default:
                break
            }
            return barButtonItem
        }
        
        let isLoading = webView?.isLoading ?? false
        toolbarItems = toolbarItems?.map {
            barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
        
        navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems?.map {
            barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
        
        navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems?.map {
            barButtonItem -> UIBarButtonItem in
            return updateReloadBarButtonItem(barButtonItem, isLoading)
        }
    }
    
    func setUpState() {
        if let tintColor = tintColor {
            progressView.progressTintColor = tintColor
            currentNavigationController?.navigationBar.tintColor = tintColor
            currentNavigationController?.toolbar.tintColor = tintColor
        }
        
        if currentNavigationController?.isNavigationBarHidden ?? true, !activityIndicatorView.isDescendant(of: view) {
            activityIndicatorView.center = view.center
            view.addSubview(activityIndicatorView)
            activityIndicatorView.startAnimating()
        }
        else if let navigationBar = currentNavigationController?.navigationBar, !progressView.isDescendant(of: navigationBar) {
            navigationBar.addSubview(progressView)
        }
        
        if let currentNavigationController = currentNavigationController {
            previousNavigationBarState = (currentNavigationController.navigationBar.tintColor, currentNavigationController.navigationBar.isHidden)
            previousToolbarState = (currentNavigationController.toolbar.tintColor, currentNavigationController.toolbar.isHidden)
        }
    }
    
    func rollbackState(_ animated: Bool) {
        progressView.removeFromSuperview()
    
        if let previousNavigationBarState = previousNavigationBarState {
            currentNavigationController?.navigationBar.tintColor = previousNavigationBarState.tintColor
            currentNavigationController?.setNavigationBarHidden(previousNavigationBarState.hidden, animated: animated)
        }
        if let previousToolbarState = previousToolbarState {
            currentNavigationController?.toolbar.tintColor = previousToolbarState.tintColor
            currentNavigationController?.setToolbarHidden(previousToolbarState.hidden, animated: animated)
        }
    }
    
    func openURLWithApp(_ url: URL) -> Bool {
        let application = UIApplication.shared
        if application.canOpenURL(url) {
            application.open(url)
            return true
        }
        
        return false
    }
    
    func handleURLWithApp(_ url: URL, targetFrame: WKFrameInfo?) -> Bool {
        let hosts = urlsHandledByApp["hosts"] as? [String]
        let schemes = urlsHandledByApp["schemes"] as? [String]
        let blank = urlsHandledByApp["_blank"] as? Bool
        
        var tryToOpenURLWithApp = false
        if let host = url.host, hosts?.contains(host) ?? false {
            tryToOpenURLWithApp = true
        }
        if let scheme = url.scheme, schemes?.contains(scheme) ?? false {
            tryToOpenURLWithApp = true
        }
        if blank ?? false && targetFrame == nil {
            tryToOpenURLWithApp = true
        }
        
        return tryToOpenURLWithApp ? openURLWithApp(url) : false
    }
    
    func isBlank(url: URL) -> Bool {
        return url.absoluteString == "about:blank"
    }
}

// MARK: - WKUIDelegate
extension ProgressWebViewController: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let createWebViewWithConfiguartion = delegate?.progressWebViewController(_:createWebViewWith:for:windowFeatures:) {
            return createWebViewWithConfiguartion(self, configuration, navigationAction, windowFeatures)
        }
        else if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        })
        alertController.addAction(cancelAction)
        alertController.preferredAction = cancelAction
        
        present(alertController, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }

        })
        alertController.addAction(okAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        alertController.preferredAction = okAction

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate
extension ProgressWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateBarButtonItems()
        updateProgressViewFrame()
        if let url = webView.url ?? defaultURL {
            delegate?.progressWebViewController?(self, didStart: url)
        }
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBarButtonItems()
        updateProgressViewFrame()
        if pullToRefresh {
            refreshControl.endRefreshing()
        }
        if let url = webView.url ?? defaultURL {
            delegate?.progressWebViewController?(self, didFinish: url)
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateBarButtonItems()
        updateProgressViewFrame()
        if pullToRefresh {
            refreshControl.endRefreshing()
        }
        if let url = webView.url ?? defaultURL {
            delegate?.progressWebViewController?(self, didFail: url, withError: error)
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateBarButtonItems()
        updateProgressViewFrame()
        if pullToRefresh {
            refreshControl.endRefreshing()
        }
        if let url = webView.url ?? defaultURL {
            delegate?.progressWebViewController?(self, didFail: url, withError: error)
        }
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let bypassedSSLHosts = bypassedSSLHosts, bypassedSSLHosts.contains(challenge.protectionSpace.host) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        actionPolicy = .allow
        defer {
            decisionHandler(actionPolicy)
        }
        guard let url = navigationAction.request.url, !url.isFileURL else {
            return
        }
        
        if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
            return
        }
   
        if handleURLWithApp(url, targetFrame: navigationAction.targetFrame) {
            actionPolicy = .cancel
            return
        }
        
        if let navigationType = NavigationType(rawValue: navigationAction.navigationType.rawValue), let result = delegate?.progressWebViewController?(self, decidePolicy: url, navigationType: navigationType) {
            actionPolicy = result ? .allow : .cancel
            if actionPolicy == .cancel {
                return
            }
        }
        
        switch navigationAction.navigationType {
        case .linkActivated:
            if let fragment = url.fragment {
                let removedFramgnetURL = URL(string: url.absoluteString.replacingOccurrences(of: "#\(fragment)", with: ""))
                var currentURL = currentURL
                if let currentFragment = currentURL?.fragment {
                    currentURL = URL(string: url.absoluteString.replacingOccurrences(of: "#\(currentFragment)", with: ""))
                }
                if removedFramgnetURL == currentURL {
                    return
                }
            }
            if case .push = navigationWay {
                pushWebViewController(defaultURL: url)
                actionPolicy = .cancel
                return
            }
            if navigationAction.targetFrame == nil {
                pushWebViewController(defaultURL: url)
                actionPolicy = .cancel
            }
        default:
            break
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        var responsePolicy: WKNavigationResponsePolicy = .allow
        defer {
            decisionHandler(responsePolicy)
        }
        guard let url = navigationResponse.response.url, !url.isFileURL else {
            return
        }
        
        if let result = delegate?.progressWebViewController?(self, decidePolicy: url, response: navigationResponse.response) {
            responsePolicy = result ? .allow : .cancel
        }
        
        if case .push = navigationWay, responsePolicy == .cancel, let webViewController = currentNavigationController?.topViewController as? ProgressWebViewController, webViewController.currentURL?.appendingPathComponent("") == url.appendingPathComponent("") {
            currentNavigationController?.popViewController(animated: true)
        }
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if viewIfLoaded?.window != nil {
            reload()
        }
        else {
            isReloadWhenAppear = true
        }
    }
}

extension ProgressWebViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return disableZoom ? nil : scrollView.subviews[0]
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if scrollToRefresh, pullToRefresh {
            refreshWebView(sender: refreshControl)
        }
        scrollToRefresh = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
}

extension ProgressWebViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - @objc
@objc extension ProgressWebViewController {
    func backDidClick(sender: AnyObject) {
        webView?.goBack()
    }
    
    func forwardDidClick(sender: AnyObject) {
        webView?.goForward()
    }
    
    func reloadDidClick(sender: AnyObject) {
        reload()
    }
    
    func stopDidClick(sender: AnyObject) {
        webView?.stopLoading()
    }
    
    func activityDidClick(sender: AnyObject) {
        guard let url = currentURL else {
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    func doneDidClick(sender: AnyObject) {
        var canDismiss = true
        if let url = currentURL {
            canDismiss = delegate?.progressWebViewController?(self, canDismiss: url) ?? true
        }
        if canDismiss {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func refreshWebView(sender: UIRefreshControl) {
        let isLoading = webView?.isLoading ?? false
        if !isLoading {
            sender.beginRefreshing()
            reloadDidClick(sender: sender)
        }
    }
    
    func webViewDidTap(sender: UITapGestureRecognizer) {
      lastTapPosition = sender.location(in: view)
    }
}
