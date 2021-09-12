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
    
    #if os(macOS)
    @State private(set) var login = ""
    @State private(set) var password = ""
    @State private var code = ""
    let twoFactor: Bool
    let captcha: Captcha.Solved?
    let completion: ((_: String, _: String, _: String?, _: Captcha.Solved?) -> Void)
    
    #else
    @ObservedObject var model: LoginViewModel
    @Environment(\.presentationMode) private var presentationMode
    #endif
    
    var body: some View {
        #if os(macOS)
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
        #else
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            VStack {
                TextField("login", text: $model.login)
                SecureField("password", text: $model.password)
                if model.twoFactor {
                    TextField("code", text:$model.code)
                }
                Button("Apply", action: {
                    if !model.twoFactor {
                        model.completion(model.login, model.password, nil, model.captcha)
                    } else {
                        model.completion(model.login, model.password, model.code, model.captcha)
                    }
                })
            }
            .padding()
            Spacer()
        }
        .onReceive(model.viewDismissalModePublisher) { shouldDismiss in
            if shouldDismiss {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        #endif
    }
}
