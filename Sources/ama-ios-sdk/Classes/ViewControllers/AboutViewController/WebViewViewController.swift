//
//  WebViewViewController.swift
//  Copyright © 2018 iGrant.com. All rights reserved.
//

import UIKit
import WebKit
import SVProgressHUD

protocol WebViewRedirectDelegate: AnyObject {
    func handleRedirectURL(_ url: URL)
    func webViewDidDismiss(dismissed: Bool)
}

extension WebViewRedirectDelegate where Self: AnyObject {
    func webViewDidDismiss(dismissed: Bool) {}
}
 
enum OriginatingFrom {
    case DataPods
    case Other
    case DataAgreement
}

class WebViewViewController: AriesBaseViewController , WKNavigationDelegate, WKUIDelegate {
    @IBOutlet weak var webview : WKWebView!
    var urlString  = ""
    var redirectUrl = ""
    var redirectDelegate: WebViewRedirectDelegate?
    var originatingFrom: OriginatingFrom = .Other
    var isBeingDismissedFromDataPodsAfterLogin: Bool = false
    var completionHandler: ((Bool) -> Void)?
    var isDismissedManually: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        clearWebViewCache()
        webview.navigationDelegate = self
        webview.uiDelegate = self
        self.navigationController?.navigationBar.isHidden = false
        if let url =  URL.init(string: urlString){
            webview.load(URLRequest.init(url: url))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        if originatingFrom == .DataPods && !isBeingDismissedFromDataPodsAfterLogin {
            completionHandler?(false)
            UIApplicationUtils.hideLoader()
        } else if originatingFrom == .DataPods && isBeingDismissedFromDataPodsAfterLogin {
            completionHandler?(true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func clearWebViewCache() {
        // Create a data store configuration
        let configuration = WKWebViewConfiguration()
        let dataStore = configuration.websiteDataStore
        
        // Specify the types of data to remove (including cache)
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        
        // Remove the cache data
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: date) {
            debugPrint("Cache cleared successfully")
        }
    }
    
    //Equivalent of webViewDidFinishLoad:
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish - webView.url: \(String(describing: webView.url?.description))")
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if let redirectDelegate = redirectDelegate, urlIsRedirectURL(url) {
            redirectDelegate.handleRedirectURL(url)
            if originatingFrom == .DataPods {
                isBeingDismissedFromDataPodsAfterLogin = true
            }
            dismiss(animated: true, completion: nil)
            decisionHandler(.cancel)
        } else {
            //completionHandler?(false)
            if originatingFrom == .DataPods {
                isBeingDismissedFromDataPodsAfterLogin = false
            }
            decisionHandler(.allow)
        }
    }
    
    //Equivalent of didFailLoadWithError:
       func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
           let nserror = error as NSError
           UIApplicationUtils.hideLoader()
           if nserror.code != NSURLErrorCancelled {
               webView.loadHTMLString("Page Not Found", baseURL: URL(string: "https://developer.apple.com/"))
           }
       }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        debugPrint("didFailProvisionalNavigation:\(error)")
    }
    
    private func urlIsRedirectURL(_ url: URL) -> Bool {
        guard let redirectURL = URL(string: redirectUrl), let urlScheme = url.scheme,
                  let urlHost = url.host,
                  let redirectScheme = redirectURL.scheme,
                  let redirectHost = redirectURL.host
            else {
                return false
            }
            return urlScheme == redirectScheme && urlHost == redirectHost
    }
    
}
