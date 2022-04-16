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
                    .textFieldStyle(.roundedBorder)
                SecureField("password", text: $model.password)
                    .textFieldStyle(.roundedBorder)
                if model.twoFactor {
                    TextField("code", text: $model.code)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Button("Cancel") {
                        cancel()
                    }
                    Spacer(minLength: 10)
                    Button("Confirm") {
                        model.complete()
                    }
                    .disabled(!model.credentialsAreValid)
                }
                if model.accountCreatingEnabled {
                    createAccountView
                }
            }
            .padding()
            Spacer()
        }
        .modify {
            #if os(macOS)
            $0.background(
                KeyEventHandling { event in
                    if let characters = event.characters {
                        handleKey(characters)
                    }
                }
            )
            #else
            $0
            #endif
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
            if let error = model.error {
                return AlertsManager.makeAlert(error: error)
            } else {
                return Alert(title: Text("Unknown error"))
            }
        }
    }
    
    var createAccountView: some View {
        VStack {
            Text("or")
            Button("Create new account") {
                model.service.showingAuthorization = false
                model.service.showingSignUp = true
            }
        }
    }
    
    func handleKey(_ characters: String) {
        switch characters {
        case "\r":
            model.complete()
        case "\u{1B}":
            cancel()
        default:
            break
        }
    }
    
    func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
}
