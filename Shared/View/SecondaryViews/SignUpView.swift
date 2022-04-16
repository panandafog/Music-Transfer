//
//  SignUpView.swift
//  Music Transfer (iOS)
//
//  Created by Andrey on 14.04.2022.
//

import SwiftUI
import URLImage

struct SignUpView: View {
    
    @ObservedObject var model: SignUpViewModel
    @ObservedObject var alertsManager = AlertsManager.shared
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            VStack {
                TextField("login", text: $model.login)
                    .textFieldStyle(.roundedBorder)
                TextField("email", text: $model.email)
                    .textFieldStyle(.roundedBorder)
                SecureField("password", text: $model.password)
                    .textFieldStyle(.roundedBorder)
                SecureField("password confirmation", text: $model.passwordConfirmation)
                    .textFieldStyle(.roundedBorder)
                
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
