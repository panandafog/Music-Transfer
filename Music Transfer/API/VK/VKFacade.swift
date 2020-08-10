//
//  VKFacade.swift
//  Music Transfer
//
//  Created by panandafog on 08.08.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import SwiftUI

final class VKFacade: APIFacade {

    private static let client_id = 
    private static let client_secret =

    static let authorizationRedirectUrl = "https://example.com/callback/"

    private static let stateLength = 100
    static var state = randomString(length: stateLength)

    static var authorizationUrl: URL? {
        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "oauth.vk.com"
        tmp.path = "/authorize"
        tmp.queryItems = [
            URLQueryItem(name: "client_id", value: String(self.client_id)),
            URLQueryItem(name: "display", value: "page"),
            URLQueryItem(name: "redirect_uri", value: VKFacade.authorizationRedirectUrl),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "audio"),
            URLQueryItem(name: "state", value: state)
        ]
        return tmp.url
    }

    static var shared: VKFacade = {
        let instance = VKFacade()
        return instance
    }()

    var isAuthorised = false {
        willSet {
            APIManager.shared.objectWillChange.send()
        }
    }

    let apiName = "VK"

    var tokensAreRequested = false
    var tokensInfo: TokensInfo?

    struct TokensInfo: Decodable {
        let access_token: String
        let expires_in: Int
        let user_id: Int
    }

    struct ErrorInfo: Decodable {
        let error: String
        let error_description: String
    }

    func authorize() {
        let browserDelegate = BrowserViewDelegate.shared
        browserDelegate.openBrowser(browser: VKBrowser(url: VKFacade.authorizationUrl))
    }

    private init() {}

    private static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    private func requestTokensURL(code: String) -> URL? {

        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "oauth.vk.com"
        tmp.path = "/access_token"
        tmp.queryItems = [
            URLQueryItem(name: "client_id", value: String(VKFacade.client_id)),
            URLQueryItem(name: "client_secret", value: VKFacade.client_secret),
            URLQueryItem(name: "redirect_uri", value: VKFacade.authorizationRedirectUrl),
            URLQueryItem(name: "code", value: code)
        ]
        return tmp.url
    }

    func requestTokens(code: String) {

        guard let url = requestTokensURL(code: code) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        print(url.absoluteString)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let error = error {
                print("Error took place \(error)")
                return
            }

            guard let data = data, let dataString = String(data: data, encoding: .utf8) else {
                return
            }

            print("Response data string:\n \(dataString)")

            guard let tokensInfo = try? JSONDecoder().decode(TokensInfo.self, from: data) else {
                return
            }
            self.tokensInfo = tokensInfo

            //run timer for token expiring
            //create refresh tokens method (look https://www.appsdeveloperblog.com/http-post-request-example-in-swift/)

            print("Response data string:\n \(dataString)")
        }
        task.resume()
    }
}
