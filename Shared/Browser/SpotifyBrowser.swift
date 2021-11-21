//
//  SpotifyBrowser.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Combine
import SwiftUI
import WebKit

public final class SpotifyBrowser: APIBrowser {
    
    var url: URL?
    let service: SpotifyService
    
    private let webView = WKWebView()
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    init(url: URL?, service: SpotifyService) {
        self.url = url
        self.service = service
    }
    
    public func load() {
        guard let url = self.url else {
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(browser: self, service: service)
    }
}

public extension SpotifyBrowser {
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let browser: SpotifyBrowser
        let service: SpotifyService
        
        init(browser: SpotifyBrowser, service: SpotifyService) {
            self.browser = browser
            self.service = service
        }
        
        public func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            
            guard let url = navigationResponse.response.url else {
                return
            }
            
            let currentUrlComponents = URLComponents(string: url.absoluteString)
            let redirectUrlComponents = URLComponents(string: SpotifyService.authorizationRedirectUrl)
            
            if currentUrlComponents?.host == redirectUrlComponents?.host {
                let queryItems = currentUrlComponents?.queryItems
                
                let code = queryItems?.first { $0.name == "code" }
                let error = queryItems?.first { $0.name == "error" }
                let state = queryItems?.first { $0.name == "state" }
                
                guard state?.value == SpotifyService.state else {
                    return
                }
                
                guard error?.value == nil else {
                    return
                }
                
                guard let codeValue = code?.value else {
                    return
                }
                
                service.requestTokens(code: codeValue)
                
                decisionHandler(.cancel)
                browser.shouldDismissView = true
                
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

#if os(macOS)
extension SpotifyBrowser: NSViewRepresentable {
    
    public typealias NSViewType = WKWebView
    
    public func makeNSView(context: NSViewRepresentableContext<SpotifyBrowser>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }
    
    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SpotifyBrowser>) {
        guard let url = self.url else {
            return
        }
        nsView.load(URLRequest(url: url))
    }
}
#else
extension SpotifyBrowser: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    
    public func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = self.url else {
            return
        }
        uiView.load(URLRequest(url: url))
    }
}
#endif
