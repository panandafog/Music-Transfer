//
//  LoginView.swift
//  Music Transfer
//
//  Created by panandafog on 25.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import SwiftUI
import URLImage

struct LoginView: View {

    @State private var login = ""
    @State private var password = ""
    @State private var code = ""
    let twoFactor: Bool
    let captcha: VKCaptcha.Solved?
    let completion: ((_: String, _: String, _: String?, _: VKCaptcha.Solved?) -> Void)
    
    var body: some View {
        VStack {
            TextField("login", text: $login)
            SecureField("password", text: $password)
            if twoFactor {
                TextField("code", text: $code)
            }
            Button("Apply", action: {
                if !twoFactor {
                    completion(login, password, nil, captcha)
                } else {
                    completion(login, password, code, captcha)
                }
                LoginViewDelegate.shared.close()
            })
            Spacer()
        }
        .padding()
    }
}
