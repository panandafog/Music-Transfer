//
//  AuthorizationView.swift
//  Music Transfer
//
//  Created by panandafog on 31.12.2021.
//

import SwiftUI

struct AuthorizationView: View {
    
    @Binding var service: APIService
    
    var body: some View {
        if let vkService = service as? VKService {
            return AnyView(LoginView(model: vkService.loginViewModel))
        }
        if let lastFmService = service as? LastFmService {
            return AnyView(LoginView(model: lastFmService.loginViewModel))
        }
        if let spotifyService = service as? SpotifyService {
            return AnyView(spotifyService.authorizationView)
        }
        return AnyView(EmptyView())
    }
}
