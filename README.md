# ProgressWebViewController

A WebViewController implemented by WKWebView with a progress bar in the navigation bar. The WebViewController is safari-like web browser.

[![CocoaPods](https://img.shields.io/cocoapods/dt/ProgressWebViewController.svg)](https://cocoapods.org/pods/ProgressWebViewController)
[![GitHub stars](https://img.shields.io/github/stars/kf99916/ProgressWebViewController.svg)](https://github.com/kf99916/ProgressWebViewController/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/kf99916/ProgressWebViewController.svg)](https://github.com/kf99916/ProgressWebViewController/network)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ProgressWebViewController.svg)](https://cocoapods.org/pods/ProgressWebViewController)
[![Platform](https://img.shields.io/cocoapods/p/ProgressWebViewController.svg)](https://github.com/kf99916/ProgressWebViewController)
[![GitHub license](https://img.shields.io/github/license/kf99916/ProgressWebViewController.svg)](https://github.com/kf99916/ProgressWebViewController/blob/master/LICENSE)

![ProgressWebViewController](/screenshots/progressWebViewController.png "ProgressWebViewController") ![ProgressWebViewController](/screenshots/progressWebViewController2.png "ProgressWebViewController")

## Features

* :white_check_mark: Progress bar in navigation bar
* :white_check_mark: Bypass SSL according to the assigned hosts.( i.e., you can access the self-signed certificate websites with ProgressWebViewController)
* :white_check_mark: Customize bar button items
* :white_check_mark: Assign cookies to the web view
* :white_check_mark: Browse the local html files
* :white_check_mark: Support large titles for navigation bars in iOS 11
* :white_check_mark: Support custom headers
* :white_check_mark: Support custom user agent
* :white_check_mark: Open the special urls including the app store, tel, mailto, sms, and _blank with other apps

## Requirements

* iOS 9.0 or higher
* Swift 4.0 or higher

## Installation

```ruby
pod "ProgressWebViewController"
```

## Usage

### Import

```swift
import ProgressWebViewController
```

### Integration

### ProgressWebViewController

A view controller with WKWebView and a progress bar in the navigation bar

`var url: URL?` the url to request  
`var tintColor: UIColor?` the tint color for the progress bar, navigation bar, and tool bar  
`var delegate: ProgressWebViewControllerDelegate?` the delegate for ProgressWebViewController  
`var bypassedSSLHosts: [String]?` the bypassed SSL hosts. The hosts must also be disabled in the App Transport Security.  
`var cookies: [HTTPCookie]?` the assigned cookies   
`var headers: [String: String]?` the custom headers   
`var userAgent: String?` the custom user agent    
`var urlsHandledByApp: [String: Any]` configure the urls handled by other apps (default `[
        "hosts": ["itunes.apple.com"],
        "schemes": ["tel", "mailto", "sms"],
        "_blank": true
        ]`)   
`var websiteTitleInNavigationBar = true` show the website title in the navigation bar  
`var doneBarButtonItemPosition: NavigationBarPosition` the position for the done bar button item. the done barbutton item is added automatically if the view controller is presented.(default `.left`)  
`var leftNavigaionBarItemTypes: [BarButtonItemType]` configure the bar button items in the left navigation bar (default `[]`)  
`var rightNavigaionBarItemTypes: [BarButtonItemType]` configure the bar button items in the right navigation bar (default `[]`)  
`var toolbarItemTypes: [BarButtonItemType]` configure the bar button items in the toolbar of navigation controller (default `[.back, .forward, .reload, .activity]`)

#### Subclassing

You should set up the webview in `loadView()` and set up others in `viewDidLoad()`

```swift
class MyWebViewController: ProgressWebViewController {
    override open func loadView() {
        super.loadView()
        
        // set up webview, including cookies, headers, user agent, and so on.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // Other methods
}
```

### ProgressWebViewControllerDelegate

The delegate for ProgressWebViwController

`optional func progressWebViewController(_ controller: ProgressWebViewController, canDismiss url: URL) -> Bool`  
`optional func progressWebViewController(_ controller: ProgressWebViewController, didStart url: URL)`  
`optional func progressWebViewController(_ controller: ProgressWebViewController, didFinish url: URL)`  
`optional func progressWebViewController(_ controller: ProgressWebViewController, didFail url: URL, withError error: Error)`  
`optional func progressWebViewController(_ controller: ProgressWebViewController, decidePolicy url: URL) -> Bool`

### BarButtonItemType

The enum for bar button item

```swift
enum BarButtonItemType {
    case back
    case forward
    case reload
    case stop
    case activity
    case done
    case flexibleSpace
}
```

### NavigationBarPosition

The enum for position of bar button item in the navigation bar

```swift
enum NavigationBarPosition {
    case none
    case left
    case right
}
```

## Apps using ProgressWebViewController

If you are using ProgressWebViewController in your app and want to be listed here, simply create a pull request.

I am always curious who is using my projects :)

[Hikingbook](https://itunes.apple.com/app/id1067838748) - by Zheng-Xiang Ke

![Hikingbook](apps/Hikingbook.png)

## Demo

ProgressWebViewControllerDemo is a simple demo app which browse the Apple website with ProgressWebViewController.

## Author

Zheng-Xiang Ke, kf99916@gmail.com

## License

ProgressWebViewController is available under the MIT license. See the LICENSE file for more info.
