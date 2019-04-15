# Changelog

## Version 1.8

- Migrate to Xcode 10.2 and Swift 5.
- Support the push navigation way.
- Support pull-to-refresh to reload the web view.

## Version 1.7

- Add delegate: progressWebViewController(controller:decidePolicy:response:).
- Add disable zoom configuration.
- Support iFrame.
- Fix the issue: reload a url when a user tries to go back because the cookies in the header are not taken.

## Version 1.6.1

- Ensure all available cookies are set in the navigation request.

## Version 1.6.0

- Reload url if cookies or headers are changed.
- Ensure the web view loads a url in the main thread.

## Version 1.5.1

- Fix the issue: load the url infinitely if there is no any required cookies and request's cookies.

## Version 1.5.0

- Open the special urls including the app store, tel, mailto, sms, and \_blank with other apps.

## Version 1.4.0

- Support custom headers.
- Support custom user agent.

## Version 1.3.1

- Support large titles for navigation bars in iOS 11.

## Version 1.3.0

- Let webView and progressView be optional.

## Version 1.2.0

- Browse the local html files.
- Change the default done bar button position.

## Version 1.1.0

- Assign cookies to the web view.
- Fix warnings about layout constraints in the demo project.

## Version 1.0.1

- Fix a crash if the toolbarItemTypes is empty.
- Update ProgressWebViewControllerDelegate.
- Correct url passed to the delegate.
- Ensure web view's url exist.

## Version 1.0.0

Initial version

- Progress bar in navigation bar.
- Bypass SSL according to the assigned hosts.
- Customize bar button items.
