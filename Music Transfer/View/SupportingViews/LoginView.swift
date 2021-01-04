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
    
    @State private(set) var login = ""
    @State private(set) var password = ""
    @State private var code = ""
    let twoFactor: Bool
    let captcha: VKCaptcha.Solved?
    let completion: ((_: String, _: String, _: String?, _: VKCaptcha.Solved?) -> Void)
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
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
            }
            .frame(width: 180, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .padding()
            Spacer()
        }
    }
}

struct TLoginView_Preview: PreviewProvider {
    static var previews: some View {
        LoginView(twoFactor: false, captcha: nil, completion: {_,_,_,_ in })
        LoginView(twoFactor: true, captcha: nil, completion: {_,_,_,_ in })
    }
}
