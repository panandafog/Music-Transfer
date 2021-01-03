//
//  SpotifyBrowser.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI
import WebKit

public struct SpotifyBrowser: APIBrowser {

    let url: URL?

    private let webView: WKWebView = WKWebView()

    public func load() {
        guard let url = self.url else {
            return
        }
        webView.load(URLRequest(url: url))
    }

    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {

        var parent: SpotifyBrowser
        private let spotifyFacade = SpotifyFacade.shared

        init(parent: SpotifyBrowser) {
            self.parent = parent
        }

        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) {
                        print("fail 1")
        }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
                        print("fail 2")
        }

        public func webView(_: WKWebView, didFinish: WKNavigation!) {
                        print("finish")
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
                       print(4)
        }

        public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

            print("redirect")

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

                if state?.value != SpotifyFacade.state {
                    print("incorrect state")
                    return
                }

                if error?.value != nil {
                    print("error: ")
                    print(error?.value)
                    return
                }

                if code?.value == nil {
                    print("no code")
                    return
                }

                guard let codeValue = code?.value else {
                    return
                }

                spotifyFacade.isAuthorised = true
                spotifyFacade.requestTokens(code: codeValue)

                decisionHandler(.cancel)
                let browserDelegate = BrowserViewDelegate.shared
                browserDelegate.closeBrowser()
                
            } else {
                decisionHandler(.allow)
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

extension SpotifyBrowser: NSViewRepresentable {

    public typealias NSViewType = WKWebView

    public func makeNSView(context: NSViewRepresentableContext<SpotifyBrowser>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        print("make")
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SpotifyBrowser>) {
        guard let url = self.url else {
            return
        }
        print("update")
        nsView.load(URLRequest(url: url))
    }
}
