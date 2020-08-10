//
//  SpotifyFacade.swift
//  Music Transfer
//
//  Created by panandafog on 25.07.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import Foundation
import SwiftUI

final class SpotifyFacade: APIFacade {

    private static let client_id =
    private static let client_secret =

    static let authorizationRedirectUrl = "https://example.com/callback/"

    private static let stateLength = 100
    static var state = randomString(length: stateLength)

    static var authorizationUrl: URL? {

        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "accounts.spotify.com"
        tmp.path = "/authorize"
        tmp.queryItems = [
            URLQueryItem(name: "client_id", value: self.client_id),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyFacade.authorizationRedirectUrl),
            URLQueryItem(name: "state", value: state)
        ]
        return tmp.url
    }

    static var requestTokensURL: URL? {

        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "accounts.spotify.com"
        tmp.path = "/api/token"
        tmp.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: SpotifyFacade.authorizationRedirectUrl),
            URLQueryItem(name: "state", value: state)
        ]
        return tmp.url
    }

    static var shared: SpotifyFacade = {
        let instance = SpotifyFacade()
        return instance
    }()

    let apiName = "Spotify"
    var isAuthorised = false {
        willSet {
            APIManager.shared.objectWillChange.send()
        }
    }

    var tokensAreRequested = false
    var tokensInfo: TokensInfo?

    struct TokensInfo: Decodable {
        let access_token: String
        let token_type: String
        let scope: String
        let expires_in: Int
        let refresh_token: String
    }

    func authorize() {
        let browserDelegate = BrowserViewDelegate.shared
        browserDelegate.openBrowser(browser: SpotifyBrowser(url: SpotifyFacade.authorizationUrl))
    }

    private init() {}

    private static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    func requestTokens(code: String) {

        var tmp = URLComponents()
        tmp.scheme = "https"
        tmp.host = "accounts.spotify.com"
        tmp.path = "/api/token"

        guard let url = tmp.url else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let postString = "grant_type=" + "authorization_code" + "&" +
            "client_id=" + SpotifyFacade.client_id + "&" +
            "code=" + code + "&" +
            "redirect_uri=" + SpotifyFacade.authorizationRedirectUrl + "&" +
            "&client_secret=" + SpotifyFacade.client_secret

        request.httpBody = postString.data(using: String.Encoding.utf8)

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

extension SpotifyFacade: NSCopying {

    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
