//
//  LoginView.swift
//  Music Transfer
//
//  Created by panandafog on 25.10.2020.
//  Copyright © 2020 panandafog. All rights reserved.
//

import AlertToast
import SwiftUI
import URLImage

struct LoginView: View {
    
    @ObservedObject var model: LoginViewModel
    @ObservedObject var alertsManager = AlertsManager.shared
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            VStack {
                TextField("login", text: $model.login)
                SecureField("password", text: $model.password)
                if model.twoFactor {
                    TextField("code", text: $model.code)
                }
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer(minLength: 10)
                    Button("Apply") {
                        if !model.twoFactor {
                            model.completion(model.login, model.password, nil, model.captcha)
                        } else {
                            model.completion(model.login, model.password, model.code, model.captcha)
                        }
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
//        .toast(
//            isPresenting: Binding<Bool>(
//                get: {
//                    model.error != nil
//                },
//                set: { presenting in
//                    if !presenting {
//                        model.error = nil
//                    }
//                }
//            )
//        ) {
//            AlertToast(type: .regular, title: String(describing: model.error))
//        }
        .alert(
            isPresented: Binding<Bool>(
                get: {
                    model.error != nil
                },
                set: { presenting in
                    if !presenting {
                        model.error = nil
                    }
                }
            )
        ) {
            Alert(title: Text(String(describing: model.error)), dismissButton: .default(Text("Dismiss")))
        }
    }
}
