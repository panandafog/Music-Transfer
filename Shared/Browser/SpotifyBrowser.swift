//
//  SpotifyBrowser.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI
import WebKit
import Combine

public final class SpotifyBrowser: APIBrowser {
    
    var url: URL? = nil
    
    private let webView: WKWebView = WKWebView()
    
    public func load() {
        guard let url = self.url else {
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    init(url: URL?) {
        self.url = url
    }
    
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        
        var parent: SpotifyBrowser
        private let spotifyFacade = SpotifyFacade.shared
        
        init(parent: SpotifyBrowser) {
            self.parent = parent
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) {
        }
        
        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        }
        
        public func webView(_: WKWebView, didFinish: WKNavigation!) {
        }
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        }
        
        public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            
            guard let url = navigationResponse.response.url else {
                return
            }
            
            let currentUrlComponents = URLComponents(string: url.absoluteString)
            let redirectUrlComponents = URLComponents(string: SpotifyFacade.authorizationRedirectUrl)
            
            if currentUrlComponents?.host == redirectUrlComponents?.host {
                let queryItems = currentUrlComponents?.queryItems
                
                let code = queryItems?.filter({$0.name == "code"}).first
                let error = queryItems?.filter({$0.name == "error"}).first
                let state = queryItems?.filter({$0.name == "state"}).first
                
                guard state?.value == SpotifyFacade.state else {
                    return
                }
                
                guard error?.value == nil else {
                    return
                }
                
                guard let codeValue = code?.value else {
                    return
                }
                
                spotifyFacade.isAuthorised = true
                spotifyFacade.requestTokens(code: codeValue)
                
                decisionHandler(.cancel)
                #if os(macOS)
                let browserDelegate = BrowserViewDelegate.shared
                browserDelegate.closeBrowser()
                #else
                parent.shouldDismissView = true
                #endif
                
            } else {
                decisionHandler(.allow)
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
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
