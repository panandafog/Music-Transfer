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
    
    @ObservedObject var model: LoginViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            VStack {
                TextField("login", text: $model.login)
                SecureField("password", text: $model.password)
                if model.twoFactor {
                    TextField("code", text: $model.code)
                }
                Button("Apply") {
                    if !model.twoFactor {
                        model.completion(model.login, model.password, nil, model.captcha)
                    } else {
                        model.completion(model.login, model.password, model.code, model.captcha)
                    }
                }
            }
            .padding()
            Spacer()
        }
        .onReceive(model.viewDismissalModePublisher) { shouldDismiss in
            if shouldDismiss {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
